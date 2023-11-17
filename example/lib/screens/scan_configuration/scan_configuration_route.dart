import 'package:flutter/material.dart';
import 'package:flutter_splendid_ble_example/screens/scan_configuration/scan_configuration_controller.dart';

/// The [ScanConfigurationRoute] is used to set up parameters for the Bluetooth scanning process.
class ScanConfigurationRoute extends StatefulWidget {
  const ScanConfigurationRoute({Key? key}) : super(key: key);

  @override
  ScanConfigurationController createState() => ScanConfigurationController();
}
