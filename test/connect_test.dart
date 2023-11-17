import 'package:flutter/services.dart';
import 'package:flutter_splendid_ble/flutter_splendid_ble_method_channel.dart';
import 'package:flutter_splendid_ble/models/ble_connection_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('flutter_splendid_ble');

  // Initialize the class containing the `connect` method
  final MethodChannelFlutterSplendidBle methodChannelFlutterBle =
      MethodChannelFlutterSplendidBle();

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

  test('Test connect method', () async {
    final Stream<BleConnectionState> connectionStream =
        methodChannelFlutterBle.connect(deviceAddress: '00:00:00:00:00:01');

    final List<BleConnectionState> emittedStates = [];

    // Listen to the emitted states and store them
    connectionStream.listen((state) => emittedStates.add(state));

    // Simulate a connection state change emitted from the platform side
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
      channel.name,
      channel.codec.encodeMethodCall(const MethodCall(
          'bleConnectionState_00:00:00:00:00:01', 'connected')),
      (ByteData? data) {},
    );

    // Check that the correct state was emitted
    expect(emittedStates, [BleConnectionState.connected]);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      channel,
      null,
    );
  });
}
