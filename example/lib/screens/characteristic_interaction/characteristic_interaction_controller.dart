import 'package:flutter/material.dart';
import 'package:flutter_ble/flutter_ble.dart';
import 'package:flutter_ble_example/screens/characteristic_interaction/models/message_source.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'characteristic_interaction_route.dart';
import 'characteristic_interaction_view.dart';
import 'models/message.dart';

/// A controller for the [CharacteristicInteractionRoute] that manages the state and owns all business logic.
class CharacteristicInteractionController extends State<CharacteristicInteractionRoute> {
  /// A [FlutterBle] instance used for Bluetooth operations conducted by this route.
  final FlutterBle _ble = FlutterBle();

  /// A list of "messages" sent between the host mobile device and a Bluetooth peripheral, in either direction.
  List<Message> messages = [];

  /// A controller for the text field used to input commands to be sent to the Bluetooth peripheral.
  final TextEditingController controller = TextEditingController();

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

  /// Handles submission of entries into the text field used to input values to be sent to the Bluetooth peripheral.
  ///
  /// First, this method will attempt to write the string provided in the [TextField] to the Bluetooth characteristic
  /// provided to this route. If that write fails, a [SnackBar] will be displayed alerting the user of the failure. If
  /// it is successful, the message will be added to [messages] so thjat it will be displayed in the list, and the
  /// [TextField] will be cleared.
  Future<void> onEntrySubmitted() async {
    try {
      await _ble.writeCharacteristic(
        address: widget.device.address,
        characteristicUuid: widget.characteristic.uuid,
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

  @override
  Widget build(BuildContext context) => CharacteristicInteractionView(this);
}
