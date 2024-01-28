import 'package:flutter_splendid_ble/peripheral/peripheral_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'models/ble_server.dart';
import 'models/ble_server_configuration.dart';

abstract class PeripheralPlatformInterface extends PlatformInterface {
  /// Constructs a [CentralPlatformInterface].
  PeripheralPlatformInterface() : super(token: _token);

  static final Object _token = Object();

  static PeripheralPlatformInterface _instance = PeripheralMethodChannel();

  /// The default instance of [PeripheralPlatformInterface] to use.
  static PeripheralPlatformInterface get instance => _instance;

  /// Platform-specific implementations should set this with their own platform-specific class that extends
  /// [PeripheralPlatformInterface] when they register themselves.
  static set instance(PeripheralPlatformInterface instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Sets up a BLE peripheral server with the specified configuration.
  Future<BleServer> setupPeripheralServer(BleServerConfiguration configuration) async {
    throw UnimplementedError(
        'setupPeripheralServer() has not been implemented.');
  }
}
