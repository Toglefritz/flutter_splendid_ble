import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_splendid_ble/central/models/connected_ble_device.dart';
import 'package:flutter_splendid_ble/central/models/exceptions/bluetooth_scan_exception.dart';
import 'package:flutter_splendid_ble/central/splendid_ble_central.dart';
import 'package:flutter_splendid_ble/shared/models/ble_device.dart';

import '../device_details/device_details_route.dart';
import 'connected_devices_route.dart';
import 'connected_devices_view.dart';

/// A controller for the [ConnectedDevicesRoute] that manages the state and owns all business logic.
class ConnectedDevicesController extends State<ConnectedDevicesRoute> {
  /// A [SplendidBleCentral] instance used for Bluetooth operations conducted by this route.
  final SplendidBleCentral _ble = SplendidBleCentral();

  /// A list of Bluetooth devices currently connected to the host device.
  List<ConnectedBleDevice>? connectedDevices;

  /// An error condition resulting from the attempt to get connected Bluetooth devices. This error is displayed in the
  /// UI.
  String? errorMessage;

  @override
  void initState() {
    _getConnectedDevices();

    super.initState();
  }

  /// Get a list of Bluetooth devices that are currently connected to the host device.
  // TODO(Toglefritz): replace the service UUID with a value from your own system
  Future<void> _getConnectedDevices() async {
    try {
      final List<ConnectedBleDevice> devices = await _ble.getConnectedDevices(['abcd1234-1234-1234-1234-1234567890aa']);

      debugPrint('Connected devices: $connectedDevices');

      setState(() {
        connectedDevices = devices;
      });
    } on BluetoothScanException catch (e) {
      _showErrorMessage(e.message);

      setState(() {
        errorMessage = e.message;
      });
    } catch (e) {
      if (e is UnsupportedError) {
        _showErrorMessage(e.message ?? 'This platform does not support getting connected devices.');

        setState(() {
          errorMessage = e.message ?? 'This platform does not support getting connected devices.';
        });
      } else {
        _showErrorMessage('An error occurred while getting connected devices.');

        setState(() {
          errorMessage = 'An error occurred while getting connected devices.';
        });
      }
    }
  }

  /// Handles taps on one of the connected devices.
  void onResultTap(ConnectedBleDevice deviceIdentifier) {
    // Create a BleDevice instance from the device address.
    final device = BleDevice(
      address: deviceIdentifier.address,
      name: deviceIdentifier.name,
      rssi: deviceIdentifier.rssi, // Always zero
      manufacturerData: deviceIdentifier.manufacturerData, // Always null
    );

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
  Widget build(BuildContext context) => ConnectedDevicesView(this);
}
