import 'package:flutter_ble/models/ble_device.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

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

  /// Starts a scan for nearby BLE devices and returns a [Stream] of [BleDevice] instances representing the BLE
  /// devices that were discovered. On the Flutter side, listeners can be added to this stream so they can
  /// respond to Bluetooth devices being discovered, for example by presenting the list in the user interface
  /// or enabling controllers to find and connect to specific devices.
  Stream<BleDevice> startScan() {
    throw UnimplementedError('startScan() has not been implemented.');
  }
}
