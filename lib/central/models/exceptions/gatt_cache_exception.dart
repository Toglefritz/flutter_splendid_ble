/// Exception thrown when a GATT cache refresh operation fails.
///
/// On Android, the OS caches GATT service information between connections to avoid re-running
/// service discovery every time. This is normally helpful, but causes problems when a bonded
/// device's firmware is updated or when its attribute table changes, because Android may serve
/// the old cached layout instead of reading fresh data from the device.
///
/// Calling `refreshGattCache` before service discovery forces Android to discard the stale cache.
/// When that reflection-based call fails, this exception is thrown.
///
/// This exception is Android-specific. On iOS, Core Bluetooth does not expose a GATT cache or a
/// mechanism to clear it, so `refreshGattCache` is a no-op there and this exception is never
/// thrown.
///
/// ## Example
///
/// ```dart
/// try {
///   await ble.refreshGattCache(deviceAddress: address);
/// } on GattCacheException catch (e) {
///   // Log the failure and proceed with service discovery anyway.
///   debugPrint(e.message);
/// }
/// ```
class GattCacheException implements Exception {
  /// A message describing why the GATT cache refresh failed.
  final String message;

  /// Creates a [GattCacheException] with the specified error [message].
  GattCacheException(this.message);

  @override
  String toString() => 'GattCacheException: $message';
}
