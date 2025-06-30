import 'package:flutter/material.dart';
import 'package:flutter_splendid_ble/central/splendid_ble_central.dart';
import 'package:flutter_splendid_ble/shared/models/ble_device.dart';

import '../scan/scan_route.dart';
import 'device_details_controller.dart';

/// Displays information about a [BleDevice] selected from the Bluetooth scan and provides controls for doing stuff
/// to it.
///
/// When this screen is initially loaded, resulting from navigation from the [ScanRoute], the Bluetooth device will
/// most likely not be connected to the host mobile device. So, the screen initially presents preliminary information
/// about the Bluetooth peripheral and a button that can be used to begin the connection process.
///
/// Once a connection to the peripheral is established, this screen presents a button that can be used to perform
/// service and characteristic discovery on the module. The *flutter_ble* library also offers the ability to
/// perform service an characteristic discovery automatically after a connection is established using a boolean
/// in the `connect` method.
class DeviceDetailsRoute extends StatefulWidget {
  /// Creates an instance of [DeviceDetailsRoute].
  DeviceDetailsRoute({
    required this.device,
    SplendidBleCentral? ble,
    super.key,
  }) : ble = ble ?? SplendidBleCentral();

  /// A [SplendidBleCentral] instance used for Bluetooth operations conducted by this route.
  final SplendidBleCentral ble;

  /// A [BleDevice] instance selected from the Bluetooth scan. Details and controls for this device will be
  /// presented by this route.
  final BleDevice device;

  @override
  DeviceDetailsController createState() => DeviceDetailsController();
}
