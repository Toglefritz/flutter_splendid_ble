import '../../shared/models/ble_device.dart';

/// The `ScanFilter` class is used to define criteria that determine which Bluetooth devices are returned during a scan
/// for BLE (Bluetooth Low Energy) devices.
///
/// Scanning for BLE devices can be a resource-intensive process, especially when many devices are within range. By
/// using filters, the scanning process can be tailored to detect only devices that match certain criteria, thereby
/// making the process more efficient and focused.
///
/// The `ScanFilter` class allows for filtering based on various properties of the Bluetooth devices, such as:
///
/// - **Device Name:** The human-readable name of the device.
/// - **Device Address:** The unique hardware address of the device.
/// - **Manufacturer Data:** Custom data provided by the manufacturer of the device.
/// - **Service UUIDs:** Specific universally unique identifiers (UUIDs) for services provided by the device.
/// - **Service Data:** Data related to a specific service provided by the device.
///
/// By using one or more of these properties, the `ScanFilter` class enables applications to find and interact with only
/// those devices that are of interest. For instance, an application might use a `ScanFilter` to look only for devices
/// that provide a particular service or that have a specific name.
///
/// Example usage:
/// ```dart
/// var filter = ScanFilter(deviceName: 'DeviceName');
/// ```
class ScanFilter {
  /// The device name that should match the device's advertised name.
  final String? deviceName;

  /// The service UUIDs that should match the advertised service UUIDs.
  final List<String>? serviceUuids;

  /// The manufacturer ID associated with a specific device manufacturer.
  ///
  /// Bluetooth devices can include manufacturer-specific data in their advertisements. The manufacturer ID is generally
  /// a 16-bit identifier that corresponds to the manufacturer of the device. There is no dedicated field for including
  /// the manufacturer ID in the advertisement, but there are a few conventional methods by which manufacturers include
  /// vendor-specific data:
  ///
  /// - The most common method is to include it as the first two bytes of the Manufacturer Specific Data field
  /// (AD type 0xFF) in the advertisement payload. This field is formatted as a 16-bit company identifier assigned by
  /// the Bluetooth SIG, followed by manufacturer-defined custom data.
  ///
  /// - Some devices may embed a vendor-specific identifier within the Service Data fields (AD types 0x16 or 0x21),
  /// typically as part of a custom protocol. This is not standardized and depends on the vendor’s implementation.
  ///
  /// - Although not a direct representation of the manufacturer ID, the Bluetooth MAC address may reveal the vendor
  /// through its Organizationally Unique Identifier (OUI), which is assigned by the IEEE and comprises the first three
  /// bytes of the address.
  ///
  /// These techniques can be used together or separately to identify the device's manufacturer depending on the use
  /// case.
  final int? manufacturerId;

  /// A custom function that determines whether the vendor ID in a [BleDevice] matches a desired value.
  ///
  /// Some devices may encode their vendor ID in a non-standard way that cannot be captured through the conventional
  /// Manufacturer Specific Data or MAC address OUI. This optional function allows specifying custom logic for matching
  /// vendor IDs.
  ///
  /// The function should return `true` if the [BleDevice] matches the expected vendor ID using the desired logic. If
  /// this function is provided, it will be called in addition to the standard manufacturer ID checks.
  final bool Function(BleDevice device)? customVendorIdMatcher;

  /// Additional manufacturer data that must match the advertised data.
  final Map<int, List<int>>? manufacturerData;

  /// Constructs a [ScanFilter] instance with specified filter parameters.
  ///
  /// You can specify one or more criteria that scanned devices must match. If all parameters are left `null`, the
  /// filter will not apply any restrictions.
  ///
  /// [deviceName] filters devices based on their advertised name. [serviceUuids] filters devices based on their
  /// advertised service UUIDs. [manufacturerId] filters devices based on their manufacturer ID. [manufacturerData]
  /// filters devices based on their manufacturer-specific data. [customVendorIdMatcher] allows custom logic for
  /// matching vendor IDs in cases where standard methods are insufficient.
  ScanFilter({
    this.deviceName,
    this.serviceUuids,
    this.manufacturerId,
    this.manufacturerData,
    this.customVendorIdMatcher,
  });

  /// Converts the [ScanFilter] instance into a map representation.
  ///
  /// This method is useful for sending the filter data across platform channels.
  Map<String, dynamic> toMap() {
    return {
      'deviceName': deviceName,
      'serviceUuids': serviceUuids,
      'manufacturerId': manufacturerId,
      'manufacturerData': manufacturerData,
      'customVendorIdMatcher': null,
    };
  }
}
