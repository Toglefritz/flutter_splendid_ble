
import 'package:flutter_ble/models/ble_device.dart';

import 'flutter_ble_platform_interface.dart';

class FlutterBle {
  Stream<BleDevice> startScan() {
    return FlutterBlePlatform.instance.startScan();
  }
}
