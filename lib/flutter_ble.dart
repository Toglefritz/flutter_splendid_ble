import 'package:flutter_ble/models/ble_device.dart';
import 'package:flutter_ble/models/scan_filter.dart';
import 'package:flutter_ble/models/scan_settings.dart';

import 'flutter_ble_platform_interface.dart';

class FlutterBle {
  Stream<BleDevice> startScan({List<ScanFilter>? filters, ScanSettings? settings}) {
    return FlutterBlePlatform.instance.startScan();
  }
}
