/// Exception for handling errors during the BLE service discovery process.
///
/// This exception is thrown when an error occurs during the process of discovering services on a Bluetooth Low Energy
/// (BLE) peripheral. The BLE service discovery process is a critical step in BLE communication, which involves querying
/// a BLE peripheral for the services it supports. An error in this process typically indicates a problem with the BLE
/// connection, the peripheral device's state, or an issue with the mobile device's BLE stack.
///
/// The `ServiceDiscoveryException` contains a [message] that provides details about the failure, which can be used for
/// debugging purposes or to inform the user about the nature of the issue.
///
/// /// ## Example Below is an example of catching and handling a `ServiceDiscoveryException`:
/// ```dart
/// try {
/// // Code to start service discovery on a BLE peripheral
/// } on ServiceDiscoveryException catch (e) {
/// // Handle the service discovery exception, possibly by alerting the user or retrying
/// print(e.message);
/// }
/// ```
class ServiceDiscoveryException implements Exception {
  /// A message describing the error that occurred during the service discovery process.
  final String message;

  /// Creates a [ServiceDiscoveryException] with the specified error [message].
  ServiceDiscoveryException(this.message);

  @override
  String toString() => 'ServiceDiscoveryException: $message';
}
