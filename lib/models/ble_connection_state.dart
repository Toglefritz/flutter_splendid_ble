/// Enumeration representing the possible connection states between a Bluetooth peripheral and the host platform.
///
/// * [connected]: The Bluetooth peripheral is successfully connected.
/// * [disconnected]: The Bluetooth peripheral is disconnected from the host device.
/// * [connecting]: A connection between the peripheral and the host device is in the process of being established.
/// * [disconnecting]: The peripheral and the host device are in the process of disconnecting.
/// * [unknown]: The connection, or lack thereof, between the peripheral and the host device is in an unknown state.
enum BleConnectionState {
  connected('connected'),
  disconnected('disconnected'),
  connecting('connecting'),
  disconnecting('disconnecting'),
  unknown('unknown');

  /// A String identifier for each [BleConnectionState] value.
  final String identifier;

  const BleConnectionState(this.identifier);
}