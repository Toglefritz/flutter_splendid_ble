import 'package:flutter_splendid_ble/peripheral/peripheral_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../shared/models/bluetooth_permission_status.dart';
import '../shared/models/bluetooth_status.dart';
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

  /// Checks the status of the host device's Bluetooth adapter and returns a [BluetoothStatus] to communicate the
  /// current status of the adapter.
  Future<BluetoothStatus> checkBluetoothAdapterStatus() async {
    throw UnimplementedError(
        'checkBluetoothAdapterStatus() has not been implemented.');
  }

  /// Emits the current Bluetooth adapter status to the Dart side.
  Stream<BluetoothStatus> emitCurrentBluetoothStatus() {
    throw UnimplementedError(
        'emitCurrentBluetoothStatus() has not been implemented.');
  }

  /// Requests Bluetooth permissions from the user.
  Future<BluetoothPermissionStatus> requestBluetoothPermissions() async {
    throw UnimplementedError(
        'requestBluetoothPermissions() has not been implemented.');
  }

  /// Emits the current Bluetooth permission status whenever it changes.
  Stream<BluetoothPermissionStatus> emitCurrentPermissionStatus() {
    throw UnimplementedError(
        'emitCurrentPermissionStatus() has not been implemented.');
  }

  /// Sets up a BLE peripheral server with the specified configuration.
  Future<BleServer> setupPeripheralServer(BleServerConfiguration configuration) async {
    throw UnimplementedError(
        'setupPeripheralServer() has not been implemented.');
  }
}
