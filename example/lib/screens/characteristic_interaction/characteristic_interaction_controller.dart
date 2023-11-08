import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_splendid_ble/models/ble_characteristic_value.dart';

import 'characteristic_interaction_route.dart';
import 'characteristic_interaction_view.dart';
import 'models/message.dart';
import 'models/message_source.dart';

/// A controller for the [CharacteristicInteractionRoute] that manages the state and owns all business logic.
class CharacteristicInteractionController extends State<CharacteristicInteractionRoute> {
  /// A list of "messages" sent between the host mobile device and a Bluetooth peripheral, in either direction.
  List<Message> messages = [];

  /// A controller for the text field used to input commands to be sent to the Bluetooth peripheral.
  final TextEditingController controller = TextEditingController();

  /// A [StreamSubscription] used to listen for changes in the value of the characteristic.
  StreamSubscription<BleCharacteristicValue>? characteristicValueListener;

  @override
  void initState() {
    super.initState();

    // Set a lister for changes in the characteristic value
    characteristicValueListener = widget.characteristic.subscribe().listen(
          (event) => onCharacteristicChanged(event),
        );
  }

  /// A callback invoked when the value of the Bluetooth characteristic changes.
  void onCharacteristicChanged(BleCharacteristicValue event) {
    // Convert the List<int> from the Bluetooth device to a String
    String eventContent;
    try {
      eventContent = utf8.decode(event.value);
    } catch (e) {
      debugPrint('Failed to decode event value with exception, $e');
      // TODO show SnackBar or something
      return;
    }

    // Create a Message instance for the new event
    Message newMessage = Message(contents: eventContent, source: MessageSource.peripheral);

    // Add the new message to the list
    setState(() {
      messages.add(newMessage);
    });
  }

  /// Handles submission of entries into the text field used to input values to be sent to the Bluetooth peripheral.
  ///
  /// First, this method will attempt to write the string provided in the [TextField] to the Bluetooth characteristic
  /// provided to this route. If that write fails, a [SnackBar] will be displayed alerting the user of the failure. If
  /// it is successful, the message will be added to [messages] so that it will be displayed in the list, and the
  /// [TextField] will be cleared.
  Future<void> onEntrySubmitted() async {
    try {
      await widget.characteristic.writeValue(
        value: controller.text,
      );

      setState(() {
        messages.add(
          Message(contents: controller.text, source: MessageSource.mobile),
        );
        controller.text = '';
      });
    } catch (e) {
      debugPrint('Writing to characteristic, ${widget.characteristic.uuid}, failed with exception, $e');

      _showWriteError();
    }
  }

  /// Shows a [SnackBar] explaining that a Bluetooth write operation has failed.
  void _showWriteError() {
    if (!mounted) return;
    SnackBar snackBar = SnackBar(
      content: Text(AppLocalizations.of(context)!.errorWriting),
      duration: const Duration(seconds: 8),
      behavior: SnackBarBehavior.floating,
    );

    // Find the ScaffoldMessenger in the widget tree
    // and use it to show a SnackBar.
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) => CharacteristicInteractionView(this);

  @override
  void dispose() {
    // When this controller is disposed, make sure that the listener is cleaned up
    widget.characteristic.unsubscribe();
    characteristicValueListener?.cancel();

    super.dispose();
  }
}
