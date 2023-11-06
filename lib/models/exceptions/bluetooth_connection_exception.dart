/// Exception for handling errors during the BLE peripheral connection process.
///
/// This exception is thrown when an attempt to connect to a Bluetooth Low Energy (BLE) peripheral
/// fails or encounters a problem. Establishing a connection is the first step in BLE communication,
/// which enables further interactions such as service discovery, reading, and writing
/// characteristic values.
///
/// The `BluetoothConnectionException` carries a [message] that provides more information about
/// the failure, which can be valuable for troubleshooting or informing the user about what went
/// wrong.
///
/// ## Example
/// Here's how to handle a `BluetoothConnectionException`:
/// ```dart
/// try {
///   // Attempt to connect to a BLE peripheral
/// } on BluetoothConnectionException catch (e) {
///   // Respond to the connection error, perhaps by notifying the user or attempting a reconnect
///   print(e.message);
/// }
/// ```
class BluetoothConnectionException implements Exception {
  final String message;

  BluetoothConnectionException(this.message);

  @override
  String toString() => 'BluetoothConnectionException: $message';
}
