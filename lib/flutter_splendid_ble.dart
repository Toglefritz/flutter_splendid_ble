import 'central/central_platform_interface.dart';
import 'central/models/ble_connection_state.dart';
import 'central/models/ble_device.dart';
import 'central/models/ble_service.dart';
import 'central/models/bluetooth_permission_status.dart';
import 'central/models/bluetooth_status.dart';
import 'central/models/scan_filter.dart';
import 'central/models/scan_settings.dart';

/// [FlutterSplendidBle] provides an interface to interact with Bluetooth functionalities.
///
/// This class offers methods to check and monitor the status of the Bluetooth adapter, scan for devices,
/// connect/disconnect to/from devices, and manage Bluetooth permissions. It serves as a bridge to the underlying
/// platform-specific Bluetooth implementation, abstracting the complexity and providing a simple API for Flutter
/// applications.
///
/// The class primarily uses asynchronous patterns like [Future] and [Stream] to provide real-time updates and
/// responses to Bluetooth operations. The methods in this class delegate the actual operations to
/// `FlutterSplendidBlePlatform.instance`, ensuring platform-agnostic behavior.
class FlutterSplendidBle {
  /// Asks the platform to check the current status of the Bluetooth adapter.
  ///
  /// Returns a [Future] containing the current [BluetoothStatus].
  Future<BluetoothStatus> checkBluetoothAdapterStatus() async {
    return CentralPlatformInterface.instance.checkBluetoothAdapterStatus();
  }

  /// Emits the current status of the Bluetooth adapter whenever it changes.
  ///
  /// Returns a [Stream] of [BluetoothStatus].
  Stream<BluetoothStatus> emitCurrentBluetoothStatus() {
    return CentralPlatformInterface.instance.emitCurrentBluetoothStatus();
  }

  /// Asks the platform to stop scanning for Bluetooth devices.
  void stopScan() {
    return CentralPlatformInterface.instance.stopScan();
  }

  /// Asks the platform to start scanning for Bluetooth devices.
  ///
  /// Returns a [Stream] of [BleDevice] found during the scan.
  Stream<BleDevice> startScan(
      {List<ScanFilter>? filters, ScanSettings? settings}) {
    return CentralPlatformInterface.instance.startScan(
      filters: filters,
      settings: settings,
    );
  }

  /// Asks the platform to connect to a Bluetooth device by its address.
  ///
  /// Returns a [Stream] of [BleConnectionState].
  Stream<BleConnectionState> connect({required String deviceAddress}) {
    return CentralPlatformInterface.instance
        .connect(deviceAddress: deviceAddress);
  }

  /// Asks the platform to discover available services for a connected device by its address.
  ///
  /// Returns a [Stream] of [BleService].
  Stream<List<BleService>> discoverServices(String deviceAddress) {
    return CentralPlatformInterface.instance.discoverServices(deviceAddress);
  }

  /// Asks the platform to disconnect from a Bluetooth device by its address.
  Future<void> disconnect(String deviceAddress) {
    return CentralPlatformInterface.instance.disconnect(deviceAddress);
  }

  /// Asks the platform to get the current connection state for a Bluetooth device by its address.
  ///
  /// Returns a [Future] of [BleConnectionState].
  Future<BleConnectionState> getCurrentConnectionState(String deviceAddress) {
    return CentralPlatformInterface.instance
        .getCurrentConnectionState(deviceAddress);
  }

  /// Asks the platform to request Bluetooth permissions from the user.
  ///
  /// Returns a [Future] containing the current [BluetoothPermissionStatus].
  Future<BluetoothPermissionStatus> requestBluetoothPermissions() async {
    return CentralPlatformInterface.instance.requestBluetoothPermissions();
  }

  /// Emits the current Bluetooth permission status whenever it changes.
  ///
  /// Returns a [Stream] of [BluetoothPermissionStatus].
  Stream<BluetoothPermissionStatus> emitCurrentPermissionStatus() {
    return CentralPlatformInterface.instance.emitCurrentPermissionStatus();
  }
}
