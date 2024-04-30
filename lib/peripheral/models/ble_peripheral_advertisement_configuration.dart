/// Represents the configuration for Bluetooth Low Energy (BLE) peripheral advertisement.
///
/// This class allows a Flutter app to configure the advertisement information when acting as a BLE peripheral device.
/// The advertisement information includes the local name of the device, a list of service UUIDs, and manufacturer-specific data.
class BlePeripheralAdvertisementConfiguration {
  /// The local name of the BLE device.
  ///
  /// This name is advertised to other devices and can be used for identification purposes. If null, the device may be
  /// advertised with a default name or no name, depending on the platform's behavior.
  final String? localName;

  /// A list of service UUIDs to be included in the advertisement.
  ///
  /// These UUIDs represent the BLE services that the peripheral device offers. It helps central devices to identify
  /// the type of services available before establishing a connection. If no service UUIDs are provided, the
  /// advertisement will not include service UUID information. However, note that the BLE peripheral device will
  /// still have at least one primary service UUID. When [serviceUuids] is empty, service UUIDs will not be included
  /// in the advertisement data, meaning that, for central devices, filters by service UUIDs would not apply to this
  /// device.
  final List<String> serviceUuids;


  /// Manufacturer-specific data to be included in the advertisement.
  ///
  /// This is a map where the key is an integer representing the manufacturer ID and the value is a list of integers
  /// representing the manufacturer-specific data. This data can be used for custom purposes, like identifying the
  /// device model or firmware version. A central device designed to interact with the BLE peripheral device
  /// created with this [manufacturerData] would need to be configured to interpret this data.
  final Map<int, List<int>> manufacturerData;


  /// Constructs a [BlePeripheralAdvertisementConfiguration] with the given settings.
  ///
  /// [localName] is the name that will appear when other devices scan for this device.
  /// [serviceUuids] is a list of service UUIDs that this device advertises.
  /// [manufacturerData] is a map of manufacturer-specific data that will be included in the advertisement.
  BlePeripheralAdvertisementConfiguration({
    this.localName,
    this.serviceUuids = const [], // Defaults to an empty list
    this.manufacturerData = const {}, // Defaults to an empty map
  });

  /// Converts the [BlePeripheralAdvertisementConfiguration] instance to a map.
  ///
  /// This method is useful for passing the configuration to platform-specific code that requires advertisement data
  /// in a map format.
  ///
  /// Returns a map containing the local name, service UUIDs, and manufacturer data of the BLE peripheral advertisement
  /// configuration.
  Map<String, dynamic> toMap() {
    return {
      'localName': localName,
      'serviceUuids': serviceUuids,
      'manufacturerData': manufacturerData,
    };
  }
}