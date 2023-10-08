import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_ble_platform_interface.dart';

/// An implementation of [FlutterBlePlatform] that uses method channels.
class MethodChannelFlutterBle extends FlutterBlePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_ble');
}
