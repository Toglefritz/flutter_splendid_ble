import 'package:flutter/material.dart';
import 'package:flutter_splendid_ble/central/models/ble_characteristic.dart';
import 'package:flutter_splendid_ble/central/models/ble_characteristic_property.dart';
import 'package:flutter_splendid_ble/central/models/ble_characteristic_value.dart';

/// Displays information about an individual Bluetooth characteristic.
class CharacteristicInfo extends StatefulWidget {
  /// Creates an instance of [CharacteristicInfo].
  const CharacteristicInfo({
    required this.characteristic,
    required this.characteristicOnTap,
    super.key,
  });

  /// A Bluetooth characteristic detailed by this widget.
  final BleCharacteristic characteristic;

  /// A callback invoked when a characteristic is tapped.
  final void Function(BleCharacteristic) characteristicOnTap;

  @override
  State<CharacteristicInfo> createState() => _CharacteristicInfoState();
}

class _CharacteristicInfoState extends State<CharacteristicInfo> {
  /// The value of the `widget.characteristic`.
  BleCharacteristicValue? _characteristicValue;

  /// Reads the value of the provided Bluetooth characteristic and returns the value as a String.
  ///
  /// If reading the characteristic value is successful, this function returns the characteristic value as a
  /// [BleCharacteristicValue].
  Future<void> _readCharacteristicValue(
    BleCharacteristic characteristic,
  ) async {
    try {
      final BleCharacteristicValue characteristicValue =
          await characteristic.readValue<BleCharacteristicValue>();

      setState(() {
        _characteristicValue = characteristicValue;
      });
    } catch (e) {
      debugPrint('Failed to read characteristic value with exception, $e');

      // TODO(Toglefritz): show SnackBar?
    }
  }

  /// Converts a list of Bluetooth characteristic properties into a string format that is easier to read in the UI.
  String _getPropertiesLabel(List<BleCharacteristicProperty> properties) {
    return properties
        .toString()
        .replaceAll('BleCharacteristicProperty.', '')
        .replaceAll('[', '')
        .replaceAll(']', '')
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => widget.characteristicOnTap(widget.characteristic),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'UUID: ${widget.characteristic.uuid}',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              Text(
                'Properties: ${_getPropertiesLabel(widget.characteristic.properties)}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              if (_characteristicValue != null)
                RichText(
                  text: TextSpan(
                    text: 'Value: ',
                    style: Theme.of(context).textTheme.labelSmall,
                    children: <TextSpan>[
                      TextSpan(
                        text: _characteristicValue?.valueString,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (widget.characteristic.properties
              .contains(BleCharacteristicProperty.read))
            InkWell(
              onTap: () => _readCharacteristicValue(widget.characteristic),
              child: Icon(
                Icons.download_outlined,
                color: Theme.of(context).primaryColor.withValues(alpha: 0.8),
              ),
            ),
        ],
      ),
    );
  }
}
