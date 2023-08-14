import 'package:flutter/material.dart';

import 'package:flutter_ble_example/screens/scan/scan_controller.dart';

/// Automatically starts a scan for nearby Bluetooth devices and presents the detected devices in a list.
class ScanRoute extends StatefulWidget {
  const ScanRoute({Key? key}) : super(key: key);

  @override
  ScanController createState() => ScanController();
}