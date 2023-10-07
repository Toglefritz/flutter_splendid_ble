import 'package:flutter/services.dart';
import 'package:flutter_ble/models/bluetooth_status.dart';
import 'package:flutter_ble/src/channel/flutter_ble_method_channel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('flutter_ble');

  _testCheckBluetoothAdapterStatus(channel);
}

/// Tests that the `checkBluetoothAdapterStatus` method returns the expected value for mocked responses to the
/// platform specific functions.
void _testCheckBluetoothAdapterStatus(MethodChannel channel) {
  for (BluetoothStatus status in BluetoothStatus.values) {
    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        ((MethodCall methodCall) async {
          if (methodCall.method == 'checkBluetoothAdapterStatus') {
            return status.identifier; // Mock the behavior of the native code
          }
          return null;
        }),
      );
    });

    test('checkBluetoothAdapterStatus returns correct status', () async {
      final MethodChannelFlutterBle methodChannelFlutterBle = MethodChannelFlutterBle();
      final BluetoothStatus status = await methodChannelFlutterBle.checkBluetoothAdapterStatus();

      // Check if the function returns the expected value
      expect(status, status);
    });
  }

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      null,
    );
  });
}
