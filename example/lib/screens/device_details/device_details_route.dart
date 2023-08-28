import 'package:flutter/material.dart';
import 'package:flutter_ble/models/ble_device.dart';

import 'device_details_controller.dart';

/// Displays information about a [BleDevice] selected from the Bluetooth scan and provides controls for doing stuff
/// to it.
class DeviceDetailsRoute extends StatefulWidget {
  const DeviceDetailsRoute({
    Key? key,
    required this.device,
  }) : super(key: key);

  /// A [BleDevice] instance selected from the Bluetooth scan. Details and controls for this device will be
  /// presented by this route.
  final BleDevice device;

  @override
  DeviceDetailsController createState() => DeviceDetailsController();
}
