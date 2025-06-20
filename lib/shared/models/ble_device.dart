import 'manufacturer_data.dart';

/// Represents a discovered BLE device.
class BleDevice {
  /// The name of the device.
  ///
  /// Bluetooth devices are not required to provide a name so this String is nullable.
  final String? name;

  /// The Bluetooth address of the device.
  final String address;

  /// The RSSI (Received Signal Strength Indicator) value for the device.
  final int rssi;

  /// The manufacturer data associated with the device.
  ///
  /// Bluetooth devices are not required to provide manufacturer data so this field is nullable.
  final ManufacturerData? manufacturerData;

  /// Creates an instance of [BleDevice].
  BleDevice({
    required this.name,
    required this.address,
    required this.rssi,
    required this.manufacturerData,
  });

  /// Converts a Map to a [BleDevice] object.
  ///
  /// The [map], which contains information about the discovered Bluetooth device, comes from the plugin's method
  /// channel. Therefore, the type annotation is <dynamic, dynamic>.
  factory BleDevice.fromMap(Map<dynamic, dynamic> map) {
    // Parse the manufacturer data from the string if it exists.
    final String? manufacturerDataString = map['manufacturerData'] as String?;
    ManufacturerData? manufacturerData;
    if (manufacturerDataString != null && manufacturerDataString.isNotEmpty) {
      manufacturerData = ManufacturerData.fromString(manufacturerDataString);
    }

    return BleDevice(
      name: map['name'] as String?,
      address: map['address'] as String,
      rssi: map['rssi'] as int,
      manufacturerData: manufacturerData,
    );
  }
}
