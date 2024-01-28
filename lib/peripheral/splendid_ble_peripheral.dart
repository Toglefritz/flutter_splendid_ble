import 'package:flutter_splendid_ble/peripheral/peripheral_platform_interface.dart';

import '../shared/models/bluetooth_permission_status.dart';
import '../shared/models/bluetooth_status.dart';
import 'models/ble_server.dart';
import 'models/ble_server_configuration.dart';

/// [SplendidBlePeripheral] provides an interface to interact with Bluetooth functionalities from a Flutter app acting
/// as a BLE peripheral device.
///
/// This class offers methods // TODO add more
///
/// The class primarily uses asynchronous patterns like [Future] and [Stream] to provide real-time updates and
/// responses to Bluetooth operations. The methods in this class delegate the actual operations to
/// `FlutterSplendidBlePlatform.instance`, ensuring platform-agnostic behavior.
class SplendidBlePeripheral {
  /// Asks the platform to check the current status of the Bluetooth adapter.
  ///
  /// Returns a [Future] containing the current [BluetoothStatus].
  Future<BluetoothStatus> checkBluetoothAdapterStatus() async {
    return PeripheralPlatformInterface.instance.checkBluetoothAdapterStatus();
  }

  /// Emits the current status of the Bluetooth adapter whenever it changes.
  ///
  /// Returns a [Stream] of [BluetoothStatus].
  Stream<BluetoothStatus> emitCurrentBluetoothStatus() {
    return PeripheralPlatformInterface.instance.emitCurrentBluetoothStatus();
  }


  /// Asks the platform to request Bluetooth permissions from the user.
  ///
  /// Returns a [Future] containing the current [BluetoothPermissionStatus].
  Future<BluetoothPermissionStatus> requestBluetoothPermissions() async {
    return PeripheralPlatformInterface.instance.requestBluetoothPermissions();
  }

  /// Emits the current Bluetooth permission status whenever it changes.
  ///
  /// Returns a [Stream] of [BluetoothPermissionStatus].
  Stream<BluetoothPermissionStatus> emitCurrentPermissionStatus() {
    return PeripheralPlatformInterface.instance.emitCurrentPermissionStatus();
  }

  /// Sets up a BLE peripheral server with the specified configuration.
  Future<BleServer> setupPeripheralServer(BleServerConfiguration configuration) async {
    return PeripheralPlatformInterface.instance.setupPeripheralServer(configuration);
  }
}
