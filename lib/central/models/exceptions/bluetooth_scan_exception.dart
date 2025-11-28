/// A custom exception for handling Bluetooth scan errors.
///
/// This exception is thrown when an error occurs during a Bluetooth scan operation, such as starting or stopping a
/// scan. It provides a unified error handling mechanism across the Bluetooth functionality of an application.
///
/// The exception includes a message that describes the error, which can be used to inform the user about what went
/// wrong. The message is intended to be sufficiently descriptive for debugging purposes but should be sanitized before
/// being displayed in a user interface.
///
/// ## Throwing this Exception
/// This exception should be thrown by methods in the Bluetooth handling classes when they encounter a condition that
/// they cannot recover from and that is related to the scanning process. It encapsulates errors that are specific to
/// Bluetooth scan operations.
///
/// Example of throwing a `BluetoothScanException`:
/// ```dart
/// if (someErrorCondition) {
/// throw BluetoothScanException('Failed to start the Bluetooth scan.');
/// }
/// ```
///
/// ## Handling this Exception
/// Callers of methods that can throw a [BluetoothScanException] should be prepared to catch and handle it. The handling
/// could involve logging the error for debugging purposes, informing the user of the failure, and potentially retrying
/// the operation or offering alternative options to the user.
///
/// Example of catching a [BluetoothScanException]:
/// ```dart
/// try {
/// await bluetoothService.startScan();
/// } on BluetoothScanException catch (e) {
/// _handleBluetoothScanError(e);
/// }
/// ```
///
/// Here, `_handleBluetoothScanError` could be a method that takes the exception and performs appropriate error
/// handling.
class BluetoothScanException implements Exception {
  /// A message describing the error that occurred during the scan operation.
  final String message;

  /// Creates a [BluetoothScanException] with the specified error [message].
  BluetoothScanException(this.message);

  @override
  String toString() => 'BluetoothScanException: $message';
}
