import 'package:flutter_splendid_ble/central/fake_central_method_channel.dart';
import 'package:flutter_splendid_ble/central/splendid_ble_central.dart';
import 'package:flutter_splendid_ble/shared/models/ble_device.dart';
import 'package:flutter_splendid_ble_example/screens/central/scan/components/scan_result_tile.dart';
import 'package:flutter_splendid_ble_example/screens/central/scan/scan_route.dart';
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

    await tester.pumpAndSettle();

    // Since no devices are discovered, we expect no ScanResultTile widgets to be found.
    expect(find.byType(ScanResultTile), findsNothing);
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
}
