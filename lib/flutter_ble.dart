import 'package:flutter_ble/models/ble_device.dart';
import 'package:flutter_ble/models/scan_filter.dart';
import 'package:flutter_ble/models/scan_settings.dart';

import 'flutter_ble_platform_interface.dart';
import 'models/ble_connection_state.dart';
import 'models/ble_service.dart';
import 'models/bluetooth_status.dart';

class FlutterBle {
  Future<BluetoothStatus> checkBluetoothAdapterStatus() async {
    return FlutterBlePlatform.instance.checkBluetoothAdapterStatus();
  }

  Stream<BluetoothStatus> emitCurrentBluetoothStatus() {
    return FlutterBlePlatform.instance.emitCurrentBluetoothStatus();
  }

  void stopScan() {
    return FlutterBlePlatform.instance.stopScan();
  }

  Stream<BleDevice> startScan({List<ScanFilter>? filters, ScanSettings? settings}) {
    return FlutterBlePlatform.instance.startScan();
  }

  Stream<BleConnectionState> connect({required String deviceAddress}) {
    return FlutterBlePlatform.instance.connect(deviceAddress: deviceAddress);
  }

  Stream<List<BleService>> discoverServices(String deviceAddress) {
    return FlutterBlePlatform.instance.discoverServices(deviceAddress);
  }

  Future<void> disconnect(String deviceAddress) {
    return FlutterBlePlatform.instance.disconnect(deviceAddress);
  }

  Future<BleConnectionState> getCurrentConnectionState(String deviceAddress) {
    return FlutterBlePlatform.instance.getCurrentConnectionState(deviceAddress);
  }
}
