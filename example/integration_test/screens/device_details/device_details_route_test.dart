import 'package:flutter_splendid_ble/central/central_platform_interface.dart';
import 'package:flutter_splendid_ble/central/fake_central_method_channel.dart';
import 'package:flutter_splendid_ble/central/models/ble_characteristic.dart';
import 'package:flutter_splendid_ble/central/models/ble_characteristic_permission.dart';
import 'package:flutter_splendid_ble/central/models/ble_characteristic_property.dart';
import 'package:flutter_splendid_ble/central/models/ble_connection_state.dart';
import 'package:flutter_splendid_ble/central/models/ble_service.dart';
import 'package:flutter_splendid_ble/central/splendid_ble_central.dart';
import 'package:flutter_splendid_ble/shared/models/ble_device.dart';
import 'package:flutter_splendid_ble_example/screens/central/device_details/device_details_route.dart';
import 'package:flutter_splendid_ble_example/screens/central/device_details/device_details_view.dart';
import 'package:flutter_splendid_ble_example/screens/components/table_button.dart';
import 'package:flutter_splendid_ble_example/splendid_ble_example_material_app.dart';
import 'package:flutter_test/flutter_test.dart';

/// Integration tests for the [DeviceDetailsRoute] widget, which manages interactions with a connected BLE device.
///
/// These tests verify the behavior of the [DeviceDetailsRoute] and its view ([DeviceDetailsView]) under different
/// connection states and device conditions:
///
/// - A device is connected and the UI reflects the connected state
/// - The connection state changes after the route is loaded, and the UI updates accordingly
///
/// The tests use a fake implementation of the [CentralPlatformInterface] to simulate Bluetooth state transitions
/// without requiring actual BLE hardware.
///
/// To run this test, use:
///
/// ```bash
/// cd example;
/// flutter test integration_test/screens/device_details/device_details_route_test.dart
/// ```
void main() {
  /// Set up a fake [SplendidBle] instance that uses the fake central for testing.
  late SplendidBle ble;

  /// Set up the fake central method channel before running the tests. This is used to simulate Bluetooth functionality
  /// without requiring actual hardware.
  late FakeCentralMethodChannel fakeCentral;

  /// Initializes faked Bluetooth plugin classes before each test.
  setUp(() {
    fakeCentral = FakeCentralMethodChannel();
    ble = SplendidBleCentral(platform: fakeCentral);
  });

  /// This test verifies that the [DeviceDetailsRoute] correctly reflects changes in the BLE connection state.
  testWidgets('DeviceDetailsRoute reflects connection state changes',
      (WidgetTester tester) async {
    final device = BleDevice(
      name: 'Test Device',
      address: 'AA:BB:CC:DD:EE:FF',
      rssi: -50,
      advertisedServiceUuids: [],
      manufacturerData: null,
    );

    // Simulate the device as disconnected initially
    fakeCentral.setConnectionState(
      device.address,
      BleConnectionState.disconnected,
    );

    await tester.pumpWidget(
      SplendidBleExampleMaterialApp(
        home: DeviceDetailsRoute(
          ble: ble,
          device: device,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // The view should initially reflect a disconnected state with a "CONNECT" button
    expect(find.widgetWithText(TableButton, 'CONNECT'), findsOneWidget);
    expect(find.widgetWithText(TableButton, 'DISCOVER SERVICES'), findsNothing);

    // Tap the "CONNECT" button to initiate a connection
    await tester.tap(find.widgetWithText(TableButton, 'CONNECT'));

    // Simulate a connection state change to connected
    fakeCentral.simulateConnectionStateUpdate(
      device.address,
      BleConnectionState.connected,
    );

    await tester.pumpAndSettle();

    // The view should now reflect the connected state with a "DISCOVER SERVICES" button
    expect(find.widgetWithText(TableButton, 'CONNECT'), findsNothing);
    expect(
      find.widgetWithText(TableButton, 'DISCOVER SERVICES'),
      findsOneWidget,
    );
  });

  /// This test verifies that the [DeviceDetailsRoute] correctly performs service discovery and updates the view to show
  /// service UUIDs.
  testWidgets('DeviceDetailsRoute handles service discovery correctly',
      (WidgetTester tester) async {
    // Create a fake BLE device with a specific service and characteristic
    final BleDevice device = BleDevice(
      name: 'Test Device',
      address: '11:22:33:44:55:66',
      rssi: -40,
      advertisedServiceUuids: [],
      manufacturerData: null,
    );

    // Define a service UUID and characteristic UUID for the test.
    const String serviceUuid = '180D';
    const String characteristicUuid = '2A37';

    // Set up fake connection and service data
    fakeCentral
      ..setConnectionState(device.address, BleConnectionState.connected)
      ..setServices(device.address, [
        BleService(
          serviceUuid: serviceUuid,
          characteristics: [
            BleCharacteristic(
              uuid: characteristicUuid,
              address: device.address,
              properties: [
                BleCharacteristicProperty.read,
              ],
              permissions: [
                BleCharacteristicPermission.read,
                BleCharacteristicPermission.write,
              ],
            ),
          ],
        ),
      ]);

    await tester.pumpWidget(
      SplendidBleExampleMaterialApp(
        home: DeviceDetailsRoute(
          ble: ble,
          device: device,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Should initially show the "DISCOVER SERVICES" button
    expect(
      find.widgetWithText(TableButton, 'DISCOVER SERVICES'),
      findsOneWidget,
    );

    // Tap the "DISCOVER SERVICES" button
    await tester.tap(find.widgetWithText(TableButton, 'DISCOVER SERVICES'));

    await tester.pumpAndSettle();

    // Verify that the service UUID text appears in the view
    expect(find.textContaining(serviceUuid), findsOneWidget);
  });
}
