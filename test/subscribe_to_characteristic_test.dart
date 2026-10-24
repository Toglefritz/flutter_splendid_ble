import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_splendid_ble/central/central_method_channel.dart';
import 'package:flutter_splendid_ble/central/models/ble_characteristic.dart';
import 'package:flutter_splendid_ble/central/models/ble_characteristic_value.dart';
import 'package:flutter_splendid_ble/central/models/ble_connection_event.dart';
import 'package:flutter_splendid_ble/central/models/ble_connection_state.dart';
import 'package:flutter_splendid_ble/central/models/exceptions/bluetooth_permission_exception.dart';
import 'package:flutter_splendid_ble/central/models/exceptions/bluetooth_subscription_exception.dart';
import 'package:flutter_test/flutter_test.dart';

/// Exercises real method-channel routing with interleaved native notifications, not the fake BLE platform.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// The channel used by native central callbacks on Android and iOS.
  const MethodChannel channel = MethodChannel('flutter_splendid_ble_central');

  /// API instance under test; the native router is shared across instances.
  late CentralMethodChannel platform;

  setUp(() {
    platform = CentralMethodChannel();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async => null);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
      'isolates identical interleaved messages across five characteristics and another device',
      () async {
    final List<List<BleCharacteristicValue>> received =
        <List<BleCharacteristicValue>>[];
    final List<BleCharacteristic> characteristics = <BleCharacteristic>[
      for (int index = 0; index < 5; index++)
        _characteristic('AA:BB:CC:DD:EE:01', 'ABCD$index'),
      _characteristic('AA:BB:CC:DD:EE:02', 'ABCD0'),
    ];
    for (final BleCharacteristic characteristic in characteristics) {
      final List<BleCharacteristicValue> values = <BleCharacteristicValue>[];
      received.add(values);
      final Stream<BleCharacteristicValue> stream =
          await platform.subscribeToCharacteristic(characteristic);
      expect(stream.isBroadcast, isTrue);
      _listen(stream, values);
    }

    for (final List<int> chunk in <List<int>>[
      <int>[123, 34, 120, 34, 58],
      <int>[49, 125, 10],
    ]) {
      for (final BleCharacteristic characteristic in characteristics) {
        await _notify(characteristic, chunk);
      }
    }
    await _notify(_characteristic('UNKNOWN', 'ABCD0'), <int>[99]);
    await _notify(
        _characteristic(characteristics.first.address, 'UNKNOWN'), <int>[99]);

    for (final List<BleCharacteristicValue> values in received) {
      expect(
          values.map((BleCharacteristicValue value) => value.value),
          <List<int>>[
            <int>[123, 34, 120, 34, 58],
            <int>[49, 125, 10],
          ]);
    }
  });

  test('matches Android and iOS identifiers case-insensitively', () async {
    for (final String address in <String>[
      'AA:BB:CC:DD:EE:FF',
      'ABCD1234-ABCD-1234-ABCD-123456789ABC'
    ]) {
      final BleCharacteristic characteristic =
          _characteristic(address, '08590F7E-DB05-467E-8757-72F6FAEB13D6');
      final List<BleCharacteristicValue> values = <BleCharacteristicValue>[];
      _listen(await platform.subscribeToCharacteristic(characteristic), values);
      await _notify(
          _characteristic(
              address.toLowerCase(), characteristic.uuid.toLowerCase()),
          <int>[42]);
      expect(values.single.value, <int>[42]);
    }
  });

  test(
      'cancellation and resubscription do not duplicate deliveries or replace another instance receiver',
      () async {
    final BleCharacteristic first = _characteristic('DEVICE', 'ABCD');
    final BleCharacteristic second = _characteristic('DEVICE', 'DCBA');
    final List<BleCharacteristicValue> oldValues = <BleCharacteristicValue>[];
    final List<BleCharacteristicValue> newValues = <BleCharacteristicValue>[];
    final List<BleCharacteristicValue> peerValues = <BleCharacteristicValue>[];
    final StreamSubscription<BleCharacteristicValue> old = _listen(
      await platform.subscribeToCharacteristic(first),
      oldValues,
    );
    _listen(await platform.subscribeToCharacteristic(second), peerValues);
    await old.cancel();
    await platform.unsubscribeFromCharacteristic(first);
    _listen(await CentralMethodChannel().subscribeToCharacteristic(first),
        newValues);
    await _notify(first, <int>[1]);
    await _notify(second, <int>[2]);
    expect(oldValues, isEmpty);
    expect(newValues.single.value, <int>[1]);
    expect(peerValues.single.value, <int>[2]);
  });

  test('other BLE operation handlers cannot replace the notification receiver',
      () async {
    final BleCharacteristic characteristic = _characteristic('DEVICE', 'ABCD');
    final List<BleCharacteristicValue> values = <BleCharacteristicValue>[];
    _listen(await platform.subscribeToCharacteristic(characteristic), values);

    await platform.startScan();
    await _notify(characteristic, <int>[1]);
    await platform.stopScan();
    await platform.discoverServices(characteristic.address);
    await _notify(characteristic, <int>[2]);
    await platform.connect(deviceAddress: characteristic.address);
    await _notify(characteristic, <int>[3]);
    await platform.observeConnectionState(
        deviceAddress: characteristic.address);
    await _notify(characteristic, <int>[4]);
    await platform.emitCurrentBluetoothStatus();
    await _notify(characteristic, <int>[5]);
    await platform.emitCurrentPermissionStatus();
    await _notify(characteristic, <int>[6]);

    final Future<BleCharacteristicValue> read = platform.readCharacteristic(
      characteristic: characteristic,
      timeout: const Duration(seconds: 1),
    );
    await _notify(characteristic, <int>[7], method: 'onCharacteristicRead');
    expect((await read).value, <int>[7]);
    await _notify(characteristic, <int>[8]);

    await expectLater(
      platform.readCharacteristic(
          characteristic: characteristic, timeout: Duration.zero),
      throwsA(isA<TimeoutException>()),
    );
    await _notify(characteristic, <int>[9]);
    expect(
      values.map((BleCharacteristicValue value) => value.value.single),
      <int>[1, 2, 3, 4, 5, 6, 8, 9],
    );
  });

  test('subscription setup preserves the existing connection observer',
      () async {
    final List<BleConnectionEvent> events = <BleConnectionEvent>[];
    final List<BleCharacteristicValue> values = <BleCharacteristicValue>[];
    final BleCharacteristic characteristic = _characteristic('DEVICE', 'ABCD');
    _listen(
        await platform.observeConnectionState(
            deviceAddress: characteristic.address),
        events);
    _listen(await platform.subscribeToCharacteristic(characteristic), values);
    await _emit(
      const MethodCall('bleConnectionState_DEVICE', <String, Object?>{
        'state': 'disconnected',
        'platform': 'ios',
      }),
    );
    await _notify(characteristic, <int>[1]);
    expect(events.length, 1);
    expect(events.single.state, BleConnectionState.disconnected);
    expect(events.single.isFailure, false);
    expect(values.single.value, <int>[1]);
  });

  test(
      'malformed bytes produce an error only on their matching stream without stopping later events',
      () async {
    final BleCharacteristic first = _characteristic('DEVICE', 'ABCD');
    final BleCharacteristic second = _characteristic('DEVICE', 'DCBA');
    final List<BleCharacteristicValue> firstValues = <BleCharacteristicValue>[];
    final List<BleCharacteristicValue> secondValues =
        <BleCharacteristicValue>[];
    final List<Object> errors = <Object>[];
    final StreamSubscription<BleCharacteristicValue> subscription =
        (await platform.subscribeToCharacteristic(first))
            .listen(firstValues.add, onError: errors.add);
    addTearDown(subscription.cancel);
    _listen(await platform.subscribeToCharacteristic(second), secondValues);
    await _emit(
      MethodCall('onCharacteristicChanged', <String, Object?>{
        'deviceAddress': first.address,
        'characteristicUuid': first.uuid,
        'value': 'not bytes',
      }),
    );
    await _notify(first, <int>[1]);
    await _notify(second, <int>[2]);
    expect(errors.single, isA<FormatException>());
    expect(firstValues.single.value, <int>[1]);
    expect(secondValues.single.value, <int>[2]);
  });

  test('failed native subscriptions do not disrupt existing streams', () async {
    final BleCharacteristic characteristic = _characteristic('DEVICE', 'ABCD');
    final List<BleCharacteristicValue> values = <BleCharacteristicValue>[];
    _listen(await platform.subscribeToCharacteristic(characteristic), values);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      throw PlatformException(
          code: 'failed', message: 'native operation failed');
    });
    await expectLater(
      platform.subscribeToCharacteristic(_characteristic('DEVICE', 'DCBA')),
      throwsA(isA<BluetoothSubscriptionException>()),
    );
    await _notify(characteristic, <int>[1]);
    expect(values.single.value, <int>[1]);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      throw PlatformException(
          code: 'permissions', message: 'Missing permissions');
    });
    await expectLater(
      platform.subscribeToCharacteristic(characteristic),
      throwsA(isA<BluetoothPermissionException>()),
    );
  });
}

/// Constructs a characteristic identity without native service discovery.
BleCharacteristic _characteristic(String address, String uuid) {
  return BleCharacteristic(
      address: address, uuid: uuid, properties: [], permissions: []);
}

/// Records events and releases the listener when the test finishes.
StreamSubscription<T> _listen<T>(Stream<T> stream, List<T> values) {
  final StreamSubscription<T> subscription = stream.listen(values.add);
  addTearDown(subscription.cancel);
  return subscription;
}

/// Sends the identity-bearing payload used by both native platforms.
Future<void> _notify(
  BleCharacteristic characteristic,
  List<int> bytes, {
  String method = 'onCharacteristicChanged',
}) {
  return _emit(
    MethodCall(method, <String, Object?>{
      'deviceAddress': characteristic.address,
      'characteristicUuid': characteristic.uuid,
      'value': bytes,
    }),
  );
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
