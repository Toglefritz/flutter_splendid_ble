
import 'flutter_ble_platform_interface.dart';

class FlutterBle {
  Future<String?> getPlatformVersion() {
    return FlutterBlePlatform.instance.getPlatformVersion();
  }
}
