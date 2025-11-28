import 'package:flutter/services.dart';
import 'package:flutter_splendid_ble/central/central_method_channel.dart';
import 'package:flutter_splendid_ble/shared/models/bluetooth_permission_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('flutter_splendid_ble_central');

  group('requestBluetoothPermissions', () {
    for (final BluetoothPermissionStatus status
        in BluetoothPermissionStatus.values) {
      test('returns $status', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          channel,
          (MethodCall methodCall) async {
            if (methodCall.method == 'requestBluetoothPermissions') {
              return status.identifier; // Mock the behavior of the native code
            }
            return null;
          },
        );

        final CentralMethodChannel methodChannelFlutterBle =
            CentralMethodChannel();
        final BluetoothPermissionStatus result =
            await methodChannelFlutterBle.requestBluetoothPermissions();

        // Check if the function returns the expected value
        expect(result, status);

        // Clean up
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          channel,
          null,
        );
      });
    }
  });
}
