import 'dart:typed_data';

/// Represents manufacturer data from a BLE device.
///
/// Manufacturer data is a specific type of data that can be included in the advertisement packets sent by Bluetooth Low
/// Energy (BLE) devices. This data is used to provide additional information about the device, which can be useful for
/// identifying the device or understanding its capabilities.
///
/// The manufacturer data is divided into two main parts:
///
/// 1. **Manufacturer Identifier**: The first two bytes of the manufacturer data represent the
/// identifier of the manufacturer of the device or the Bluetooth radio. This identifier is assigned by the Bluetooth
/// Special Interest Group (SIG) and is unique to each manufacturer. It helps in identifying the manufacturer of the BLE
/// device.
///
/// 2. **Manufacturer-Specific Payload**: The remaining bytes of the manufacturer data are available
/// for the BLE device firmware to use according to the designer's purposes. This payload can contain any data that the
/// device wants to advertise, such as sensor readings, device status, or other custom information. Interpreting this
/// data generally requires documentation or some other reference about the firmware implementation, as it is specific
/// to the device and its manufacturer.
///
/// This class encapsulates the manufacturer data and provides a structure for handling it within the application.
class ManufacturerData {
  /// The manufacturer identifier of the device.
  final List<int> manufacturerId;

  /// The manufacturer-specific payload of the device.
  final List<int> payload;

  /// Creates an instance of [ManufacturerData].
  ManufacturerData({
    required this.manufacturerId,
    required this.payload,
  });

  /// Creates an instance of [ManufacturerData] from the provided string. In the provided string, the first two bytes
  /// represent the manufacturer identifier, and the remaining bytes represent the manufacturer-specific payload.
  ///
  /// This factory constructor is used with data returned from the native side in response to Method Channel calls.
  factory ManufacturerData.fromString(String manufacturerData) {
    // If the manufacturer data is empty, return an empty ManufacturerData instance.
    if (manufacturerData.isEmpty) {
      return ManufacturerData(manufacturerId: [], payload: []);
    }

    // Convert the manufacturer data string to a list of integers.
    final Uint8List manufacturerDataInts = Uint8List.fromList(
      List<int>.generate(
        manufacturerData.length ~/ 2,
        (i) =>
            int.parse(manufacturerData.substring(i * 2, i * 2 + 2), radix: 16),
      ),
    );

    // Extract the manufacturer identifier and the payload.
    final Uint8List manufacturerId =
        Uint8List.sublistView(manufacturerDataInts, 0, 2);
    final Uint8List payload = Uint8List.sublistView(manufacturerDataInts, 2);

    return ManufacturerData(
      manufacturerId: manufacturerId,
      payload: payload,
    );
  }

  /// Converts the manufacturer data to a string.
  @override
  String toString() {
    final List<int> manufacturerDataInts = [...manufacturerId, ...payload];
    return String.fromCharCodes(manufacturerDataInts);
  }

  /// Converts the manufacturer data to a string that is formatted for easy reading. The manufacturer identifier is
  /// surrounded by angle brackets to make its separation from the rest of the data more clear. A space is included
  /// after every fourth character to separate the manufacturer data into chunks of four characters.
  ///
  /// The end result of this formatting is a value that looks similar to the format used by the nRF Connect for Mobile
  /// app.
  String toFormattedString() {
    // Create a string representing the manufacturer identifier, surrounded by
    //angle brackets.
    final StringBuffer formattedString = StringBuffer('<');
    for (int i = 0; i < manufacturerId.length; i++) {
      formattedString
          .write(manufacturerId[i].toRadixString(16).padLeft(2, '0'));
    }
    formattedString.write('> ');

    // Create a string representing the payload, with spaces after every fourth
    // character.
    for (int i = 0; i < payload.length; i++) {
      formattedString.write(payload[i].toRadixString(16).padLeft(2, '0'));
      if ((i + 1).isEven) {
        formattedString.write(' ');
      }
    }

    return formattedString.toString().toUpperCase();
  }
}
