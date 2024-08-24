import 'package:flutter/material.dart';

import 'scan_configuration_controller.dart';

/// The [ScanConfigurationRoute] is used to set up parameters for the Bluetooth scanning process.
class ScanConfigurationRoute extends StatefulWidget {
  /// Creates an instance of [ScanConfigurationRoute].
  const ScanConfigurationRoute({super.key});

  @override
  ScanConfigurationController createState() => ScanConfigurationController();
}
