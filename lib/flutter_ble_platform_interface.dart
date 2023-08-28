import 'package:flutter_ble/models/ble_device.dart';
import 'package:flutter_ble/models/scan_filter.dart';
import 'package:flutter_ble/models/scan_settings.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'models/ble_connection_state.dart';
import 'models/bluetooth_status.dart';
import 'src/channel/flutter_ble_method_channel.dart';

abstract class FlutterBlePlatform extends PlatformInterface {
  /// Constructs a FlutterBlePlatform.
  FlutterBlePlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterBlePlatform _instance = MethodChannelFlutterBle();

  /// The default instance of [FlutterBlePlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterBle].
  static FlutterBlePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterBlePlatform] when
  /// they register themselves.
  static set instance(FlutterBlePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Checks the status of the host device's Bluetooth adapter and returns a [BluetoothStatus] to communicate the
  /// current status of the adapter.
  Future<BluetoothStatus> checkBluetoothAdapterStatus() async {
    throw UnimplementedError('checkBluetoothAdapterStatus() has not been implemented.');
  }

  /// Starts a scan for nearby BLE devices and returns a [Stream] of [BleDevice] instances representing the BLE
  /// devices that were discovered. On the Flutter side, listeners can be added to this stream so they can
  /// respond to Bluetooth devices being discovered, for example by presenting the list in the user interface
  /// or enabling controllers to find and connect to specific devices.
  Stream<BleDevice> startScan({List<ScanFilter>? filters, ScanSettings? settings}) {
    throw UnimplementedError('startScan() has not been implemented.');
  }

  /// Stops an ongoing Bluetooth scan or, if no scan is running, does nothing.
  void stopScan() {
    throw UnimplementedError('stopScan() has not been implemented.');
  }

  /// Initiates a connection to a BLE peripheral and returns a Stream representing
  /// the connection state.
  Stream<BleConnectionState> connect(String deviceAddress) {
    throw UnimplementedError('connect() has not been implemented.');
  }

  /// Terminates the connection to a BLE peripheral.
  /// Initiates a connection to a BLE peripheral and returns a Stream representing
  /// the connection state.
  Future<void> disconnect(String deviceAddress) async {
    throw UnimplementedError('disconnect() has not been implemented.');
  }

  /// Returns the current connection state for the Bluetooth device with the specified address.
  Future<BleConnectionState> getCurrentConnectionState(String deviceAddress) {
    throw UnimplementedError('getCurrentConnectionState() has not been implemented.');
  }
}
