import 'ble_characteristic.dart';

/// Represents a Bluetooth Low Energy (BLE) service.
///
/// In the BLE protocol, services encapsulate one or more characteristics that
/// contain data provided by the peripheral device. Each service has a universally
/// unique identifier (UUID) and contains a collection of [BleCharacteristic]
/// instances which detail the properties and permissions of each characteristic.
class BleService {
  /// The universally unique identifier (UUID) for the service.
  final String serviceUuid;

  /// A list of [BleCharacteristic] objects that belong to this service.
  ///
  /// Each [BleCharacteristic] encapsulates the UUID, properties, and permissions
  /// of a particular characteristic within this service.
  final List<BleCharacteristic> characteristics;

  /// Creates a [BleService] instance.
  ///
  /// Requires [serviceUuid] and a list of [characteristics] to initialize.
  BleService({
    required this.serviceUuid,
    required this.characteristics,
  });

  /// Constructs a [BleService] from a map.
  ///
  /// The map should contain a 'serviceUuid' key for the UUID of the service and a
  /// 'characteristics' key containing a list of maps, each of which can be used
  /// to initialize a [BleCharacteristic] instance.
  factory BleService.fromMap(Map<String, dynamic> map) {
    return BleService(
      serviceUuid: map['serviceUuid'] as String,
      characteristics: (map['characteristics'] as List).map((charMap) => BleCharacteristic.fromMap(charMap as Map<String, dynamic>)).toList(),
    );
  }

  /// Returns a string representation of the [BleService] instance.
  ///
  /// This includes the UUID of the service and a detailed list of its
  /// characteristics, showcasing their UUIDs, properties, and permissions.
  @override
  String toString() {
    return 'BleService(serviceUuid: $serviceUuid, characteristics: $characteristics)';
  }
}