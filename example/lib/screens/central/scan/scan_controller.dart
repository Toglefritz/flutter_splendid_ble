import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_splendid_ble/central/models/exceptions/bluetooth_scan_exception.dart';
import 'package:flutter_splendid_ble/central/models/scan_filter.dart';
import 'package:flutter_splendid_ble/central/models/scan_settings.dart';
import 'package:flutter_splendid_ble/central/splendid_ble_central.dart';
import 'package:flutter_splendid_ble/shared/models/ble_device.dart';

import '../device_details/device_details_route.dart';
import '../scan_configuration/scan_configuration_route.dart';
import 'scan_route.dart';
import 'scan_view.dart';

/// A controller for the [ScanRoute] that manages the state and owns all business logic.
class ScanController extends State<ScanRoute> {
  /// A [SplendidBleCentral] instance used for Bluetooth operations conducted by this route.
  late SplendidBleCentral _ble;

  /// Determines if a scan is currently in progress.
  bool _scanInProgress = false;

  /// Determines if a scan is currently in progress.
  bool get scanInProgress => _scanInProgress;

  /// A [StreamSubscription] for the Bluetooth scanning process.
  StreamSubscription<BleDevice>? _scanStream;

  /// A list of [BleDevice]s discovered by the Bluetooth scan.
  List<BleDevice> discoveredDevices = [];

  @override
  void initState() {
    // Access the injected instance from the widget
    _ble = widget.ble;

    _startBluetoothScan();

    super.initState();
  }

  /// Starts a scan for nearby Bluetooth devices and adds a listener to the stream of devices detected by the scan.
  ///
  /// The scan is handled by the *flutter_ble* plugin. Regardless of operating system, the scan works by providing a
  /// callback function (in this case [_onDeviceDetected]) that is called whenever a device is detected by the scan.
  /// The `startScan` stream delivers an instance of [BleDevice] to the callback which contains information about
  /// the Bluetooth device.
  ///
  /// Various filters can be applied to the scanning process to limit the selection of devices returned by the scan.
  /// See the [ScanFilter] class for full information about the available filters. But the most common filtering
  /// option is typically filtering by the UUID of the primary service of the BLE devices detected by the scan. This
  /// allows manufacturers of Bluetooth devices to ensure that only their devices are returned by the Bluetooth scan,
  /// which is obviously useful for building a companion mobile app for these devices.
  Future<void> _startBluetoothScan() async {
    final Stream<BleDevice> scanStream = await _ble.startScan(filters: widget.filters, settings: widget.settings);

    _scanStream = scanStream.listen(
      _onDeviceDetected,
      // ignore: inference_failure_on_untyped_parameter
      onError: (dynamic error) {
        // Handle the error here
        if (error is BluetoothScanException) {
          debugPrint('Bluetooth scan error: ${error.message}');

          // If the error is a BluetoothScanException, handle it specifically
          _handleScanError(error);
        } else if (error is FormatException) {
          debugPrint('Format error: ${error.message}');
        }
        return;
      },
    );

    setState(() {
      _scanInProgress = true;
    });
  }

  /// Handles errors returned on the [_scanStream].
  void _handleScanError(BluetoothScanException error) {
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
  /// [ScanFilter]s and [ScanSettings]s to be set up.
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
    if (_scanInProgress) {
      _ble.stopScan();
      _scanStream?.cancel();

      setState(() {
        _scanInProgress = false;
      });
    } else {
      // Clear the existing discovered devices
      setState(() {
        discoveredDevices.clear();
      });

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
