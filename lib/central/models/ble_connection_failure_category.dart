/// A normalized, platform-agnostic classification of why a BLE connection attempt failed or an established connection
/// was lost unexpectedly.
///
/// ## Purpose
///
/// Each platform reports connection failures using its own vocabulary: Apple platforms deliver a `CBError`/`CBATTError`
/// code within an `NSError`, while Android delivers an integer GATT/HCI status code. These raw values are preserved on
/// the accompanying `BleConnectionFailure` for logging and deep investigation, but they are difficult to branch on
/// directly because the same logical failure has different representations on each platform.
///
/// [BleConnectionFailureCategory] maps those platform-specific codes into a single, stable set of reasons so that
/// application-level recovery logic can be written once rather than branching per platform. For example, a firmware
/// watchdog that drops the link appears as `CBError.peripheralDisconnected` (code 7) on iOS and as GATT status 19
/// ("connection terminated by peer") on Android; both normalize to [peerTerminated].
///
/// ## Interpreting [unknown]
///
/// [unknown] does not mean "no failure". It means the platform either provided no error object (CoreBluetooth
/// frequently delivers a `nil` error on `didFailToConnect`) or provided a code that this plugin does not yet map to a
/// more specific category (such as Android's catch-all GATT_ERROR, status 133). When the category is [unknown], consult
/// the accompanying `BleConnectionFailure` raw code, domain, and description for whatever detail the platform did
/// supply.
enum BleConnectionFailureCategory {
  /// The connection attempt or link supervision timed out.
  ///
  /// The peripheral did not respond within the time the platform allows. On Apple platforms this corresponds to
  /// `CBError.connectionTimeout`; on Android to GATT status codes such as 8 (connection timeout) and 62 (failure to
  /// establish).
  timeout('timeout'),

  /// The peripheral (or its firmware) terminated the connection.
  ///
  /// The remote device closed the link rather than the host. This is a common signature of firmware-side issues such as
  /// a watchdog reset or an application-layer disconnect. Corresponds to `CBError.peripheralDisconnected` on Apple
  /// platforms and GATT status 19 on Android.
  peerTerminated('peerTerminated'),

  /// The local host terminated or could not maintain the connection for a device-side reason.
  ///
  /// Covers cases where the host stack closed the link, as opposed to the peripheral closing it. Corresponds to GATT
  /// status 22 (terminated by local host) on Android.
  hostTerminated('hostTerminated'),

  /// Authentication, pairing, or encryption with the peripheral failed.
  ///
  /// The link could not be secured — for example, bonding was rejected, encryption timed out, or insufficient
  /// authentication was available for an encrypted characteristic. Corresponds to `CBError.encryptionTimedOut` and
  /// insufficient-authentication ATT errors on Apple platforms, and to GATT status codes such as 5
  /// (insufficient authentication) and 137 on Android.
  authenticationFailure('authenticationFailure'),

  /// The host has reached the maximum number of simultaneous connections it can maintain.
  ///
  /// Corresponds to `CBError.connectionLimitReached` on Apple platforms. Android does not report a dedicated status for
  /// this condition.
  connectionLimitReached('connectionLimitReached'),

  /// The peripheral is no longer reachable or was removed before the connection could be established.
  ///
  /// Corresponds to `CBError.peripheralDisconnected` variants and `CBError.unknownDevice`/device-not-found conditions,
  /// and to Android GATT status 62 in some stacks. Also used when the host could not locate the peripheral to connect
  /// to in the first place.
  unreachable('unreachable'),

  /// The failure is unclassified.
  ///
  /// Either the platform provided no error detail, or it provided a code that is not yet mapped to a more specific
  /// category. See the enum-level documentation for guidance on inspecting the raw failure fields in this case.
  unknown('unknown');

  /// A stable String identifier for each category, matching the value emitted by the native platforms.
  final String identifier;

  const BleConnectionFailureCategory(this.identifier);

  /// Resolves a [BleConnectionFailureCategory] from its String [identifier] as sent by the native platform.
  ///
  /// Matching is case-insensitive. A `null` argument or any unrecognized identifier resolves to
  /// [BleConnectionFailureCategory.unknown], so that a newer native layer introducing additional categories cannot
  /// cause older Dart code to throw.
  ///
  /// - Parameter [identifier]: The raw category identifier received from the platform.
  /// - Returns: The matching [BleConnectionFailureCategory], or [BleConnectionFailureCategory.unknown] when no match is
  ///   found.
  static BleConnectionFailureCategory fromIdentifier(String? identifier) {
    if (identifier == null) {
      return BleConnectionFailureCategory.unknown;
    }

    final String normalized = identifier.toLowerCase();
    for (final BleConnectionFailureCategory category
        in BleConnectionFailureCategory.values) {
      if (category.identifier.toLowerCase() == normalized) {
        return category;
      }
    }

    return BleConnectionFailureCategory.unknown;
  }
}
