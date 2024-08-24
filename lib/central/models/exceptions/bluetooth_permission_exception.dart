/// `BluetoothPermissionException` is a custom exception type that signifies an error related to
/// Bluetooth permissions. It is thrown when an operation that requires specific Bluetooth permissions
/// is attempted without those permissions being granted by the user or being available on the device.
///
/// This exception is typically used in the context of Bluetooth operations where access to the
/// Bluetooth hardware or the ability to perform certain actions is restricted by the operating system's
/// permission model. For instance, this exception may be thrown during Bluetooth scanning, connection,
/// or data transfer operations that fail due to missing permissions.
///
/// The exception carries a [message] that typically contains a description of the permission issue,
/// potentially including specifics about which permissions are missing and any other relevant details
/// provided by the platform-specific error handling.
///
/// ## Example
///
/// ```dart
/// try {
///   // Attempt a Bluetooth operation that requires permissions
/// } on BluetoothPermissionException catch (e) {
///   // Handle the exception, possibly by prompting the user to grant permissions
///   print(e);
/// }
/// ```
class BluetoothPermissionException implements Exception {
  /// A message describing the error related to Bluetooth permissions.
  final String message;

  /// Creates a [BluetoothPermissionException] with the specified error [message].
  BluetoothPermissionException(this.message);

  @override
  String toString() => 'BluetoothPermissionException: $message';
}
