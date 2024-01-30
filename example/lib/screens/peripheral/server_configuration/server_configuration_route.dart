import 'package:flutter/material.dart';

import 'package:flutter_splendid_ble_example/screens/peripheral/server_configuration/server_configuration_controller.dart';

/// Displays configuration options for a BLE peripheral device server and allows for the setting of those options.
///
/// For a Flutter application acting as BLE peripheral, this route allows various settings for the peripheral to be
/// configured.
class ServerConfigurationRoute extends StatefulWidget {
  const ServerConfigurationRoute({Key? key}) : super(key: key);

  @override
  ServerConfigurationController createState() => ServerConfigurationController();
}
