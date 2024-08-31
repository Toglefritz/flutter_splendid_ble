import '../../shared/models/ble_device.dart';

/// Represents a BLE device that is connected to the host device.
///
/// Because this class is used to represent devices that are already connected to the system. Their RSSI and
/// manufacturer data are not needed.
class ConnectedBleDevice extends BleDevice {
  /// Creates an instance of [ConnectedBleDevice].
  ConnectedBleDevice({
    required String super.name,
    required super.address,
  }) : super(
          rssi: 0, // The RSSI value is not needed for connected devices.
          manufacturerData: null, // The manufacturer data is not needed for connected devices.
        );

  /// Converts a Map to a [ConnectedBleDevice] object.
  ///
  /// The [map], which contains information about the connected Bluetooth device, comes from the plugin's method
  /// channel. Therefore, the type annotation is <dynamic, dynamic>.
  factory ConnectedBleDevice.fromMap(Map<dynamic, dynamic> map) {
    return ConnectedBleDevice(
      name: map['name'] as String,
      address: map['identifier'] as String,
    );
  }
}
