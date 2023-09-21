import 'dart:convert';

import '../flutter_ble_platform_interface.dart';
import 'ble_characteristic_permission.dart';
import 'ble_characteristic_property.dart';
import 'ble_characteristic_value.dart';

/// Represents a Bluetooth Low Energy (BLE) characteristic.
///
/// Each characteristic in BLE has a universally unique identifier (UUID), properties that define how the value of
/// the characteristic can be accessed, and permissions that set the security requirements for accessing the value.
/// This class encapsulates these details and provides utility methods to decode properties and permissions for
/// easier understanding and interaction.
class BleCharacteristic {
  /// The Bluetooth address of the Bluetooth peripheral containing a service with this characteristic.
  final String address;

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
    required this.address,
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
      address: map['address'] as String,
      uuid: map['uuid'] as String,
      properties: BleCharacteristicProperty.fromInt(map['properties'] as int),
      permissions: BleCharacteristicPermission.fromInt(map['permissions'] as int),
    );
  }

  /// Asynchronously retrieves the value of the characteristic.
  ///
  /// This method provides a flexible way to read the characteristic's value from a BLE device
  /// and interpret it as either a raw byte list (`List<int>`) or as a UTF-8 decoded string (`String`).
  ///
  /// Generics are employed to allow the caller to specify the desired return type, either `String` or `List<int>`.
  ///
  /// If you want the value as a string:
  /// ```dart
  /// String value = await myChar.readValue<String>(address: 'device-address');
  /// ```
  ///
  /// If you need the raw bytes:
  /// ```dart
  /// List<int> bytes = await myChar.readValue<List<int>>();
  /// ```
  ///
  /// If a type other than `String` or `List<int>` is used, an `ArgumentError` is thrown.
  Future<T> readValue<T>({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    BleCharacteristicValue characteristicValue = await FlutterBlePlatform.instance.readCharacteristic(
      address: address,
      characteristicUuid: uuid,
      timeout: timeout,
    );

    if (T == String) {
      return utf8.decode(characteristicValue.value) as T;
    } else if (T == List<int>) {
      return characteristicValue.value as T;
    } else {
      throw ArgumentError('Unsupported return type $T. Supported types are String and List<int>');
    }
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
