import '../../shared/models/ble_device.dart';
import '../../shared/models/manufacturer_data.dart';
import '../models/scan_filter.dart';

/// Contains utility methods for working with [ScanFilter]s.
extension ScanFilterListExtensions on List<ScanFilter>? {
  /// Checks if the given [BleDevice] matches any of the provided [ScanFilter]s.
  ///
  /// This method checks if the device's name and advertised service UUIDs match any of the filters. It returns `true`
  /// if the device matches any filter, otherwise it returns `false`.
  ///
  /// The main reason this logic is in an extension is to allow the same filtering logic to be applied in both the
  /// real `CentralMethodChannel` and the fake `FakeCentralMethodChannel`. This way, the same filtering logic can be
  /// used in tests without duplicating code.
  ///
  /// Note that Bluetooth device filtering during Bluetooth scanning is also implemented on the native side. This
  /// filtering logic provides an additional layer of filtering that is applied before the scan results are sent to the
  /// Flutter side. This makes filtering more robust and also allows for more sophisticated filtering mechanisms to
  /// be applied without adding custom filtering mechanisms for each platform.
  bool deviceMatchesFilters(BleDevice device) {
    // If no filters are provided, return true to include all devices.
    if (this == null || (this?.isEmpty ?? true)) return true;

    // Iterate through each filter in the list.
    for (final ScanFilter filter in this!) {
      // Check if the device name matches the filter name.
      final bool matchesName = filter.deviceName == null || filter.deviceName == device.name;

      // Case-insensitive UUID matching for advertised service UUIDs.
      final bool matchesService = filter.serviceUuids == null ||
          device.advertisedServiceUuids.map((uuid) => uuid.toLowerCase()).any(
                (String uuid) => filter.serviceUuids!.map((f) => f.toLowerCase()).contains(uuid),
              );

      // Check if the device matches the manufacturer ID specified in the filter.
      final bool matchesManufacturer = _matchesManufacturerId(device, filter);

      // Check if full manufacturer data matches exactly.
      final ManufacturerData? data = device.manufacturerData;
      bool matchesManufacturerData = false;
      if (filter.manufacturerData != null && data != null) {
        // Convert ManufacturerData to a compatible map for comparison.
        final Map<int, List<int>> deviceMap = {
          (data.manufacturerId[0] | (data.manufacturerId[1] << 8)): data.payload,
        };

        if (filter.manufacturerData!.length == deviceMap.length &&
            filter.manufacturerData!.keys.every(
              (int key) => deviceMap.containsKey(key) && _listEquals(filter.manufacturerData![key]!, deviceMap[key]!),
            )) {
          matchesManufacturerData = true;
        }
      } else {
        // If no manufacturer data is specified in the filter, we consider it a match.
        matchesManufacturerData = filter.manufacturerData == null || filter.manufacturerData!.isEmpty;
      }

      // If all conditions match, return true.
      if (matchesName && matchesService && matchesManufacturer && matchesManufacturerData) {
        return true;
      }
    }

    return false;
  }

  /// Checks if the device matches the manufacturer ID specified in the [filter].
  ///
  /// This checks the following:
  /// - Manufacturer Specific Data (AD type 0xFF): Matches the 16-bit Bluetooth SIG company identifier.
  /// - Service Data fields (AD types 0x16 or 0x21): May contain a custom manufacturer identifier depending on the vendor's encoding.
  /// - MAC address: Compares the first 3 bytes (OUI) if the manufacturer ID corresponds to a known OUI prefix.
  /// - Custom matcher: Uses [ScanFilter.customVendorIdMatcher] for any vendor-specific logic.
  ///
  /// If the [filter] does not specify a manufacturer ID, this returns true.
  bool _matchesManufacturerId(BleDevice device, ScanFilter filter) {
    // If no manufacturer ID is specified in the filter, return true to include all devices.
    if (filter.manufacturerId == null) return true;

    final int id = filter.manufacturerId!;
    final ManufacturerData? data = device.manufacturerData;

    // Check Manufacturer Specific Data (AD type 0xFF)
    if (data != null && data.manufacturerId.length >= 2) {
      // Extract the first two bytes as the manufacturer ID. This is the standard way to include manufacturer ID.
      final int extractedId = data.manufacturerId[0] | (data.manufacturerId[1] << 8);
      if (extractedId == id) {
        return true;
      }
    }

    // Check MAC address OUI (first 3 bytes of address if it's in standard format). This is another common way to
    // identify manufacturers.
    final String mac = device.address.toUpperCase().replaceAll(':', '');
    if (mac.length >= 6) {
      final int? ouiPrefix = int.tryParse(mac.substring(0, 6), radix: 16);
      if (ouiPrefix != null && (ouiPrefix & 0xFFFF) == id) {
        return true;
      }
    }

    // Check custom matcher if provided.
    if (filter.customVendorIdMatcher != null) {
      if (filter.customVendorIdMatcher!(device)) {
        return true;
      }
    }

    // NOTE: Matching manufacturer ID in service data is vendor-specific and not implemented here.
    return false;
  }

  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
