import 'package:flutter/material.dart';

import 'package:flutter_splendid_ble/central/models/scan_filter.dart';
import 'package:flutter_splendid_ble/central/models/scan_settings.dart';
import 'package:flutter_splendid_ble_example/screens/central/scan_configuration/scan_configuration_route.dart';
import 'package:flutter_splendid_ble_example/screens/central/scan_configuration/scan_configuration_view.dart';

import '../scan/scan_route.dart';

/// A controller for the [ScanConfigurationRoute] that manages the state and owns all business logic.
class ScanConfigurationController extends State<ScanConfigurationRoute> {
  /// Determines the behavior of the Bluetooth scanning process with respect to how aggressively the Android
  /// operating system will surface Bluetooth devices detected by the scanning process.
  ScanMode? scanMode;

  /// A delay in reporting devices detected by the scan.
  int? reportDelay;

  /// Determines if the scanning process will
  bool allowDuplicates = false;

  /// A string used to filter the Bluetooth scan list to show only Bluetooth devices including this name in their
  /// advertising data.
  String? deviceName;

  /// A manufacturer ID, which is the initial part of the [bluetoothAddress] used to filter the Bluetooth scan to show
  /// only devices from the same manufacturer (or the same manufacturer of the Bluetooth radio). This is useful for
  /// displaying only devices from a particular device vendor.
  int? manufacturerId;

  /// A list of Bluetooth primary service UUID values used to filter the Bluetooth scan to show only devices with
  /// one of the listed UUID values as their primary services. Since the primary service UUIDs are specified in the
  /// firmware of a Bluetooth device, this is another method of filtering to show only devices for a particular product
  /// line or from a particular manufacturer.
  List<String>? serviceUuids;

  /// Handles changes on the dropdown menu used to select a [ScanMode].
  void onScanModeChanged(ScanMode? value) {
    setState(() {
      scanMode = value;
    });
  }

  /// Validates input to the Bluetooth scan report delay field.
  String? validateReportDelay(String? value) {
    if (value != null && int.tryParse(value) != null) {
      reportDelay = int.parse(value);
      return null;
    } else {
      return 'Please enter a valid number';
    }
  }

  /// Handles changes in the checkbox used to select an option for the allow duplicates scan setting.
  void onAllowDuplicatesChanged(bool? value) {
    setState(() {
      allowDuplicates = value ?? false;
    });
  }

  /// Handles changes in the Bluetooth device name field used to filter the Bluetooth scan list.
  void onDeviceNameChanged(String value) {
    deviceName = value;
  }

  /// Handles changes in the Bluetooth device manufacturer ID used to filter the Bluetooth scan list.
  void onManufacturerIdChanged(String value) {
    if (int.tryParse(value) != null) {
      manufacturerId = int.parse(value);
    }
  }

  /// Handles changes in the Bluetooth device UUID list used to filter the Bluetooth scan list.
  void onServiceUuidsChanged(String value) {
    serviceUuids = value.split(',');
  }

  /// Handles taps on the "Done" CTA button.
  ///
  /// When the form used to configure scan filters and settings is submitted, the app navigates back to the
  /// [ScanRoute] and provides the information to be used for the next scan.
  void onDone() {
    // Create a ScanSettings instance based on the inputs into the form
    ScanSettings settings = ScanSettings(
      scanMode: scanMode,
      reportDelayMillis: reportDelay,
      allowDuplicates: allowDuplicates,
    );

    // Create a ScanFilter instance based on the inputs into the form
    ScanFilter filter = ScanFilter(
      deviceName: deviceName,
      serviceUuids: serviceUuids,
      manufacturerId: manufacturerId,
    );

    Navigator.pushReplacement<void, void>(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) => ScanRoute(
          filters: [filter],
          settings: settings,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ScanConfigurationView(this);
}
