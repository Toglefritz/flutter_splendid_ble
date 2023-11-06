/// `BluetoothReadException` is a custom exception that indicates an error occurred while attempting
/// to read the value of a Bluetooth Low Energy (BLE) characteristic. This exception is thrown when
/// there is a failure in the BLE read operation, which can be due to reasons like connection issues,
/// the characteristic not being readable, lack of proper permissions, or hardware malfunctions.
///
/// The [message] field typically contains a more detailed explanation of the error, which may
/// include specific error codes or additional information from the BLE stack or the underlying
/// operating system.
///
/// ## Example
///
/// ```dart
/// try {
///   // Code to read a BLE characteristic
/// } on BluetoothReadException catch (e) {
///   // Handle the exception, such as by informing the user of the error
///   print(e);
/// }
/// ```
class BluetoothReadException implements Exception {
  final String message;

  BluetoothReadException(this.message);

  @override
  String toString() => 'BluetoothReadException: $message';
}
