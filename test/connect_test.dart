import 'package:flutter/services.dart';
import 'package:flutter_splendid_ble/central/central_method_channel.dart';
import 'package:flutter_splendid_ble/central/models/ble_connection_event.dart';
import 'package:flutter_splendid_ble/central/models/ble_connection_failure_category.dart';
import 'package:flutter_splendid_ble/central/models/ble_connection_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('flutter_splendid_ble_central');

  // Initialize the class containing the `connect` method
  final CentralMethodChannel methodChannelFlutterBle = CentralMethodChannel();

  setUp(() {
    // Set up a default method channel mock
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'connect') {
        return 'success';
      }
      return null;
    });
  });

  /// Dispatches a simulated `bleConnectionState_<address>` method call from the platform side with the given
  /// [arguments] map, mirroring the payload the native layer now sends.
  Future<void> emitConnectionState(Map<String, Object?> arguments) async {
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
      channel.name,
      channel.codec.encodeMethodCall(
        MethodCall('bleConnectionState_00:00:00:00:00:01', arguments),
      ),
      (ByteData? data) {},
    );
  }

  test('emits a connected event from a connected-state payload', () async {
    final Stream<BleConnectionEvent> connectionStream =
        await methodChannelFlutterBle.connect(
      deviceAddress: '00:00:00:00:00:01',
    );

    final List<BleConnectionEvent> emittedEvents = <BleConnectionEvent>[];
    connectionStream.listen(emittedEvents.add);

    await emitConnectionState(<String, Object?>{
      'state': 'connected',
      'platform': 'ios',
    });

    expect(emittedEvents.length, 1);
    expect(emittedEvents.single.state, BleConnectionState.connected);
    expect(emittedEvents.single.isFailure, false);
    expect(emittedEvents.single.failure, isNull);
  });

  test('emits a failed event carrying normalized failure detail', () async {
    final Stream<BleConnectionEvent> connectionStream =
        await methodChannelFlutterBle.connect(
      deviceAddress: '00:00:00:00:00:01',
    );

    final List<BleConnectionEvent> emittedEvents = <BleConnectionEvent>[];
    connectionStream.listen(emittedEvents.add);

    await emitConnectionState(<String, Object?>{
      'state': 'failed',
      'platform': 'android',
      'category': 'peerTerminated',
      'errorCode': 19,
      'errorDomain': 'android_gatt',
      'errorDescription': 'Connection terminated by peer (status 19)',
    });

    expect(emittedEvents.length, 1);

    final BleConnectionEvent event = emittedEvents.single;
    expect(event.state, BleConnectionState.failed);
    expect(event.isFailure, true);
    expect(event.failure, isNotNull);
    expect(
      event.failure!.category,
      BleConnectionFailureCategory.peerTerminated,
    );
    expect(event.failure!.platform, 'android');
    expect(event.failure!.rawCode, 19);
    expect(event.failure!.domain, 'android_gatt');
    expect(
      event.failure!.description,
      'Connection terminated by peer (status 19)',
    );
  });

  test('maps an unrecognized state identifier to unknown without throwing',
      () async {
    final Stream<BleConnectionEvent> connectionStream =
        await methodChannelFlutterBle.connect(
      deviceAddress: '00:00:00:00:00:01',
    );

    final List<BleConnectionEvent> emittedEvents = <BleConnectionEvent>[];
    connectionStream.listen(emittedEvents.add);

    await emitConnectionState(<String, Object?>{
      'state': 'some_future_state',
      'platform': 'ios',
    });

    expect(emittedEvents.length, 1);
    expect(emittedEvents.single.state, BleConnectionState.unknown);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      channel,
      null,
    );
  });
}
