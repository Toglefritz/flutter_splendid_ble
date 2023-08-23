import 'dart:async';

import 'package:flutter/services.dart';

import '../../flutter_ble_platform_interface.dart';
import '../../models/ble_device.dart';
import '../../models/bluetooth_status.dart';
import '../../models/scan_filter.dart';
import '../../models/scan_settings.dart';

/// An implementation of [FlutterBlePlatform] that uses method channels.
class MethodChannelFlutterBle extends FlutterBlePlatform {
  /// The method channel used to interact with the native platform.
  final MethodChannel _channel = const MethodChannel('flutter_ble');

  /// Checks the status of the Bluetooth adapter on the device.
  ///
  /// This method communicates with the native Android code to obtain the current status of the
  /// Bluetooth adapter, and returns one of the values from the [BluetoothStatus] enumeration.
  ///
  /// * [BluetoothStatus.ENABLED]: Bluetooth is enabled and ready for connections.
  /// * [BluetoothStatus.DISABLED]: Bluetooth is disabled and not available for use.
  /// * [BluetoothStatus.NOT_AVAILABLE]: Bluetooth is not available on the device.
  ///
  /// Returns a Future containing the [BluetoothStatus] representing the current status of the
  /// Bluetooth adapter on the device.
  @override
  Future<BluetoothStatus> checkBluetoothAdapterStatus() async {
    final String statusString = await _channel.invokeMethod('checkBluetoothAdapterStatus');
    return BluetoothStatus.values.firstWhere((e) => e.identifier == statusString);
  }

  /// Starts a scan for nearby BLE devices.
  ///
  /// Returns a stream of [BleDevice] objects representing each discovered device.
  @override
  Stream<BleDevice> startScan({List<ScanFilter>? filters, ScanSettings? settings}) {
    StreamController<BleDevice> streamController = StreamController<BleDevice>.broadcast();

    // Listen to the platform side for scanned devices.
    _channel.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'bleDeviceScanned') {
        BleDevice device = BleDevice.fromMap(call.arguments);
        streamController.add(device);
      }
    });

    // Convert filters and settings into map representations if provided.
    final List<Map<String, dynamic>>? filtersMap = filters?.map((filter) => filter.toMap()).toList();
    final Map<String, dynamic>? settingsMap = settings?.toMap();

    // Begin the scan on the platform side, including the filters and settings in the method call if provided.
    _channel.invokeMethod('startScan', {
      'filters': filtersMap,
      'settings': settingsMap,
    });

    return streamController.stream;
  }

  /// Stops an ongoing Bluetooth scan.
  @override
  void stopScan() {
    _channel.invokeMethod('stopScan');
  }
}
