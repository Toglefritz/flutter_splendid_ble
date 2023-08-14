import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_ble/flutter_ble.dart';
import 'package:flutter_ble/models/ble_device.dart';

import 'package:flutter_ble_example/screens/scan/scan_route.dart';
import 'package:flutter_ble_example/screens/scan/scan_view.dart';

/// A controller for the [ScanRoute] that manages the state and owns all business logic.
class ScanController extends State<ScanRoute> {
  /// A [FlutterBle] instance used for Bluetooth operations conducted by this route.
  final FlutterBle _ble = FlutterBle();

  /// A [StreamSubscription] for the Bluetooth scanning process.
  StreamSubscription<BleDevice>? _scanStream;

  @override
  void initState() {
    _startBluetoothScan();

    super.initState();
  }

  /// Starts a scan for nearby Bluetooth devices and adds a listener to the stream of devices detected by the scan.
  void _startBluetoothScan() {
    _scanStream = _ble.startScan().listen((device) => onDeviceDetected(device));
  }

  /// A callback used each time a new device is discovered by the Bluetooth scan.
  void onDeviceDetected(BleDevice device) {
    debugPrint('Discovered BLE device: ${device.name}');

    // TODO more to do in here
  }

  @override
  Widget build(BuildContext context) => ScanView(this);

  @override
  void dispose() {
    _scanStream?.cancel();

    super.dispose();
  }
}
