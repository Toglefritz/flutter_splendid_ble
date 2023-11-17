/// An enumeration representing the bitwise properties of a `BluetoothGattCharacteristic`.
///
/// Each property is represented by a specific bit in an integer bitmask. These properties define the capabilities
/// and behaviors of a characteristic, such as whether a characteristic can be read, written, or notified of changes.
enum BleCharacteristicProperty {
  /// Indicates that the characteristic value can be broadcast using Server Characteristic Configuration Descriptor.
  broadcast,

  /// Indicates that the characteristic value can be read.
  read,

  /// Indicates that the characteristic value can be written without response.
  noResponse,

  /// Indicates that the characteristic value can be written.
  write,

  /// Indicates that the characteristic value can notify a connected device if the value changes.
  notify,

  /// Indicates that the characteristic value can indicate an update to a connected device.
  indicate,

  /// Indicates that the characteristic supports signed writes.
  signedWrite,

  /// Refers to the extended properties descriptor, which provides more details about a characteristic's behaviors.
  props,

  /// Indicates that the characteristic supports reliable writes, ensuring the data is properly received.
  reliableWrite,

  /// Indicates that auxiliary writable descriptors are present.
  writableAuxiliaries;

  /// Converts an integer containing bitwise representations into a list of enum values.
  ///
  /// This method interprets the bitwise properties set in the input integer and returns a list of corresponding
  /// [BleCharacteristicProperty] values. The [value] parameter is an integer bitmask representing the set properties.
  /// Returns a list of [BleCharacteristicProperty] representing the properties in the bitmask.
  static List<BleCharacteristicProperty> fromInt(int value) {
    List<BleCharacteristicProperty> propertiesList = [];

    for (BleCharacteristicProperty property
        in BleCharacteristicProperty.values) {
      if ((value & property.value) != 0) {
        propertiesList.add(property);
      }
    }
    return propertiesList;
  }
}

extension BluetoothGattCharacteristicPropertiesExtension
    on BleCharacteristicProperty {
  /// Retrieves the bitmask value corresponding to the characteristic property.
  ///
  /// Each characteristic property has a unique bitmask value. This method maps the enum value to its corresponding
  /// bitmask value.
  int get value {
    switch (this) {
      case BleCharacteristicProperty.broadcast:
        return 0x01;
      case BleCharacteristicProperty.read:
        return 0x02;
      case BleCharacteristicProperty.noResponse:
        return 0x04;
      case BleCharacteristicProperty.write:
        return 0x08;
      case BleCharacteristicProperty.notify:
        return 0x10;
      case BleCharacteristicProperty.indicate:
        return 0x20;
      case BleCharacteristicProperty.signedWrite:
        return 0x40;
      case BleCharacteristicProperty.props:
        return 0x80;
      case BleCharacteristicProperty.reliableWrite:
        return 0x100;
      case BleCharacteristicProperty.writableAuxiliaries:
        return 0x200;
      default:
        return 0;
    }
  }
}
