import 'package:flutter/material.dart';
import 'package:flutter_ble/models/scan_filter.dart';
import 'package:flutter_ble/models/scan_settings.dart';

import 'package:flutter_ble_example/screens/scan/scan_controller.dart';

/// Automatically starts a scan for nearby Bluetooth devices and presents the detected devices in a list.
class ScanRoute extends StatefulWidget {
  const ScanRoute({
    this.filters,
    this.settings,
    Key? key,
  }) : super(key: key);

  /// A list of [ScanFilter]s to be used for the scanning process.
  ///
  /// The [ScanFilter]s allow for control over the devices that will be returned by the Bluetooth scanning process.
  /// Different information about Bluetooth devices detected by the scanning process can be used to filter the list
  /// including device names, service UUIDs, manufacturing data, vendor identifiers, and other data. This information
  /// is all specified in the firmware running on the Bluetooth devices.
  ///
  /// Using filters for the scanning process is useful to, for example, only return a specific type of Bluetooth device
  /// that your team or company makes. It can also be used to return only devices made by a particular vendor.
  final List<ScanFilter>? filters;

  /// [ScanSettings] used to control the behavior of the scan itself.
  ///
  /// The options that can be specified in the [ScanSettings] include how aggressive the scanning process is when it
  /// comes to returning [BleDeice] instances for peripherals detected during the scanning process, a delay between
  /// detecting a device and returning it in the scan list, and whether or not the same device will be returned
  /// multiple times during the scanning process.
  final ScanSettings? settings;

  @override
  ScanController createState() => ScanController();
}
