/// `BluetoothWriteException` is a custom exception type that indicates an error occurred during
/// the process of writing values to a Bluetooth Low Energy (BLE) characteristic. It is thrown when
/// the BLE operation to write data to a characteristic fails due to various reasons such as
/// Bluetooth connection issues, the characteristic not being writable, or the device not being
/// properly connected or paired.
///
/// This exception provides a mechanism to handle write failures gracefully in the application logic,
/// allowing developers to provide feedback to the user or to attempt recovery actions. The [message]
/// field typically includes a detailed description of the error, possibly containing error codes or
/// additional information provided by the BLE stack or the underlying platform.
///
/// ## Example
///
/// ```dart
/// try {
///   // Attempt to write to a BLE characteristic
/// } on BluetoothWriteException catch (e) {
///   // Handle the exception by informing the user or attempting a retry
///   print(e);
/// }
/// ```
class BluetoothWriteException implements Exception {
  /// A message describing the error that occurred during the write operation.
  final String message;

  /// Creates a [BluetoothWriteException] with the specified error [message].
  BluetoothWriteException(this.message);

  @override
  String toString() => 'BluetoothWriteException: $message';
}
