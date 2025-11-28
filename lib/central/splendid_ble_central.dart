import '../shared/models/ble_device.dart';
import '../shared/models/bluetooth_permission_status.dart';
import '../shared/models/bluetooth_status.dart';
import 'central_platform_interface.dart';
import 'models/ble_connection_state.dart';
import 'models/ble_service.dart';
import 'models/connected_ble_device.dart';
import 'models/scan_filter.dart';
import 'models/scan_settings.dart';

/// [SplendidBleCentral] provides an interface to interact with Bluetooth functionalities from a Flutter app acting as a
/// BLE central device.
///
/// This class offers methods to check and monitor the status of the Bluetooth adapter, scan for devices,
/// connect/disconnect to/from devices, and manage Bluetooth permissions. It serves as a bridge to the underlying
/// platform-specific Bluetooth implementation, abstracting the complexity and providing a simple API for Flutter
/// applications.
///
/// The class primarily uses asynchronous patterns like [Future] and [Stream] to provide real-time updates and responses
/// to Bluetooth operations. The methods in this class delegate the actual operations to
/// `FlutterSplendidBlePlatform.instance`, ensuring platform-agnostic behavior.

/// This type is an alias for [SplendidBleCentral] and is used to maintain compatibility with the previous version of
/// the plugin. It is recommended to use [SplendidBleCentral] instead because, when peripheral mode is eventually
/// introduced, the use of [SplendidBleCentral] will be more clear.
typedef SplendidBle = SplendidBleCentral;

/// [SplendidBleCentral] provides an interface to interact with Bluetooth functionalities from a Flutter app acting as a
/// BLE central device.
class SplendidBleCentral {
  /// The platform interface used to perform Bluetooth operations.
  ///
  /// This allows for dependency injection of different platform implementations (e.g., a fake platform for testing). If
  /// no platform is explicitly provided, the default singleton [CentralPlatformInterface.instance] is used.
  final CentralPlatformInterface _platform;

  /// Creates an instance of [SplendidBleCentral].
  SplendidBleCentral({CentralPlatformInterface? platform})
      : _platform = platform ?? CentralPlatformInterface.instance;

  /// Asks the platform to check the current status of the Bluetooth adapter.
  ///
  /// Returns a [Future] containing the current [BluetoothStatus].
  Future<BluetoothStatus> checkBluetoothAdapterStatus() async {
    return _platform.checkBluetoothAdapterStatus();
  }

  /// Emits the current status of the Bluetooth adapter whenever it changes.
  ///
  /// Returns a [Stream] of [BluetoothStatus].
  Future<Stream<BluetoothStatus>> emitCurrentBluetoothStatus() async {
    return _platform.emitCurrentBluetoothStatus();
  }

  /// Returns a list of BLE device identifiers that are currently connected to the host device.
  Future<List<ConnectedBleDevice>> getConnectedDevices(
    List<String> serviceUUIDs,
  ) async {
    return _platform.getConnectedDevices(serviceUUIDs);
  }

  /// Asks the platform to request Bluetooth permissions from the user.
  ///
  /// Returns a [Future] containing the current [BluetoothPermissionStatus].
  Future<BluetoothPermissionStatus> requestBluetoothPermissions() async {
    return _platform.requestBluetoothPermissions();
  }

  /// Emits the current Bluetooth permission status whenever it changes.
  ///
  /// Returns a [Stream] of [BluetoothPermissionStatus].
  Future<Stream<BluetoothPermissionStatus>>
      emitCurrentPermissionStatus() async {
    return _platform.emitCurrentPermissionStatus();
  }

  /// Asks the platform to stop scanning for Bluetooth devices.
  void stopScan() {
    return _platform.stopScan();
  }

  /// Asks the platform to start scanning for Bluetooth devices.
  ///
  /// Returns a [Stream] of [BleDevice] found during the scan.
  Future<Stream<BleDevice>> startScan({
    List<ScanFilter>? filters,
    ScanSettings? settings,
  }) async {
    return _platform.startScan(
      filters: filters,
      settings: settings,
    );
  }

  /// Asks the platform to connect to a Bluetooth device by its address.
  ///
  /// Returns a [Stream] of [BleConnectionState].
  Future<Stream<BleConnectionState>> connect({
    required String deviceAddress,
  }) async {
    return _platform.connect(deviceAddress: deviceAddress);
  }

  /// Asks the platform to discover available services for a connected device by its address.
  ///
  /// Returns a [Stream] of [BleService].
  Future<Stream<List<BleService>>> discoverServices(
    String deviceAddress,
  ) async {
    return _platform.discoverServices(deviceAddress);
  }

  /// Asks the platform to disconnect from a Bluetooth device by its address.
  Future<void> disconnect(String deviceAddress) {
    return _platform.disconnect(deviceAddress);
  }

  /// Asks the platform to get the current connection state for a Bluetooth device by its address.
  ///
  /// Returns a [Future] of [BleConnectionState].
  Future<BleConnectionState> getCurrentConnectionState(String deviceAddress) {
    return _platform.getCurrentConnectionState(deviceAddress);
  }
}
