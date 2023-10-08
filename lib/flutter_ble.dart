import 'package:flutter_ble/models/ble_device.dart';
import 'package:flutter_ble/models/scan_filter.dart';
import 'package:flutter_ble/models/scan_settings.dart';
import 'dart:async';

import 'flutter_ble_platform_interface.dart';
import 'models/ble_connection_state.dart';
import 'models/ble_service.dart';
import 'models/bluetooth_permission_status.dart';
import 'models/bluetooth_status.dart';

class FlutterBle {
  /// Asks the platform to check the current status of the Bluetooth adapter.
  ///
  /// Returns a `Future` containing the current `BluetoothStatus`.
  Future<BluetoothStatus> checkBluetoothAdapterStatus() async {
    return FlutterBlePlatform.instance.checkBluetoothAdapterStatus();
  }

  /// Emits the current status of the Bluetooth adapter whenever it changes.
  ///
  /// Returns a `Stream` of `BluetoothStatus`.
  Stream<BluetoothStatus> emitCurrentBluetoothStatus() {
    return FlutterBlePlatform.instance.emitCurrentBluetoothStatus();
  }

  /// Asks the platform to stop scanning for Bluetooth devices.
  ///
  /// Returns `void`.
  void stopScan() {
    return FlutterBlePlatform.instance.stopScan();
  }

  /// Asks the platform to start scanning for Bluetooth devices.
  ///
  /// Returns a `Stream` of `BleDevice` found during the scan.
  Stream<BleDevice> startScan({List<ScanFilter>? filters, ScanSettings? settings}) {
    return FlutterBlePlatform.instance.startScan();
  }

  /// Asks the platform to connect to a Bluetooth device by its address.
  ///
  /// Returns a `Stream` of `BleConnectionState`.
  Stream<BleConnectionState> connect({required String deviceAddress}) {
    return FlutterBlePlatform.instance.connect(deviceAddress: deviceAddress);
  }

  /// Asks the platform to discover available services for a connected device by its address.
  ///
  /// Returns a `Stream` of `BleService`.
  Stream<List<BleService>> discoverServices(String deviceAddress) {
    return FlutterBlePlatform.instance.discoverServices(deviceAddress);
  }

  /// Asks the platform to disconnect from a Bluetooth device by its address.
  ///
  /// Returns a `Future` of `void`.
  Future<void> disconnect(String deviceAddress) {
    return FlutterBlePlatform.instance.disconnect(deviceAddress);
  }

  /// Asks the platform to get the current connection state for a Bluetooth device by its address.
  ///
  /// Returns a `Future` of `BleConnectionState`.
  Future<BleConnectionState> getCurrentConnectionState(String deviceAddress) {
    return FlutterBlePlatform.instance.getCurrentConnectionState(deviceAddress);
  }

  /// Asks the platform to request Bluetooth permissions from the user.
  ///
  /// Returns a `Future` containing the current `BluetoothPermissionStatus`.
  Future<BluetoothPermissionStatus> requestBluetoothPermissions() async {
    return FlutterBlePlatform.instance.requestBluetoothPermissions();
  }

  /// Emits the current Bluetooth permission status whenever it changes.
  ///
  /// Returns a `Stream` of `BluetoothPermissionStatus`.
  Stream<BluetoothPermissionStatus> emitCurrentPermissionStatus() {
    return FlutterBlePlatform.instance.emitCurrentPermissionStatus();
  }
}

