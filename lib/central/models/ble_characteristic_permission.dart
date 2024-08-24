/// An enumeration representing the permissions associated with a Bluetooth Low Energy (BLE) characteristic.
///
/// Each permission corresponds to a specific type of operation that can be performed on the characteristic,
/// determining the allowed interactions with it. These permissions are a representation of Android's
/// `BluetoothGattCharacteristic` permissions.
enum BleCharacteristicPermission {
  /// Allows the characteristic value to be read.
  ///
  /// This permission indicates that the BLE characteristic value can be retrieved by a connected device.
  read,

  /// Allows the characteristic value to be read with encryption enabled.
  ///
  /// This permission ensures that the data exchanged is encrypted for security. It's a level up from the basic [read] permission.
  readEncrypted,

  /// Allows the characteristic value to be read with encryption and protection against Man-in-the-Middle (MITM) attacks.
  ///
  /// This is a higher level of security, ensuring not only encryption but also authentication, making it difficult for unauthorized devices to intercept and alter the data being exchanged.
  readEncryptedMitm,

  /// Allows the characteristic value to be written.
  ///
  /// This permission grants a connected device the ability to send and update the value of the characteristic.
  write,

  /// Allows the characteristic value to be written with encryption enabled.
  ///
  /// Like its read counterpart, this permission ensures that data being sent to update the characteristic value is encrypted.
  writeEncrypted,

  /// Allows the characteristic value to be written with encryption and protection against MITM attacks.
  ///
  /// This provides a secure mechanism for devices to send updates to the characteristic value, ensuring the data is both encrypted and authenticated.
  writeEncryptedMitm,

  /// Allows the characteristic value to be written with a signed writing method.
  ///
  /// This means the data being sent carries a signature, verifying its authenticity.
  writeSigned,

  /// Allows the characteristic value to be written with a signed method and protection against MITM attacks.
  ///
  /// This ensures that not only is the data signed for authenticity, but it is also protected against tampering and interception by unauthorized devices.
  writeSignedMitm;

  /// Convert an integer with bitwise representations to a list of enum values.
  static List<BleCharacteristicPermission> fromInt(int value) {
    final List<BleCharacteristicPermission> permissionsList = [];

    for (final BleCharacteristicPermission permission
        in BleCharacteristicPermission.values) {
      if ((value & permission.value) != 0) {
        permissionsList.add(permission);
      }
    }
    return permissionsList;
  }
}

/// Extension on [BleCharacteristicPermission] to retrieve the bitmask value for Bluetooth GATT characteristic
/// permissions.
///
/// This extension adds a property `value` to the `BleCharacteristicPermission` enum, providing a convenient way to
/// access the bitmask value of each permission. Bitmask values are essential in Bluetooth communication to
/// represent permissions in a compact, bitwise format.
extension BluetoothGattCharacteristicPermissionsExtension
    on BleCharacteristicPermission {
  /// Retrieves the bitmask value corresponding to the characteristic permission.
  ///
  /// Each characteristic permission has a unique bitmask value. This method maps the enum value to its corresponding
  /// bitmask value.
  int get value {
    switch (this) {
      case BleCharacteristicPermission.read:
        return 0x01;
      case BleCharacteristicPermission.readEncrypted:
        return 0x02;
      case BleCharacteristicPermission.readEncryptedMitm:
        return 0x04;
      case BleCharacteristicPermission.write:
        return 0x10;
      case BleCharacteristicPermission.writeEncrypted:
        return 0x20;
      case BleCharacteristicPermission.writeEncryptedMitm:
        return 0x40;
      case BleCharacteristicPermission.writeSigned:
        return 0x80;
      case BleCharacteristicPermission.writeSignedMitm:
        return 0x100;
    }
  }
}
