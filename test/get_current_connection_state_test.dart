import 'package:flutter/services.dart';
import 'package:flutter_splendid_ble/central/central_method_channel.dart';
import 'package:flutter_splendid_ble/central/models/ble_connection_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('flutter_splendid_ble_central');
  final CentralMethodChannel methodChannelFlutterBle = CentralMethodChannel();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'getCurrentConnectionState') {
        return 'connected';
      }
      return null;
    });
  });

  test('Test getCurrentConnectionState method', () async {
    const String deviceAddress = '00:00:00:00:00:01';

    // Listen for method calls on the channel and validate the parameters
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      expect(methodCall.method, 'getCurrentConnectionState');
      expect(methodCall.arguments, {'address': deviceAddress});
      return 'connected';
    });

    // Execute the function
    final BleConnectionState state =
        await methodChannelFlutterBle.getCurrentConnectionState(deviceAddress);

    // Validate that the function correctly converted the method channel result
    // to a Dart enum
    expect(state, BleConnectionState.connected);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
}
