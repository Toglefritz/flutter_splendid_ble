import 'package:flutter/material.dart';

import 'ble_test_controller.dart';

/// Route for the BLE testing screen.
///
/// This screen provides a terminal-style interface for running and displaying results of BLE plugin tests against the
/// ESP32 test device.
class BleTestRoute extends StatefulWidget {
  /// Creates a new BLE test route.
  const BleTestRoute({super.key});

  @override
  State<BleTestRoute> createState() => BleTestController();
}
