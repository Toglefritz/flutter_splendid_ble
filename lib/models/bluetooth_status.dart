/// Enumeration representing the possible statuses of the Bluetooth adapter on the Android platform.
///
/// * [enabled]: The Bluetooth adapter is turned on, and the device can connect to other Bluetooth devices.
/// * [disabled]: The Bluetooth adapter is turned off, and the device cannot connect to other Bluetooth devices.
/// * [notAvailable]: The device does not support Bluetooth functionality.
enum BluetoothStatus {
  enabled('enabled'),
  disabled('disabled'),
  notAvailable('notAvailable');

  /// A String identifier for each [BluetoothStatus] value.
  final String identifier;

  const BluetoothStatus(this.identifier);
}
