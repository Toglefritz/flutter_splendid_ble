import 'ble_characteristic_permission.dart';
import 'ble_characteristic_property.dart';

/// Represents a Bluetooth Low Energy (BLE) characteristic.
///
/// Each characteristic in BLE has a universally unique identifier (UUID),
/// properties that define how the value of the characteristic can be accessed,
/// and permissions that set the security requirements for accessing the value.
/// This class encapsulates these details and provides utility methods to
/// decode properties and permissions for easier understanding and interaction.
class BleCharacteristic {
  /// The universally unique identifier (UUID) for the characteristic.
  final String uuid;

  /// An integer value representing the properties of the characteristic that is converted into a
  /// [List<BleCharacteristicProperty>] representing the properties of the Bluetooth characteristic.
  final List<BleCharacteristicProperty> properties;

  /// An integer value representing the permissions of the characteristic that is converted into a
  /// [List<BleCharacteristicPermission>] representing the permissions of the Bluetooth characteristic.
  final List<BleCharacteristicPermission> permissions;

  /// Creates a [BleCharacteristic] instance.
  ///
  /// Requires [uuid], [properties], and [permissions] to initialize.
  BleCharacteristic({
    required this.uuid,
    required this.properties,
    required this.permissions,
  });

  /// Constructs a [BleCharacteristic] from a map.
  ///
  /// The map must contain keys 'uuid', 'properties', and 'permissions' with
  /// appropriate values.
  factory BleCharacteristic.fromMap(Map<String, dynamic> map) {
    return BleCharacteristic(
      uuid: map['uuid'] as String,
      properties: BleCharacteristicProperty.fromInt(map['properties'] as int),
      permissions: BleCharacteristicPermission.fromInt(map['permissions'] as int),
    );
  }

  /// Converts a list of [BluetoothGattCharacteristicProperties] to a string representation.
  ///
  /// Each characteristic property in the list is represented by its string name and separated by commas.
  String _propertiesListToString(List<BleCharacteristicProperty> properties) {
    return properties.map((property) => property.toString().split('.').last).join(', ');
  }

  /// Converts a list of [BleCharacteristicPermission] to a string representation.
  ///
  /// Each characteristic permission in the list is represented by its string name and separated by commas.
  String _permissionsListToString(List<BleCharacteristicPermission> permissions) {
    return permissions.map((permission) => permission.toString().split('.').last).join(', ');
  }

  /// Returns a string representation of the [BleCharacteristic] instance.
  ///
  /// This includes the UUID and the decoded properties and permissions.
  @override
  String toString() {
    return 'BleCharacteristic(uuid: $uuid, properties: ${_propertiesListToString(properties)}, permissions: ${_permissionsListToString(permissions)})';
  }
}
