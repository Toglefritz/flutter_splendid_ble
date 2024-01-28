import 'package:flutter_splendid_ble/peripheral/peripheral_platform_interface.dart';

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
  /// Sets up a BLE peripheral server with the specified configuration.
  Future<BleServer> setupPeripheralServer(BleServerConfiguration configuration) async {
    return PeripheralPlatformInterface.instance.setupPeripheralServer(configuration);
  }
}
