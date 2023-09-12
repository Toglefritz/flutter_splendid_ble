/// An enumeration of entities that are able to source messages while Bluetooth communication
/// is taking place between a mobile device and a Bluetooth peripheral.
enum MessageSource {
  /// The message originated with the host mobile device and was sent to a Bluetooth peripheral.
  mobile,

  /// The message originated with the Bluetooth peripheral and was read by the mobile device from one
  /// of the peripheral's Bluetooth characteristics.
  peripheral,
}