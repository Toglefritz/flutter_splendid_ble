import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../central/models/ble_characteristic.dart';
import '../central/models/ble_characteristic_value.dart';
import '../central/models/ble_connection_state.dart';
import '../central/models/ble_service.dart';
import '../central/models/scan_filter.dart';
import '../central/models/scan_settings.dart';
import '../shared/models/ble_device.dart';
import '../shared/models/bluetooth_permission_status.dart';
import '../shared/models/bluetooth_status.dart';
import 'central_method_channel.dart';
import 'models/connected_ble_device.dart';

/// The interface that implementations of splendid_ble must implement.
abstract class CentralPlatformInterface extends PlatformInterface {
  /// Constructs a [CentralPlatformInterface].
  CentralPlatformInterface() : super(token: _token);

  /// The token used to verify that the instance is a valid implementation of [CentralPlatformInterface].
  static final Object _token = Object();

  /// The default instance of [CentralPlatformInterface] to use.
  static CentralPlatformInterface _instance = CentralMethodChannel();

  /// The default instance of [CentralPlatformInterface] to use.
  static CentralPlatformInterface get instance => _instance;

  /// Platform-specific implementations should set this with their own platform-specific class that extends
  /// [CentralPlatformInterface] when they register themselves.
  static set instance(CentralPlatformInterface instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Checks the status of the host device's Bluetooth adapter and returns a [BluetoothStatus] to communicate the
  /// current status of the adapter.
  Future<BluetoothStatus> checkBluetoothAdapterStatus() async {
    throw UnimplementedError(
      'checkBluetoothAdapterStatus() has not been implemented.',
    );
  }

  /// Emits the current Bluetooth adapter status to the Dart side.
  Stream<BluetoothStatus> emitCurrentBluetoothStatus() {
    throw UnimplementedError(
      'emitCurrentBluetoothStatus() has not been implemented.',
    );
  }

  /// Returns a list of BLE device identifiers that are currently connected to the host device.
  Future<List<ConnectedBleDevice>> getConnectedDevices(List<String> serviceUUIDs) async {
    throw UnimplementedError(
      'getConnectedDevices() has not been implemented.',
    );
  }

  /// Requests Bluetooth permissions from the user.
  Future<BluetoothPermissionStatus> requestBluetoothPermissions() async {
    throw UnimplementedError(
      'requestBluetoothPermissions() has not been implemented.',
    );
  }

  /// Emits the current Bluetooth permission status whenever it changes.
  Stream<BluetoothPermissionStatus> emitCurrentPermissionStatus() {
    throw UnimplementedError(
      'emitCurrentPermissionStatus() has not been implemented.',
    );
  }

  /// Starts a scan for nearby BLE devices and returns a [Stream] of [BleDevice] instances representing the BLE
  /// devices that were discovered. On the Flutter side, listeners can be added to this stream so they can
  /// respond to Bluetooth devices being discovered, for example by presenting the list in the user interface
  /// or enabling controllers to find and connect to specific devices.
  Stream<BleDevice> startScan({
    List<ScanFilter>? filters,
    ScanSettings? settings,
  }) {
    throw UnimplementedError('startScan() has not been implemented.');
  }

  /// Stops an ongoing Bluetooth scan or, if no scan is running, does nothing.
  void stopScan() {
    throw UnimplementedError('stopScan() has not been implemented.');
  }

  /// Initiates a connection to a BLE peripheral and returns a Stream representing the connection state.
  Stream<BleConnectionState> connect({required String deviceAddress}) {
    throw UnimplementedError('connect() has not been implemented.');
  }

  /// Triggers the service discovery process manually.
  Stream<List<BleService>> discoverServices(String deviceAddress) {
    throw UnimplementedError('discoverServices() has not been implemented.');
  }

  /// Terminates the connection to a BLE peripheral. Initiates a connection to a BLE peripheral and returns a
  /// [Stream] representing the connection state.
  Future<void> disconnect(String deviceAddress) async {
    throw UnimplementedError('disconnect() has not been implemented.');
  }

  /// Returns the current connection state for the Bluetooth device with the specified address.
  Future<BleConnectionState> getCurrentConnectionState(String deviceAddress) {
    throw UnimplementedError(
      'getCurrentConnectionState() has not been implemented.',
    );
  }

  /// Writes data to a specified characteristic.
  Future<void> writeCharacteristic({
    required BleCharacteristic characteristic,
    required String value,
    int? writeType,
  }) async {
    throw UnimplementedError('writeCharacteristic() has not been implemented.');
  }

  /// Reads the value of a specified Bluetooth characteristic.
  ///
  /// This method is accessed through the [BleCharacteristic] class.
  Future<BleCharacteristicValue> readCharacteristic({
    required BleCharacteristic characteristic,
    required Duration timeout,
  }) async {
    throw UnimplementedError('readCharacteristic() has not been implemented.');
  }

  /// Subscribes to a Bluetooth characteristic to listen for updates.
  Stream<BleCharacteristicValue> subscribeToCharacteristic(
    BleCharacteristic characteristic,
  ) {
    throw UnimplementedError(
      'subscribeToCharacteristic() has not been implemented.',
    );
  }

  /// Unsubscribes from a Bluetooth characteristic.
  void unsubscribeFromCharacteristic(BleCharacteristic characteristic) {
    throw UnimplementedError(
      'unsubscribeFromCharacteristic() has not been implemented.',
    );
  }
}
