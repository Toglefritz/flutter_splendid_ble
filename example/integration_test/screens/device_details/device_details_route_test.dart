import 'package:flutter_splendid_ble/central/central_platform_interface.dart';
import 'package:flutter_splendid_ble/central/fake_central_method_channel.dart';
import 'package:flutter_splendid_ble/central/models/ble_connection_state.dart';
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
  testWidgets('DeviceDetailsRoute reflects connection state changes', (WidgetTester tester) async {
    final device = BleDevice(
      name: 'Test Device',
      address: 'AA:BB:CC:DD:EE:FF',
      rssi: -50,
      advertisedServiceUuids: [],
      manufacturerData: null,
    );

    // Simulate the device as disconnected initially
    fakeCentral.setConnectionState(device.address, BleConnectionState.disconnected);

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
    fakeCentral.simulateConnectionStateUpdate(device.address, BleConnectionState.connected);

    await tester.pumpAndSettle();

    // The view should now reflect the connected state with a "DISCOVER SERVICES" button
    expect(find.widgetWithText(TableButton, 'CONNECT'), findsNothing);
    expect(find.widgetWithText(TableButton, 'DISCOVER SERVICES'), findsOneWidget);
  });
}
