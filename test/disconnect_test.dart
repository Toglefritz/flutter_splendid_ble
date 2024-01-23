import 'package:flutter/services.dart';
import 'package:flutter_splendid_ble/central/central_method_channel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('flutter_splendid_ble_central');
  final CentralMethodChannel methodChannelFlutterBle =
      CentralMethodChannel();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'disconnect') {
        return 'success';
      }
      return null;
    });
  });

  test('Test disconnect method', () async {
    const String deviceAddress = '00:00:00:00:00:01';

    // Listen for method calls on the channel and validate the parameters
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      expect(methodCall.method, 'disconnect');
      expect(methodCall.arguments, {'address': deviceAddress});

      return;
    });

    // Execute the function and check for completion
    await methodChannelFlutterBle.disconnect(deviceAddress);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
}
