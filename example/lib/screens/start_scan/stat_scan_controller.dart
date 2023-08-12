import 'package:flutter/material.dart';

import 'package:flutter_ble_example/screens/start_scan/start_scan_route.dart';
import 'package:flutter_ble_example/screens/start_scan/start_scan_view.dart';

/// A controller for the [StartScanRoute] that manages the state and owns all business logic.
class StartScanController extends State<StartScanRoute> {
  @override
  Widget build(BuildContext context) => StartScanView(this);
}