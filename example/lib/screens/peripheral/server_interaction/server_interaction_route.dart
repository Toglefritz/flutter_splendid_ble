import 'package:flutter/material.dart';
import 'package:flutter_splendid_ble/peripheral/models/ble_server.dart';
import 'package:flutter_splendid_ble/shared/models/ble_device.dart';
import 'package:flutter_splendid_ble_example/screens/peripheral/server_interaction/server_interaction_controller.dart';

/// Provides an interface for controlling a [BleServer] and interacting with a peripherals connected to the server.
///
// TODO(Toglefritz): add more documentation
class ServerInteractionRoute extends StatefulWidget {
  const ServerInteractionRoute({
    Key? key,
    required this.server,
  }) : super(key: key);

  /// The [BleDevice] with which the app will communicate in this route.
  final BleServer server;

  @override
  ServerInteractionController createState() => ServerInteractionController();
}
