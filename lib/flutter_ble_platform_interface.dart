import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_ble_method_channel.dart';

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

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
