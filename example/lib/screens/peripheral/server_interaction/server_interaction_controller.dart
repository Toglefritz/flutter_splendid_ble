import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_splendid_ble/peripheral/models/ble_peripheral_advertisement_configuration.dart';
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

  /// Handles changes in the state of the switch that controls advertising.
  ///
  /// When the switch is toggled, this method will either start or stop advertising the BLE server.
  Future<void> onAdvertisingSwitchChanged(bool value) async {
    if (value) {
      // Start advertising. The server will advertise itself as a BLE peripheral with name "Splendid BLE Example" and
      // will advertise the service UUID of the primary service.
      BlePeripheralAdvertisementConfiguration config = BlePeripheralAdvertisementConfiguration(
        localName: 'Splendid BLE Example',
        serviceUuids: [widget.server.configuration.primaryServiceUuid],
      );

      await widget.server.startAdvertising(config);
    } else {
      // Stop advertising.
      await widget.server.stopAdvertising();
    }

    if (!mounted) return;
    setState(() {
      isAdvertising = value;
    });
  }

  // TODO (Toglefritz): implement
  Future<void> onEntrySubmitted() async {
    // TODO (Toglefritz): implement
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
}
