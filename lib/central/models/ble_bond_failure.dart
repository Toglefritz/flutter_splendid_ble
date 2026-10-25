import 'ble_bond_failure_category.dart';
import 'ble_bond_state.dart';

/// Describes why a BLE bonding attempt failed.
///
/// ## Overview
///
/// A [BleBondFailure] accompanies a [BleBondState.failed] event. It carries both a normalized, cross-platform
/// [category] for writing recovery logic and the raw platform-specific detail ([rawCode], [domain], [description]) for
/// logging and deep diagnosis.
///
/// ## Platform detail and the iOS limitation
///
/// The amount of detail available depends entirely on the underlying platform, and the two platforms are highly
/// asymmetric here because bonding is performed by the operating system:
///
/// * **Android (BluetoothDevice):** When a bond attempt fails, Android broadcasts `ACTION_BOND_STATE_CHANGED` with a
///   transition to `BOND_NONE` and an `EXTRA_REASON` (or `EXTRA_UNBOND_REASON`) code. [rawCode] is that integer reason
///   code, [domain] is `"android_bond"`, and [description] is a short human-readable label when one is known. This
///   yields a specific [category] such as [BleBondFailureCategory.authenticationRejected] or
///   [BleBondFailureCategory.authenticationTimeout].
///
/// * **iOS / macOS (CoreBluetooth):** This is a known platform limitation. CoreBluetooth does **not** expose a bonding
///   API, a bond-state callback, or a bonding failure reason to apps — the operating system deliberately hides the
///   pairing process. The only signal this plugin can observe is an attribute-level error (`CBATTError`) returned when
///   an operation on an encrypted characteristic fails, which is the closest available proxy for a bonding failure.
///   When present, [rawCode] is the `NSError` code, [domain] is the `NSError` domain (such as `CBATTErrorDomain`), and
///   [description] is the error's `localizedDescription`. In practice the [category] on iOS is almost always
///   [BleBondFailureCategory.authenticationFailure] or [BleBondFailureCategory.unknown]. There is nothing this plugin
///   can do to improve iOS bonding diagnostics, because the information simply is not made available by the platform.
///
/// Because the raw values differ per platform, prefer branching on [category] for behavior and use the raw fields for
/// logging and analysis.
class BleBondFailure {
  /// The normalized, platform-agnostic classification of the failure.
  ///
  /// This is the field application code should branch on when deciding how to recover. See [BleBondFailureCategory] for
  /// the meaning of each value and guidance on interpreting [BleBondFailureCategory.unknown].
  final BleBondFailureCategory category;

  /// The host platform that reported the failure, such as `"ios"`, `"macos"`, or `"android"`.
  ///
  /// Useful for interpreting [rawCode] and [domain], which are only meaningful in the context of the platform that
  /// produced them. May be `null` if the platform did not identify itself.
  final String? platform;

  /// The raw, platform-specific numeric error code, when the platform provides one.
  ///
  /// On Android this is the `ACTION_BOND_STATE_CHANGED` unbond reason integer. On Apple platforms it is the `NSError`
  /// code from an attribute-level error on an encrypted operation. It is `null` when the platform did not supply a code
  /// (which is common on iOS, where bonding detail is not exposed).
  final int? rawCode;

  /// The platform-specific error domain or source of [rawCode], when available.
  ///
  /// On Android this is `"android_bond"`; on Apple platforms it is the `NSError` domain (for example `CBATTErrorDomain`
  /// or `CBErrorDomain`). May be `null` when no code was provided.
  final String? domain;

  /// A human-readable description of the failure as provided by the platform, when available.
  ///
  /// On Android this is a short label for the known unbond reason codes. On Apple platforms this is the `NSError`
  /// `localizedDescription`. This string is intended for logs and diagnostics, not for direct display to end users. May
  /// be `null` when the platform provided no description.
  final String? description;

  /// Creates a [BleBondFailure].
  ///
  /// - Parameter [category]: The normalized failure classification. Required.
  /// - Parameter [platform]: The reporting host platform identifier, or `null` if unknown.
  /// - Parameter [rawCode]: The raw platform-specific error code, or `null` if none was provided.
  /// - Parameter [domain]: The platform-specific error domain, or `null` if none was provided.
  /// - Parameter [description]: A human-readable description, or `null` if none was provided.
  const BleBondFailure({
    required this.category,
    this.platform,
    this.rawCode,
    this.domain,
    this.description,
  });

  /// Creates a [BleBondFailure] from the map sent across the method channel by the native platform.
  ///
  /// The map is tolerant of missing keys: any absent or malformed field falls back to `null`, and an absent or
  /// unrecognized category falls back to [BleBondFailureCategory.unknown] (see [BleBondFailureCategory.fromIdentifier]).
  /// This ensures a failure event can always be constructed even from a partial payload.
  ///
  /// - Parameter [map]: The decoded method channel arguments describing the failure.
  /// - Returns: A [BleBondFailure] populated with whatever detail the platform provided.
  factory BleBondFailure.fromMap(Map<Object?, Object?> map) {
    return BleBondFailure(
      category: BleBondFailureCategory.fromIdentifier(
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
    return 'BleBondFailure('
        'category: ${category.identifier}, '
        'platform: $platform, '
        'rawCode: $rawCode, '
        'domain: $domain, '
        'description: $description)';
  }
}
