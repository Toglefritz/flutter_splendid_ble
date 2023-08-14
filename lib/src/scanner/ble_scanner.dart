import '../../models/ble_device.dart';

/// Scanning related functionalities.
import 'dart:async';
import 'package:flutter/services.dart';

/// The BleScanner class encapsulates everything related to scanning for BLE devices. It contains methods to start
/// and stop scanning and manages the stream of discovered devices.
class BleScanner {
  final MethodChannel _channel;

  /// A controller for the stream used to deliver discovered [BleDevice]s to the Dart code.
  late StreamController<BleDevice> _streamController;

  /// This constructor creates a [BleScanner] object, and at the time of construction, it initializes the
  /// [_channel] field with a [MethodChannel] object configured with the given [channelName]. It sets up the
  /// basic communication pathway for the scanning functionality between the Dart code and the platform-specific
  /// code for the plugin.
  BleScanner(String channelName) : _channel = MethodChannel(channelName) {
    _streamController = StreamController<BleDevice>.broadcast();
    // Set a method call handler for incoming device information.
    _channel.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'bleDeviceScanned') {
        _streamController.add(BleDevice.fromMap(call.arguments));
      }
    });
  }

  /// Starts scanning for nearby BLE devices.
  ///
  /// Returns a stream of [BleDevice] objects representing each discovered device.
  Stream<BleDevice> startScan() {
    _channel.invokeMethod('startScan');
    return _streamController.stream;
  }

  /// Stops the ongoing scan for nearby BLE devices.
  Future<void> stopScan() async {
    await _channel.invokeMethod('stopScan');
  }

  /// Closes the StreamController when this object is disposed of.
  void dispose() {
    _streamController.close();
  }
}
