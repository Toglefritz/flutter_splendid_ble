/// `BluetoothSubscriptionException` is a custom exception that is thrown when an error occurs
/// while attempting to subscribe to notifications or indications from a Bluetooth Low Energy (BLE)
/// characteristic. This type of exception is particularly useful for handling the intricacies of
/// BLE communication where setting up notifications or indications can fail due to a range of issues,
/// such as connection instability, incorrect characteristic properties, insufficient permissions, or
/// unsupported operations by the BLE peripheral.
///
/// The [message] field is intended to provide a more detailed description of the error, often
/// including specific error codes or additional context provided by the BLE framework or the
/// underlying platform.
///
/// ## Example
///
/// ```dart
/// try {
///   // Code to subscribe to a BLE characteristic for notifications or indications
/// } on BluetoothSubscriptionException catch (e) {
///   // Handle the exception by possibly retrying or notifying the user
///   print(e);
/// }
/// ```
class BluetoothSubscriptionException implements Exception {
  /// A message describing the error that occurred during the subscription process.
  final String message;

  /// Creates a [BluetoothSubscriptionException] with the specified error [message].
  BluetoothSubscriptionException(this.message);

  @override
  String toString() => 'BluetoothSubscriptionException: $message';
}
