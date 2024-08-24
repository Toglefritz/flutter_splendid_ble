import 'bluetooth_status.dart';

/// Enumeration representing the possible statuses of a request for Bluetooth permissions.
///
/// * [granted]: The user has granted the application permission to use Bluetooth functionality on their device.
/// * [denied]: The user has denied the application permission to use Bluetooth functionality.
/// * [unknown]: The result of a request for permissions is unknown.
enum BluetoothPermissionStatus {
  /// The user has granted the application permission to use Bluetooth functionality on their device.
  granted('granted'),

  /// The user has denied the application permission to use Bluetooth functionality.
  denied('denied'),

  /// The result of a request for permissions is unknown.
  unknown('unknown');

  /// A String identifier for each [BluetoothStatus] value.
  final String identifier;

  const BluetoothPermissionStatus(this.identifier);
}
