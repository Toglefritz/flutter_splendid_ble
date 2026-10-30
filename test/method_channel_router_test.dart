import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_splendid_ble/central/central_method_channel.dart';
import 'package:flutter_splendid_ble/central/models/ble_characteristic.dart';
import 'package:flutter_splendid_ble/central/models/ble_characteristic_value.dart';
import 'package:flutter_splendid_ble/central/models/ble_connection_event.dart';
import 'package:flutter_splendid_ble/central/models/ble_connection_state.dart';
import 'package:flutter_splendid_ble/shared/models/ble_device.dart';
import 'package:flutter_splendid_ble/shared/models/bluetooth_status.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression tests for native callback routing through the shared method channel.
///
/// All central callbacks arrive on one method channel. Previously, each scan, connect, discover, observe, read, and
/// status call replaced a single shared handler, silently stopping every stream returned by earlier calls. These tests
/// exercise the real [CentralMethodChannel] (not the fake platform) and inject native callbacks to verify that:
/// * Event streams keep receiving updates after other BLE operations start.
/// * Concurrent characteristic reads each complete with their own response.
/// * Untargeted native `error` callbacks reach only the most recently started operation that reports errors.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// The channel used by native central callbacks on Android and iOS.
  const MethodChannel channel = MethodChannel('flutter_splendid_ble_central');

  /// API instance under test; the native router is shared across instances.
  late CentralMethodChannel platform;

  /// Creates a fresh API instance and answers every outgoing platform call with null.
  setUp(() {
    platform = CentralMethodChannel();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async => null);
  });

  /// Removes the mock platform handler so later test files start clean.
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  /// An adapter-off watcher installed before scanning must still observe the adapter turning off afterward.
  test('adapter status stream survives scan, connect, and read', () async {
    final List<BluetoothStatus> statuses = <BluetoothStatus>[];
    _listen(await platform.emitCurrentBluetoothStatus(), statuses);

    await platform.startScan();
    await platform.connect(deviceAddress: 'A');
    final Future<BleCharacteristicValue> read = platform.readCharacteristic(
      characteristic: _characteristic('A', 'U'),
      timeout: const Duration(seconds: 1),
    );
    await _emit(MethodCall('onCharacteristicRead', _payload('A', 'U')));
    await read;

    await _emit(const MethodCall('adapterStateUpdated', 'disabled'));
    expect(statuses, <BluetoothStatus>[BluetoothStatus.disabled]);
  });

  /// An unexpected-disconnect watcher for one device must survive connecting to another device and scanning.
  test('connection streams for a device survive connecting to another device',
      () async {
    final List<BleConnectionEvent> deviceA = <BleConnectionEvent>[];
    final List<BleConnectionEvent> deviceB = <BleConnectionEvent>[];
    _listen(await platform.connect(deviceAddress: 'A'), deviceA);
    _listen(await platform.observeConnectionState(deviceAddress: 'A'), deviceA);
    _listen(await platform.connect(deviceAddress: 'B'), deviceB);
    await platform.startScan();

    await _emit(
      const MethodCall('bleConnectionState_A', <String, Object?>{
        'state': 'disconnected',
        'platform': 'android',
      }),
    );

    // Both the connect stream and the observe stream for A receive the update; B's stream does not.
    expect(
      deviceA.map((BleConnectionEvent event) => event.state),
      <BleConnectionState>[
        BleConnectionState.disconnected,
        BleConnectionState.disconnected,
      ],
    );
    expect(deviceB, isEmpty);
  });

  /// A running scan must keep delivering results while other operations run concurrently.
  test('scan stream survives connect, discovery, observe, and bond calls',
      () async {
    final List<BleDevice> devices = <BleDevice>[];
    _listen(await platform.startScan(), devices);

    await platform.connect(deviceAddress: 'A');
    await platform.discoverServices('A');
    await platform.observeConnectionState(deviceAddress: 'A');
    await platform.observeBondState(deviceAddress: 'A');

    await _emit(
      const MethodCall('bleDeviceScanned', <String, Object?>{
        'name': 'device',
        'address': 'X',
        'rssi': -40,
        'manufacturerData': null,
      }),
    );
    expect(devices.single.address, 'X');
  });

  /// Every read observes every native read response, so each read must complete only with the response matching its
  /// own device address and characteristic UUID, ignoring case.
  test('concurrent reads complete with their own responses', () async {
    final Future<BleCharacteristicValue> first = platform.readCharacteristic(
      characteristic: _characteristic('A', 'U1'),
      timeout: const Duration(seconds: 1),
    );
    final Future<BleCharacteristicValue> second = platform.readCharacteristic(
      characteristic: _characteristic('A', 'U2'),
      timeout: const Duration(seconds: 1),
    );

    // Deliver responses out of order and in a different case.
    await _emit(MethodCall('onCharacteristicRead', _payload('a', 'u2', 2)));
    await _emit(MethodCall('onCharacteristicRead', _payload('A', 'U1', 1)));

    expect((await first).value, <int>[1]);
    expect((await second).value, <int>[2]);
  });

  /// Native `error` callbacks name no device or operation, so they go only to the newest operation that reports
  /// errors. Status streams do not take that role.
  test('untargeted errors reach only the newest error-reporting operation',
      () async {
    final List<Object> scanErrors = <Object>[];
    final List<Object> connectErrors = <Object>[];
    _listenErrors(await platform.startScan(), scanErrors);
    _listenErrors(await platform.connect(deviceAddress: 'A'), connectErrors);
    await platform.emitCurrentBluetoothStatus();

    await _emit(const MethodCall('error', 'native failure'));

    expect(scanErrors, isEmpty);
    expect(connectErrors, hasLength(1));
  });
}

/// Constructs a characteristic identity without native service discovery.
BleCharacteristic _characteristic(String address, String uuid) {
  return BleCharacteristic(
    address: address,
    uuid: uuid,
    properties: [],
    permissions: [],
  );
}

/// Builds the identity-bearing characteristic payload sent by both native platforms, carrying a single byte [value].
Map<String, Object?> _payload(String address, String uuid, [int value = 0]) {
  return <String, Object?>{
    'deviceAddress': address,
    'characteristicUuid': uuid,
    'value': <int>[value],
  };
}

/// Records events from [stream] into [values] and cancels the listener when the test finishes.
void _listen<T>(Stream<T> stream, List<T> values) {
  final StreamSubscription<T> subscription = stream.listen(values.add);
  addTearDown(subscription.cancel);
}

/// Records errors from [stream] into [errors] and cancels the listener when the test finishes.
void _listenErrors<T>(Stream<T> stream, List<Object> errors) {
  final StreamSubscription<T> subscription =
      stream.listen((T _) {}, onError: errors.add);
  addTearDown(subscription.cancel);
}

/// Injects a native callback and waits for broadcast delivery before the next assertion.
Future<void> _emit(MethodCall call) async {
  await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(
    'flutter_splendid_ble_central',
    const StandardMethodCodec().encodeMethodCall(call),
    (ByteData? reply) {},
  );
  await Future<void>.delayed(Duration.zero);
}
