import 'dart:async';

import 'package:flutter/services.dart';

import '../../flutter_ble_platform_interface.dart';
import '../../models/ble_device.dart';

/// An implementation of [FlutterBlePlatform] that uses method channels.
class MethodChannelFlutterBle extends FlutterBlePlatform {
  /// The method channel used to interact with the native platform.
  final MethodChannel _channel = const MethodChannel('flutter_ble');

  /// Starts a scan for nearby BLE devices.
  ///
  /// Returns a stream of [BleDevice] objects representing each discovered device.
  @override
  Stream<BleDevice> startScan() {
    StreamController<BleDevice> streamController = StreamController<BleDevice>.broadcast();

    // Listen to the platform side for scanned devices.
    _channel.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'bleDeviceScanned') {
        BleDevice device = BleDevice.fromMap(call.arguments);
        streamController.add(device);
      }
    });

    // Begin the scan on the platform side.
    _channel.invokeMethod('startScan');

    return streamController.stream;
  }
}
