import 'package:flutter/material.dart';
import 'package:flutter_splendid_ble/peripheral/models/ble_server.dart';
import 'package:flutter_splendid_ble/peripheral/models/ble_server_configuration.dart';
import 'package:flutter_splendid_ble_example/screens/peripheral/server_interaction/server_interaction_route.dart';
import 'package:uuid/uuid.dart';

import 'package:flutter_splendid_ble/peripheral/splendid_ble_peripheral.dart';
import 'package:flutter_splendid_ble_example/screens/peripheral/server_configuration/server_configuration_route.dart';
import 'package:flutter_splendid_ble_example/screens/peripheral/server_configuration/server_configuration_view.dart';

import '../../home/home_route.dart';

/// A controller for the [ServerConfigurationRoute] that manages the state and owns all business logic.
class ServerConfigurationController extends State<ServerConfigurationRoute> {
  /// A [FlutterBle] instance used for Bluetooth operations conducted by this route.
  final SplendidBlePeripheral _ble = SplendidBlePeripheral();

  /// A controller for the [TextField] used to supply a name for the BLE peripheral server.
  ///
  /// The controller is initialized with a default value so that, if the user does not wish to customize the value,
  /// they are able to proceed with the server's creation more quickly.
  TextEditingController serverNameController = TextEditingController(text: 'Splendid BLE Server');

  /// A controller for the [TextField] used to supply the primary service UUID for the BLE peripheral server.
  ///
  /// The controller is initialized with a default value, which is a random UUID.
  TextEditingController primaryServiceController = TextEditingController(text: _generateRandomUUID());

  /// A controller for the [TextField] used to supply a list of characteristic UUIDs for the BLE peripheral server.
  ///
  /// The controller is initialized with a default value, which is a list with a single random UUID.
  TextEditingController characteristicsController = TextEditingController(text: _generateRandomUUID());

  /// Determines if the server is currently being created.
  bool _creatingServer = false;

  bool get creatingServer => _creatingServer;

  /// Handles taps on the [AppBar] close button.
  void onClose() {
    Navigator.pushReplacement<void, void>(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const HomeRoute(),
      ),
    );
  }

  /// Generates a random UUID (Universally Unique Identifier).
  ///
  /// This function utilizes the `uuid` package to generate a version 4 (random) UUID. The UUID generated is in the
  /// standard format, for example: '12345678-1234-1234-1234-123456789abc'.
  ///
  /// Returns:
  ///   A `String` representing the random UUID.
  static String _generateRandomUUID() {
    var uuid = Uuid();

    return uuid.v4();
  }

  /// Handles taps on the "create" button, which starts the process of creating a BLE peripheral server based on the
  /// configuration parameters provided in the table for this route.
  Future<void> onCreateTap() async {
    setState(() {
      _creatingServer = true;
    });

    // Create a BleServerConfiguration object from the information provided in the fields in the table for this view.
    BleServerConfiguration configuration = BleServerConfiguration(
      primaryServiceUuid: primaryServiceController.text,
    );

    // Create the BLE peripheral server
    BleServer server;
    try {
      server = await _ble.createPeripheralServer(configuration);

      debugPrint('Successfully created BLE server');
    } catch (e) {
      debugPrint('Failed to create BLE peripheral server with exception, $e');

      return;
    }

    setState(() {
      _creatingServer = false;
    });

    Navigator.pushReplacement<void, void>(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) => ServerInteractionRoute(
          server: server,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ServerConfigurationView(this);
}
