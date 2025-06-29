import '../../shared/models/ble_device.dart';
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

      // If both conditions match, return true.
      if (matchesName && matchesService) {
        return true;
      }
    }

    return false;
  }
}
