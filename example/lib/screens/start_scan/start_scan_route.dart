import 'package:flutter/material.dart';

import 'package:flutter_ble_example/screens/start_scan/start_scan_controller.dart';

/// A quite simple little screen. It has a button in the middle to start a scan for nearby Bluetooth devices.
class StartScanRoute extends StatefulWidget {
  const StartScanRoute({Key? key}) : super(key: key);

  @override
  StartScanController createState() => StartScanController();
}