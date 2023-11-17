import 'dart:convert';

/// Represents the value of a Bluetooth characteristic.
///
/// This class encapsulates the value of a specific Bluetooth characteristic fetched from a connected device. The
/// value is typically a list of integers, representing bytes of data from the characteristic.
///
/// Along with the value, the class provides details about the characteristic's UUID and the Bluetooth device's
/// address from which the value was read.
///
/// Instances of this class can be used to easily manage, display, or process the characteristic values in your
/// application.
///
/// Example:
/// ```dart
/// BleCharacteristicValue charValue = await readCharacteristic(address, characteristicUuid, timeout);
/// print(charValue.characteristicUuid);  // prints UUID of the characteristic
/// print(charValue.deviceAddress);       // prints address of the device
/// print(charValue.value);               // prints the actual value of the characteristic
/// ```
class BleCharacteristicValue {
  /// The UUID of the Bluetooth characteristic.
  ///
  /// This UUID uniquely identifies the characteristic from which the value has been read. It can be used to
  /// differentiate values if you're working with multiple characteristics.
  final String characteristicUuid;

  /// The MAC address of the Bluetooth device.
  ///
  /// This address uniquely identifies the Bluetooth device from which the value was read. This is especially
  /// useful if your application is communicating with multiple devices simultaneously.
  final String deviceAddress;

  /// The actual value of the characteristic.
  ///
  /// This is a list of integers, where each integer represents a byte of data rom the characteristic. The structure
  /// and meaning of this data is typically defined by the Bluetooth service specification to which the characteristic
  /// belongs.
  final List<int> value;

  /// Returns the [value] converted into a String by treating the `List<int>` as a UTF-8 encoded string. This string
  /// value may, depending upon your application and the firmware running on the Bluetooth device, be further
  /// deserialized as a JSON or Protobuf object.
  String get valueString => utf8.decode(value);

  /// Constructs a new instance of [BleCharacteristicValue].
  ///
  /// Requires the [characteristicUuid], [deviceAddress], and [value] to initialize the instance. Each of these
  /// parameters should be fetched from the connected Bluetooth device when reading the characteristic.
  BleCharacteristicValue({
    required this.characteristicUuid,
    required this.deviceAddress,
    required this.value,
  });

  /// Factory constructor that creates an instance of [BleCharacteristicValue] from a map. This is typically used to
  /// convert data coming from the platform side using methods provided by the *flutter_splendid_ble* plugin.
  ///
  /// The map is expected to have the keys 'characteristicUuid', 'deviceAddress',
  /// and 'value'.
  ///
  /// Example:
  /// ```dart
  /// final mapData = {
  ///   'characteristicUuid': 'some-uuid',
  ///   'deviceAddress': '00:1A:7D:DA:71:11',
  ///   'value': [10, 20, 30],
  /// };
  /// final charValue = BleCharacteristicValue.fromMap(mapData);
  /// print(charValue.characteristicUuid);  // prints 'some-uuid'
  /// ```
  factory BleCharacteristicValue.fromMap(Map<dynamic, dynamic> map) {
    try {
      return BleCharacteristicValue(
        characteristicUuid: map['characteristicUuid'] as String,
        deviceAddress: map['deviceAddress'] as String,
        value: (map['value'] as List).map((e) => e as int).toList(),
      );
    } catch (e) {
      throw FormatException(
          'Failed to construct BleCharacteristicValue from Map, $map, with exception, $e');
    }
  }
}
