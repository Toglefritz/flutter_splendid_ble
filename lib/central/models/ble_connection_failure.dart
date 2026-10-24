import 'ble_connection_failure_category.dart';
import 'ble_connection_state.dart';

/// Describes why a BLE connection attempt failed or an established connection was lost unexpectedly.
///
/// ## Overview
///
/// A [BleConnectionFailure] accompanies a [BleConnectionState.failed] event and may accompany a
/// [BleConnectionState.disconnected] event when the disconnection was not initiated by the application. It carries both
/// a normalized, cross-platform [category] for writing recovery logic and the raw platform-specific detail
/// ([rawCode], [domain], [description]) for logging and deep diagnosis.
///
/// ## Platform detail
///
/// The amount of detail available depends entirely on the underlying platform:
///
/// * **iOS / macOS (CoreBluetooth):** [rawCode] is the `NSError` code (a `CBError.Code` or `CBATTError.Code` raw
///   value), [domain] is the `NSError` domain (such as `CBErrorDomain`), and [description] is the error's
///   `localizedDescription`. CoreBluetooth often delivers a `nil` error on a failed connection, in which case
///   [rawCode], [domain], and [description] are all `null` and [category] is [BleConnectionFailureCategory.unknown].
/// * **Android (BluetoothGatt):** [rawCode] is the integer GATT/HCI status code from `onConnectionStateChange`
///   (for example 19, 133, or 8), [domain] is `"android_gatt"`, and [description] is a short human-readable label when
///   one is known.
///
/// Because the raw values differ per platform, prefer branching on [category] for behavior and use the raw fields for
/// logging and analysis.
class BleConnectionFailure {
  /// The normalized, platform-agnostic classification of the failure.
  ///
  /// This is the field application code should branch on when deciding how to recover. See
  /// [BleConnectionFailureCategory] for the meaning of each value and guidance on interpreting
  /// [BleConnectionFailureCategory.unknown].
  final BleConnectionFailureCategory category;

  /// The host platform that reported the failure, such as `"ios"`, `"macos"`, or `"android"`.
  ///
  /// Useful for interpreting [rawCode] and [domain], which are only meaningful in the context of the platform that
  /// produced them. May be `null` if the platform did not identify itself.
  final String? platform;

  /// The raw, platform-specific numeric error code, when the platform provides one.
  ///
  /// On Apple platforms this is the `NSError` code; on Android it is the GATT/HCI status integer. It is `null` when the
  /// platform did not supply a code (notably when CoreBluetooth reports a `nil` error).
  final int? rawCode;

  /// The platform-specific error domain or source of [rawCode], when available.
  ///
  /// On Apple platforms this is the `NSError` domain (for example `CBErrorDomain` or `CBATTErrorDomain`); on Android it
  /// is `"android_gatt"`. May be `null` when no code was provided.
  final String? domain;

  /// A human-readable description of the failure as provided by the platform, when available.
  ///
  /// On Apple platforms this is the `NSError` `localizedDescription`. On Android it is a short label for the known
  /// status codes. This string is intended for logs and diagnostics, not for direct display to end users. May be
  /// `null` when the platform provided no description.
  final String? description;

  /// Creates a [BleConnectionFailure].
  ///
  /// - Parameter [category]: The normalized failure classification. Required.
  /// - Parameter [platform]: The reporting host platform identifier, or `null` if unknown.
  /// - Parameter [rawCode]: The raw platform-specific error code, or `null` if none was provided.
  /// - Parameter [domain]: The platform-specific error domain, or `null` if none was provided.
  /// - Parameter [description]: A human-readable description, or `null` if none was provided.
  const BleConnectionFailure({
    required this.category,
    this.platform,
    this.rawCode,
    this.domain,
    this.description,
  });

  /// Creates a [BleConnectionFailure] from the map sent across the method channel by the native platform.
  ///
  /// The map is tolerant of missing keys: any absent or malformed field falls back to `null`, and an absent or
  /// unrecognized category falls back to [BleConnectionFailureCategory.unknown] (see
  /// [BleConnectionFailureCategory.fromIdentifier]). This ensures a failure event can always be constructed even from a
  /// partial payload.
  ///
  /// - Parameter [map]: The decoded method channel arguments describing the failure.
  /// - Returns: A [BleConnectionFailure] populated with whatever detail the platform provided.
  factory BleConnectionFailure.fromMap(Map<Object?, Object?> map) {
    return BleConnectionFailure(
      category: BleConnectionFailureCategory.fromIdentifier(
        map['category'] as String?,
      ),
      platform: map['platform'] as String?,
      rawCode: map['errorCode'] as int?,
      domain: map['errorDomain'] as String?,
      description: map['errorDescription'] as String?,
    );
  }

  @override
  String toString() {
    return 'BleConnectionFailure('
        'category: ${category.identifier}, '
        'platform: $platform, '
        'rawCode: $rawCode, '
        'domain: $domain, '
        'description: $description)';
  }
}
