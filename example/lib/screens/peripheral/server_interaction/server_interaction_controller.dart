import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_splendid_ble/shared/models/ble_device.dart';
import 'package:flutter_splendid_ble_example/screens/peripheral/server_interaction/server_interaction_route.dart';
import 'package:flutter_splendid_ble_example/screens/peripheral/server_interaction/server_interaction_view.dart';

import '../../home/home_route.dart';
import '../../models/message.dart';

/// A controller for the [ServerInteractionRoute] that manages the state and owns all business logic.
class ServerInteractionController extends State<ServerInteractionRoute> {
  /// Determines if the BLE server is currently advertising.
  bool isAdvertising = false;

  /// A list of "messages" sent between the host mobile device and a Bluetooth peripheral, in either direction.
  List<Message> messages = [];

  /// A controller for the text field used to input commands to be sent to the Bluetooth peripheral.
  final TextEditingController controller = TextEditingController();

  /// A [StreamSubscription] used to listen for clients connecting to the BLE server.
  late StreamSubscription<BleDevice> _clientConnectionStreamController;

  /// Determines if a client is currently connected to the BLE server.
  bool hasClient = false;

  @override
  void initState() {
    // Set up a listener for a client device connecting to the server.
    _clientConnectionStreamController = widget.server.emitClientConnections().listen(_onClientConnected);

    super.initState();
  }

  /// Handles changes in the state of the switch that controls advertising.
  ///
  /// When the switch is toggled, this method will either start or stop advertising the BLE server.
  Future<void> onAdvertisingSwitchChanged(bool value) async {
    // The switch was turned on.
    if (value) {
      try {
        await widget.server.startAdvertising();
      } catch (e) {
        debugPrint('Failed to start advertising with exception, $e');
      }

      debugPrint('Started advertising with server name, "${widget.server.configuration.localName}"');
    }
    // The switch was turned off.
    else {
      try {
        await widget.server.stopAdvertising();
      } catch (e) {
        debugPrint('Failed to stop advertising with exception, $e');
      }

      debugPrint('Stopped advertising');
    }

    if (!mounted) return;
    setState(() {
      isAdvertising = value;
    });
  }

  /// Handles the event of a client connecting to the BLE server.
  void _onClientConnected(BleDevice client) {
    debugPrint('Client, ${client.name}, connected');

    // Stop advertising when a client connects.
    onAdvertisingSwitchChanged(false);

    if (!mounted) return;
    setState(() {
      hasClient = true;
    });
  }

  // TODO (Toglefritz): document
  Future<void> onEntrySubmitted() async {
    // If there is no client connected, show a SnackBar indicating such
    if(!hasClient) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No client connected'),
        ),
      );

      return;
    }
    // If there is a client connected, send the message to the client
    else {
      // TODO(Toglefritz): implement
    }
  }

  /// Handles taps on the [AppBar] close button.
  Future<void> onClose() async {
    await widget.server.stopAdvertising();

    // TODO (Toglefritz): dispose of the server

    if (!mounted) return;
    Navigator.pushReplacement<void, void>(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const HomeRoute(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ServerInteractionView(this);

  @override
  void dispose() {
    // Cancel the client connection stream subscription.
    _clientConnectionStreamController.cancel();

    super.dispose();
  }
}
