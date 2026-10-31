import 'package:flutter/services.dart';
import 'package:flutter_splendid_ble/central/central_method_channel.dart';
import 'package:flutter_splendid_ble/central/models/exceptions/bluetooth_permission_exception.dart';
import 'package:flutter_splendid_ble/central/models/exceptions/bluetooth_scan_exception.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for how [CentralMethodChannel.startScan] reports native failures to start a scan.
///
/// Android cannot start a scan while Bluetooth is off because no LE scanner is available. The native layer reports
/// this as a `BLUETOOTH_UNAVAILABLE` platform error, which callers should receive as a typed plugin exception rather
/// than a raw [PlatformException].
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// The channel used by native central callbacks on Android and iOS.
  const MethodChannel channel = MethodChannel('flutter_splendid_ble_central');

  /// API instance under test.
  late CentralMethodChannel platform;

  setUp(() {
    platform = CentralMethodChannel();
  });

  /// Removes the mock platform handler so later test files start clean.
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  /// Makes the native `startScan` call fail with the given error [code] and [message].
  void failStartScan(String code, String message) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      if (call.method == 'startScan') {
        throw PlatformException(code: code, message: message);
      }

      return null;
    });
  }

  /// Bluetooth being off on Android surfaces as a scan exception the caller can handle.
  test('throws BluetoothScanException when the scanner is unavailable',
      () async {
    failStartScan(
      'BLUETOOTH_UNAVAILABLE',
      'Cannot start scan: the Bluetooth LE scanner is unavailable. '
          'Bluetooth may be turned off.',
    );

    await expectLater(
      platform.startScan(),
      throwsA(isA<BluetoothScanException>()),
    );
  });

  /// Permission failures keep their dedicated exception type.
  test('throws BluetoothPermissionException for missing permissions', () async {
    failStartScan('permissions', 'Missing permissions');

    await expectLater(
      platform.startScan(),
      throwsA(isA<BluetoothPermissionException>()),
    );
  });
}
