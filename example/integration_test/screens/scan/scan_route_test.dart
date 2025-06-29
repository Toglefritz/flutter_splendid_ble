import 'package:flutter/cupertino.dart';
import 'package:flutter_splendid_ble/central/fake_central_method_channel.dart';
import 'package:flutter_splendid_ble/central/models/scan_filter.dart';
import 'package:flutter_splendid_ble/central/splendid_ble_central.dart';
import 'package:flutter_splendid_ble/shared/models/ble_device.dart';
import 'package:flutter_splendid_ble_example/screens/central/scan/components/scan_result_tile.dart';
import 'package:flutter_splendid_ble_example/screens/central/scan/scan_route.dart';
import 'package:flutter_splendid_ble_example/screens/components/loading_indicator.dart';
import 'package:flutter_splendid_ble_example/splendid_ble_example_material_app.dart';
import 'package:flutter_test/flutter_test.dart';

/// Integration tests for the ScanRoute widget, which manages Bluetooth scanning functionality.
///
/// These tests verify the behavior of the ScanRoute and its view (ScanView) under different conditions:
///
/// - No devices found during scan
/// - A single device is found
/// - A device is discovered multiple times (should only appear once)
///
/// The tests use a fake implementation of the CentralPlatformInterface to mock Bluetooth scan results without
/// requiring actual BLE hardware.
///
/// To run this test, use:
///
/// ```bash
/// cd example;
/// flutter test integration_test/screens/scan/scan_route_test.dart
/// ```
void main() {
  /// Set up a fake
  late SplendidBle ble;

  /// Set up the fake central method channel before running the tests. This is used to simulate Bluetooth functionality
  /// without requiring actual hardware.
  late FakeCentralMethodChannel fakeCentral;

  /// Initializes faked Bluetooth plugin classes before each test.
  setUp(() {
    fakeCentral = FakeCentralMethodChannel();
    ble = SplendidBleCentral(
      platform: fakeCentral,
    );
  });

  /// This test verifies that the [ScanRoute] displays no devices when the scan returns nothing.
  testWidgets('ScanRoute displays no devices when scan returns nothing', (WidgetTester tester) async {
    // Initialize the fake central with no devices.
    await tester.pumpWidget(
      SplendidBleExampleMaterialApp(
        home: ScanRoute(
          ble: ble,
        ),
      ),
    );

    // Wait for the fake central to complete the scan process.
    await Future<void>.delayed(const Duration(milliseconds: 100));

    // Since no devices are discovered, we expect no ScanResultTile widgets to be found.
    expect(find.byType(ScanResultTile), findsNothing);
    expect(find.byType(LoadingIndicator), findsOneWidget);
  });

  /// This test verifies that the [ScanRoute] displays one device when a single device is discovered. It also validates
  /// that the device's information is correctly displayed in the UI.
  testWidgets('ScanRoute displays one device when one is discovered', (WidgetTester tester) async {
    fakeCentral.addFakeDevice(
      BleDevice(
        name: 'Test Device',
        address: '00:11:22:33:44:55',
        rssi: -50,
        manufacturerData: null,
        advertisedServiceUuids: ['abcd1234-1234-1234-1234-1234567890aa'],
      ),
    );

    await tester.pumpWidget(
      SplendidBleExampleMaterialApp(
        home: ScanRoute(
          ble: ble,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify that the ScanResultTile for the Test Device is found in the widget tree.
    expect(find.byType(ScanResultTile), findsOneWidget);
    expect(find.text('Test Device'), findsOneWidget);
  });

  /// This test verifies that the [ScanRoute] avoids listing duplicate devices. It simulates a scenario where the same
  /// device is detected multiple times during the scan, and ensures that it only appears once in the UI.
  testWidgets('ScanRoute avoids listing duplicate devices', (WidgetTester tester) async {
    final device = BleDevice(
      name: 'Repeated Device',
      address: '01:02:03:04:05:06',
      rssi: -45,
      manufacturerData: null,
      advertisedServiceUuids: ['abcd1234-1234-1234-1234-1234567890aa'],
    );
    fakeCentral
      ..addFakeDevice(device)
      ..addFakeDevice(device); // Simulate multiple detections

    await tester.pumpWidget(
      SplendidBleExampleMaterialApp(
        home: ScanRoute(ble: ble),
      ),
    );

    await tester.pumpAndSettle();

    // Verify that the ScanResultTile for the Repeated Device is found only once in the widget tree.
    expect(find.byType(ScanResultTile), findsOneWidget);
    expect(find.text('Repeated Device'), findsOneWidget);
  });

  /// This test verifies that the [ScaRoute] displays the correct number of devices when multiple unique devices are
  /// discovered. In this test, a large number of unique devices are added to the fake central, and the test checks that
  /// each is displayed and that the view does not encounter any overflows or other layout issues.
  testWidgets('ScanRoute displays multiple unique devices correctly', (WidgetTester tester) async {
    // The number of unique devices to add for this test.
    const int numberOfDevices = 10;

    // Add a large number of unique devices to the fake central.
    for (int i = 0; i < numberOfDevices; i++) {
      fakeCentral.addFakeDevice(
        BleDevice(
          name: 'Device $i',
          address: '00:11:22:33:44:$i',
          rssi: -50 - i,
          manufacturerData: null,
          advertisedServiceUuids: ['abcd1234-1234-1234-1234-1234567890aa'],
        ),
      );
    }

    await tester.pumpWidget(
      SplendidBleExampleMaterialApp(
        home: ScanRoute(ble: ble),
      ),
    );

    await tester.pumpAndSettle();

    // Scroll to ensure all device tiles are brought into view
    final Finder scrollableFinder = find.byType(CustomScrollView);
    for (int i = 0; i < numberOfDevices; i++) {
      // Find the ScanResultTile for each device by its text.
      final Finder deviceFinder = find.widgetWithText(ScanResultTile, 'Device $i');

      // Scroll until the device tile is visible.
      await tester.dragUntilVisible(deviceFinder, scrollableFinder, const Offset(0, 1));

      // Verify that the device tile is found in the widget tree.
      expect(find.widgetWithText(ScanResultTile, 'Device $i'), findsOneWidget);
    }
  });

  /// This test verifies that, when a filter for a specific device name is applied, the [ScanRoute] only displays
  /// devices that match the filter criteria.
  testWidgets('ScanRoute applies device name filter correctly', (WidgetTester tester) async {
    // Add multiple devices,with different names
    fakeCentral
      ..addFakeDevice(
        BleDevice(
          name: 'Target Device',
          address: '00:11:22:33:44:55',
          rssi: -50,
          manufacturerData: null,
          advertisedServiceUuids: ['abcd1234-1234-1234-1234-1234567890aa'],
        ),
      )
      ..addFakeDevice(
        BleDevice(
          name: 'Other Device',
          address: '00:11:22:33:44:66',
          rssi: -60,
          manufacturerData: null,
          advertisedServiceUuids: ['abcd1234-1234-1234-1234-1234567890bb'],
        ),
      );

    await tester.pumpWidget(
      SplendidBleExampleMaterialApp(
        home: ScanRoute(
          ble: ble,
          filters: [
            ScanFilter(
              deviceName: 'Target Device',
            ),
          ],
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Only the matching device should be displayed.
    expect(find.byType(ScanResultTile), findsOneWidget);
    expect(find.text('Target Device'), findsOneWidget);
    expect(find.text('Other Device'), findsNothing);
  });
}
