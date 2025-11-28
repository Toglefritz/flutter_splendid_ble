import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_splendid_ble/central/central_method_channel.dart';
import 'package:flutter_splendid_ble/shared/models/bluetooth_permission_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('flutter_splendid_ble_central');

  _testEmitCurrentPermissionStatus(channel);
}

/// Tests that the `emitCurrentPermissionStatus` method correctly emits permission status updates from the platform side
/// to the Dart side.
void _testEmitCurrentPermissionStatus(MethodChannel channel) {
  for (final BluetoothPermissionStatus status
      in BluetoothPermissionStatus.values) {
    test('emitCurrentPermissionStatus emits $status', () async {
      final CentralMethodChannel methodChannelFlutterBle =
          CentralMethodChannel();
      final Completer<BluetoothPermissionStatus> completer =
          Completer<BluetoothPermissionStatus>();

      // Set up the mock handler
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        channel,
        (MethodCall methodCall) async {
          if (methodCall.method == 'emitCurrentPermissionStatus') {
            // Simulate the platform side emitting a permission status update
            Future.delayed(const Duration(milliseconds: 100), () async {
              await TestDefaultBinaryMessengerBinding
                  .instance.defaultBinaryMessenger
                  .handlePlatformMessage(
                channel.name,
                channel.codec.encodeMethodCall(
                  MethodCall('permissionStatusUpdated', status.identifier),
                ),
                (ByteData? data) {},
              );
            });
            return null;
          }
          return null;
        },
      );

      // Get the stream and listen for the first emission
      final Stream<BluetoothPermissionStatus> permissionStream =
          await methodChannelFlutterBle.emitCurrentPermissionStatus();

      permissionStream.listen((BluetoothPermissionStatus emittedStatus) {
        if (!completer.isCompleted) {
          completer.complete(emittedStatus);
        }
      });

      // Wait for the emission with a timeout
      final BluetoothPermissionStatus result =
          await completer.future.timeout(const Duration(seconds: 2));

      // Verify the emitted status matches the expected status
      expect(result, status);

      // Clean up
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });
  }
}
