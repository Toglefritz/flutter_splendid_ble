/// A normalized, platform-agnostic classification of why a BLE bonding attempt failed.
///
/// ## Purpose
///
/// Each platform reports bonding failures using its own vocabulary, and the two platforms differ dramatically in how
/// much they expose. Android broadcasts a specific unbond reason code (such as `UNBOND_REASON_AUTH_FAILED`) alongside
/// the `BOND_NONE` transition, while iOS exposes no bonding API at all and only surfaces a generic `CBATTError` when an
/// encrypted operation fails. These raw values are preserved on the accompanying `BleBondFailure` for logging and deep
/// investigation, but they are difficult to branch on directly because the same logical failure has different
/// representations on each platform.
///
/// [BleBondFailureCategory] maps those platform-specific signals into a single, stable set of reasons so that
/// application-level recovery logic can be written once rather than branching per platform.
///
/// ## Platform asymmetry
///
/// This categorization is inherently richer on Android than on iOS. Android's `ACTION_BOND_STATE_CHANGED` broadcast
/// carries a dedicated reason code that maps cleanly onto [authenticationFailure], [authenticationRejected],
/// [authenticationTimeout], and [remoteDeviceDown]. On iOS, the operating system does not expose bonding progress or a
/// bonding failure reason to apps; the only signal available is an attribute-level error from an encrypted operation,
/// which almost always normalizes to [authenticationFailure] or [unknown]. This is a platform limitation, not a gap in
/// this plugin. See `BleBondFailure` for details.
///
/// ## Interpreting [unknown]
///
/// [unknown] does not mean "no failure". It means the platform either provided no reason detail or provided a code that
/// this plugin does not yet map to a more specific category. When the category is [unknown], consult the accompanying
/// `BleBondFailure` raw code, domain, and description for whatever detail the platform did supply.
enum BleBondFailureCategory {
  /// Authentication or pairing with the peripheral failed for an unspecified authentication reason.
  ///
  /// The link could not be secured — for example, mismatched keys, an encryption failure, or an insufficient-
  /// authentication attribute error. Corresponds to Android `UNBOND_REASON_AUTH_FAILED` and to the insufficient-
  /// authentication/encryption `CBATTError` codes on Apple platforms.
  authenticationFailure('authenticationFailure'),

  /// The peripheral (or the user) actively rejected the pairing request.
  ///
  /// The bond was refused rather than simply failing. Corresponds to Android `UNBOND_REASON_AUTH_REJECTED`. Apple
  /// platforms do not report a distinct rejection reason.
  authenticationRejected('authenticationRejected'),

  /// The pairing exchange timed out before it could complete.
  ///
  /// The peripheral did not respond within the time the platform allows for pairing. Corresponds to Android
  /// `UNBOND_REASON_AUTH_TIMEOUT`.
  authenticationTimeout('authenticationTimeout'),

  /// The peripheral became unreachable during the pairing exchange.
  ///
  /// The remote device went down or moved out of range before the bond could be established. Corresponds to Android
  /// `UNBOND_REASON_REMOTE_DEVICE_DOWN`.
  remoteDeviceDown('remoteDeviceDown'),

  /// An existing bond was removed, or a bond attempt was cancelled, by the host or the user.
  ///
  /// Corresponds to Android `UNBOND_REASON_REMOVED` and to a user- or app-initiated cancellation of the pairing flow.
  removed('removed'),

  /// The failure is unclassified.
  ///
  /// Either the platform provided no reason detail, or it provided a code that is not yet mapped to a more specific
  /// category. This is the common case on iOS, where the operating system does not expose a bonding failure reason. See
  /// the enum-level documentation for guidance on inspecting the raw failure fields in this case.
  unknown('unknown');

  /// A stable String identifier for each category, matching the value emitted by the native platforms.
  final String identifier;

  const BleBondFailureCategory(this.identifier);

  /// Resolves a [BleBondFailureCategory] from its String [identifier] as sent by the native platform.
  ///
  /// Matching is case-insensitive. A `null` argument or any unrecognized identifier resolves to
  /// [BleBondFailureCategory.unknown], so that a newer native layer introducing additional categories cannot cause
  /// older Dart code to throw.
  ///
  /// - Parameter [identifier]: The raw category identifier received from the platform.
  /// - Returns: The matching [BleBondFailureCategory], or [BleBondFailureCategory.unknown] when no match is found.
  static BleBondFailureCategory fromIdentifier(String? identifier) {
    if (identifier == null) {
      return BleBondFailureCategory.unknown;
    }

    final String normalized = identifier.toLowerCase();
    for (final BleBondFailureCategory category in BleBondFailureCategory.values) {
      if (category.identifier.toLowerCase() == normalized) {
        return category;
      }
    }

    return BleBondFailureCategory.unknown;
  }
}
