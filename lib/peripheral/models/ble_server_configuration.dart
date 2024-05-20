/// Represents the configuration for a Bluetooth Low Energy (BLE) server.
///
/// This class encapsulates all the necessary parameters required to set up a BLE server on a device and to advertise
/// information about this BLE server to nearby central devices. This class provides a structured way to pass server
/// configuration details from the Dart side of a Flutter application to the native platform side.
///
/// Parameters:
/// - [serviceUuids]: A list of strings, each representing a UUID for services provided by the BLE server.
class BleServerConfiguration {
  /// The local name of the BLE device.
  ///
  /// This name is advertised to other devices and can be used for identification purposes. If null, the device may be
  /// advertised with a default name or no name, depending on the platform's behavior.
  final String? localName;

  /// The UUID of the primary service provided by this BLE server.
  ///
  /// In the context of Bluetooth Low Energy (BLE) communication, the primary service UUID is a unique identifier
  /// for the main service that a BLE peripheral provides. This service is what central devices (like smartphones or
  /// tablets) look for when scanning for BLE devices. The primary service should be a universally unique identifier
  /// (UUID) that distinctly represents the main functionality or the primary purpose of the BLE peripheral.
  ///
  /// For instance, if the BLE server is designed to measure temperature, the primary service UUID could represent
  /// a "Temperature Measurement Service." This UUID is crucial for BLE central devices to recognize the service's
  /// purpose and interact with it accordingly.
  final String primaryServiceUuid;

  /// This field specifies a list of UUIDs for the services that the BLE peripheral server will offer. Each UUID
  /// represents a unique service provided by the server, defining the types of operations and data the server can
  /// handle.
  ///
  /// UUIDs are crucial for BLE communication as they enable client devices to identify and interact with the specific
  /// services offered by the server. They must be unique and conform to the UUID format defined by the Bluetooth
  /// specification.
  ///
  /// The provided UUIDs should be carefully selected to match the services your server intends to provide, and must be
  /// unique to avoid conflicts with other services. The [primaryServiceUuid] will be automatically included in this
  /// list, so it does not need to be repeated here.
  ///
  /// If null, the [primaryServiceUuid], which is required, will correspond with the only service offered by the BLE
  /// peripheral server.
  final List<String>? serviceUuids;

  // TODO add other fields

  /// Constructs a new instance of [BleServerConfiguration].
  ///
  /// The [localName] parameter specifies the local name of the BLE device.
  /// The [primaryServiceUuid] parameter specifies the UUID of the primary service provided by this BLE server.
  /// The [serviceUuids] parameter specifies a list of UUIDs for the services that the BLE peripheral server will offer.
  ///
  /// If [serviceUuids] is not null and does not contain [primaryServiceUuid], [primaryServiceUuid] is inserted at the first position of [serviceUuids].
  /// If [serviceUuids] is null, it is set to a list containing just the [primaryServiceUuid].
  BleServerConfiguration({
    required this.localName,
    required this.primaryServiceUuid,
    List<String>? serviceUuids,
  }) : this.serviceUuids = serviceUuids ?? [primaryServiceUuid] {
    // If serviceUuids is not null and does not contain primaryServiceUuid, insert it at the first position
    if (this.serviceUuids != null && !this.serviceUuids!.contains(primaryServiceUuid)) {
      this.serviceUuids!.insert(0, primaryServiceUuid);
    }
  }

  /// Returns a [Map] to represent a [BleServerConfiguration] instance. This is used to communicate the information
  /// contained within the [BleServerConfiguration] to the platform side while making method channel calls.
  Map<String, dynamic> toMap() {
    return {
      'localName': localName,
      'primaryServiceUuid': primaryServiceUuid,
      'serviceUuids': serviceUuids ?? [],
      // Map other fields as well
    };
  }
}

