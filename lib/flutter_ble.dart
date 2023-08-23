import 'package:flutter_ble/models/ble_device.dart';
import 'package:flutter_ble/models/scan_filter.dart';
import 'package:flutter_ble/models/scan_settings.dart';

import 'flutter_ble_platform_interface.dart';
import 'models/bluetooth_status.dart';

class FlutterBle {
  Future<BluetoothStatus> checkBluetoothAdapterStatus() async {
    return FlutterBlePlatform.instance.checkBluetoothAdapterStatus();
  }

  void stopScan() {
    return FlutterBlePlatform.instance.stopScan();
  }

  Stream<BleDevice> startScan({List<ScanFilter>? filters, ScanSettings? settings}) {
    return FlutterBlePlatform.instance.startScan();
  }
}
