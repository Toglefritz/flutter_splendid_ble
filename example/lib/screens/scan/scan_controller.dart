import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_ble/flutter_ble.dart';
import 'package:flutter_ble/models/ble_device.dart';
import 'package:flutter_ble/models/exceptions/bluetooth_scan_exception.dart';
import 'package:flutter_ble_example/screens/device_details/device_details_route.dart';

import 'package:flutter_ble_example/screens/scan/scan_route.dart';
import 'package:flutter_ble_example/screens/scan/scan_view.dart';

import '../scan_configuration/scan_configuration_route.dart';

/// A controller for the [ScanRoute] that manages the state and owns all business logic.
class ScanController extends State<ScanRoute> {
  /// A [FlutterBle] instance used for Bluetooth operations conducted by this route.
  final FlutterBle _ble = FlutterBle();

  /// Determines if a scan is currently in progress.
  bool _scanInProgress = false;

  bool get scanInProgress => _scanInProgress;

  /// A [StreamSubscription] for the Bluetooth scanning process.
  StreamSubscription<BleDevice>? _scanStream;

  /// A list of [BleDevice]s discovered by the Bluetooth scan.
  List<BleDevice> discoveredDevices = [];

  @override
  void initState() {
    _startBluetoothScan();

    super.initState();
  }

  /// Starts a scan for nearby Bluetooth devices and adds a listener to the stream of devices detected by the scan.
  ///
  /// The scan is handled by the *flutter_ble* plugin. Regardless of operating system, the scan works by providing a
  /// callback function (in this case [_onDeviceDetected]) that is called whenever a device is detected by the scan.
  /// The [startScan] stream delivers an instance of [BleDevice] to the callback which contains information about
  /// the Bluetooth device.
  ///
  /// The
  void _startBluetoothScan() {
    _scanStream = _ble.startScan(filters: widget.filters, settings: widget.settings).listen(
      (device) => _onDeviceDetected(device),
      onError: (error) {
        // Handle the error here
        _handleScanError(error);
        return;
      },
    );

    setState(() {
      _scanInProgress = true;
    });
  }

  /// Handles errors returned on the [_scanStream].
  void _handleScanError(error) {
    // Create the SnackBar with the error message
    final snackBar = SnackBar(
      content: Text('Error scanning for Bluetooth devices: $error'),
      action: SnackBarAction(
        label: 'Dismiss',
        onPressed: () {
          // If you need to do anything when the user dismisses the SnackBar
        },
      ),
    );

    // Show the SnackBar using the ScaffoldMessenger
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// A callback used each time a new device is discovered by the Bluetooth scan.
  void _onDeviceDetected(BleDevice device) {
    debugPrint('Discovered BLE device: ${device.name}');

    // Add the newly discovered device to the list only if it not already in the list
    if (discoveredDevices.where((discoveredDevice) => discoveredDevice.address == device.address).isEmpty) {
      setState(() {
        discoveredDevices.add(device);
      });
    }
  }

  /// Handles taps on the "filter" button in the [AppBar].
  ///
  /// When this button is pressed, the app navigates to the [ScanConfigurationRoute], which allows for the
  /// [ScanFilter]s and [ScanSetting]s to be set up.
  void onFiltersPressed() {
    Navigator.pushReplacement<void, void>(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const ScanConfigurationRoute(),
      ),
    );
  }

  /// Handles taps on the action button in the [AppBar].
  ///
  /// This button is used to start or stop the Bluetooth scan. If a scan is in progress, as determined by the
  /// [_scanInProgress] boolean value, the function stops the scan. If, on the other hand, there is not a scan
  /// in progress, a scan is started.
  void onActionButtonPressed() {
    if(_scanInProgress) {
      _ble.stopScan();
      _scanStream?.cancel();

      setState(() {
        _scanInProgress = false;
      });
    } else {
      _startBluetoothScan();
    }
  }

  /// Handles taps on a scan result.
  void onResultTap(BleDevice device) {
    try {
      _ble.stopScan();
    } on BluetoothScanException catch (e) {
      // Handle the exception, possibly by showing an error message to the user.
      _showErrorMessage(e.message);
      return;
    }

    _scanStream?.cancel();

    Navigator.pushReplacement<void, void>(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) => DeviceDetailsRoute(
          device: device,
        ),
      ),
    );
  }

  /// Displays an error message to the user.
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) => ScanView(this);

  @override
  void dispose() {
    _scanStream?.cancel();

    super.dispose();
  }
}
