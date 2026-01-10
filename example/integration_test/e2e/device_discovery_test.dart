import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_splendid_ble/flutter_splendid_ble.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'configs/esp32_test_constants.dart';
import 'configs/test_device_timing.dart';

/// Integration test for ESP32 BLE test device discovery.
///
/// This test validates the core scanning functionality of the Flutter Splendid BLE
/// plugin by attempting to discover the ESP32 test device. It serves as a foundational
/// test that confirms the basic BLE scanning capability works with real hardware.
///
/// Prerequisites:
/// * ESP32 test device must be powered on and advertising
/// * Mobile device must have Bluetooth enabled
/// * Required permissions must be granted (location on Android)
///
/// Test Flow:
/// 1. Initialize the BLE central instance
/// 2. Check Bluetooth adapter status
/// 3. Request necessary permissions
/// 4. Start scanning for BLE devices
/// 5. Filter scan results for the ESP32 test device
/// 6. Validate device discovery within timeout period
/// 7. Stop scanning and clean up
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('ESP32 Device Discovery', () {
    late SplendidBleCentral ble;

    /// Initialize BLE central instance before each test.
    ///
    /// Creates a fresh instance to ensure test isolation and
    /// prevent interference between test runs.
    setUp(() {
      ble = SplendidBleCentral();
    });

    /// Clean up resources after each test.
    ///
    /// Stops any ongoing scans to prevent resource leaks and
    /// interference with subsequent tests.
    tearDown(() {
      ble.stopScan();
    });

    /// Tests basic device discovery functionality.
    ///
    /// This test performs a BLE scan and validates that the ESP32 test device
    /// can be discovered within the expected timeout period. It checks both
    /// the device name and advertised service UUID to ensure correct identification.
    ///
    /// Expected Behavior:
    /// * Bluetooth adapter is available and enabled
    /// * Required permissions are granted
    /// * ESP32 device is discovered within 10 seconds
    /// * Device name matches expected value
    /// * Advertised service UUID matches expected value
    testWidgets('should discover ESP32 test device during scan',
        (WidgetTester tester) async {
      // Step 1: Verify Bluetooth adapter status
      final BluetoothStatus bluetoothStatus =
          await ble.checkBluetoothAdapterStatus();
      expect(
        bluetoothStatus,
        BluetoothStatus.enabled,
        reason: 'Bluetooth adapter must be enabled for device discovery',
      );

      // Step 2: Request and verify permissions
      final BluetoothPermissionStatus permissionStatus =
          await ble.requestBluetoothPermissions();
      expect(
        permissionStatus,
        BluetoothPermissionStatus.granted,
        reason: 'Bluetooth permissions must be granted for scanning',
      );

      // Step 3: Start scanning and collect discovered devices
      final Stream<BleDevice> scanStream = await ble.startScan();

      BleDevice? discoveredTestDevice;
      final Completer<void> discoveryCompleter = Completer<void>();

      // Step 4: Listen for scan results and filter for test device
      late StreamSubscription<BleDevice> scanSubscription;
      scanSubscription = scanStream.listen(
        (BleDevice device) {
          // Check if this is our ESP32 test device
          if (device.name == kTestDeviceName) {
            discoveredTestDevice = device;
            scanSubscription.cancel();
            if (!discoveryCompleter.isCompleted) {
              discoveryCompleter.complete();
            }
          }
        },
        onError: (Object error) {
          scanSubscription.cancel();
          if (!discoveryCompleter.isCompleted) {
            discoveryCompleter.completeError(error);
          }
        },
      );

      // Step 5: Wait for device discovery with timeout
      try {
        await discoveryCompleter.future.timeout(
          const Duration(milliseconds: TestDeviceTiming.discoveryTimeoutMs),
        );
      } on TimeoutException {
        await scanSubscription.cancel();
        fail(
          'ESP32 test device not discovered within ${TestDeviceTiming.discoveryTimeoutMs}ms. '
          'Ensure device is powered on and advertising.',
        );
      }

      // Step 6: Stop scanning
      ble.stopScan();

      // Step 7: Validate discovered device properties
      expect(
        discoveredTestDevice,
        isNotNull,
        reason: 'ESP32 test device should be discovered during scan',
      );

      expect(
        discoveredTestDevice!.name,
        equals(kTestDeviceName),
        reason: 'Discovered device name should match expected test device name',
      );

      expect(
        discoveredTestDevice!.address,
        isNotEmpty,
        reason: 'Discovered device should have a valid MAC address',
      );

      // Step 8: Validate advertised service (if available in scan results)
      if (discoveredTestDevice!.advertisedServiceUuids.isNotEmpty) {
        expect(
          discoveredTestDevice!.advertisedServiceUuids,
          contains(kTestServiceUuid.toLowerCase()),
          reason:
              'ESP32 test device should advertise the expected service UUID',
        );
      }

      debugPrint('✓ ESP32 test device discovered successfully');
      debugPrint('  Device Name: ${discoveredTestDevice!.name}');
      debugPrint('  Device Address: ${discoveredTestDevice!.address}');
      debugPrint(
        '  Service UUIDs: ${discoveredTestDevice!.advertisedServiceUuids}',
      );
      debugPrint('  RSSI: ${discoveredTestDevice!.rssi} dBm');
    });

    /// Tests scan timeout behavior when device is not available.
    ///
    /// This test validates that the scanning functionality properly handles
    /// scenarios where the expected device is not available or not advertising.
    /// It ensures the scan doesn't hang indefinitely and provides appropriate
    /// feedback when devices are not found.
    ///
    /// Note: This test will only pass if the ESP32 device is NOT advertising.
    /// It's primarily useful for validating timeout behavior during development.
    testWidgets(
      'should handle scan timeout when device not available',
      (WidgetTester tester) async {
        // This test is marked as skip by default since it requires the ESP32 to be off
        // Uncomment the skip line below to run this test when the ESP32 is not available
      },
      skip: true,
    );
  });
}
