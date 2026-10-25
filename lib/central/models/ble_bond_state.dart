/// Enumeration representing the possible bonding states between a Bluetooth peripheral and the host platform.
///
/// ## What bonding is
///
/// Bonding (often used interchangeably with "pairing") is the process by which two Bluetooth devices exchange and
/// persist long-term keys so that future connections can be encrypted without repeating the pairing exchange. It is a
/// distinct concept from connection: a device can be connected without being bonded, and can remain bonded across
/// disconnections.
///
/// ## The operating system owns bonding
///
/// On both Android and iOS the bonding process itself is performed by the operating system, not by this plugin. A
/// Flutter app using this plugin can *provoke* bonding (on Android by explicitly requesting it, and on both platforms
/// by interacting with an encrypted characteristic), but it cannot drive the pairing exchange directly. These states
/// therefore report what the OS is doing, to the extent the OS exposes it.
///
/// * [none]: No bond exists between the host and the peripheral.
/// * [bonding]: The operating system is actively establishing a bond with the peripheral.
/// * [bonded]: A bond has been successfully established and persisted.
/// * [failed]: An attempt to establish a bond failed. The accompanying `BleBondEvent` failure describes why, to the
///   extent the platform provides that information.
/// * [unknown]: The bonding state could not be determined.
enum BleBondState {
  /// No bond exists between the host and the peripheral.
  none('none'),

  /// The operating system is actively establishing a bond with the peripheral.
  bonding('bonding'),

  /// A bond has been successfully established and persisted by the operating system.
  bonded('bonded'),

  /// An attempt to establish a bond failed.
  ///
  /// When a [BleBondState] of [failed] is reported, the accompanying `BleBondEvent` failure describes why the attempt
  /// failed, to the extent the platform provides that information. On Android this detail is often rich (an unbond
  /// reason code); on iOS it is limited by the platform (see `BleBondFailure`).
  failed('failed'),

  /// The bonding state, or lack thereof, between the peripheral and the host device is in an unknown state.
  unknown('unknown');

  /// A String identifier for each [BleBondState] value, matching the value emitted by the native platforms.
  final String identifier;

  const BleBondState(this.identifier);

  /// Resolves a [BleBondState] from its String [identifier] as sent by the native platform.
  ///
  /// Matching is case-insensitive. Any value that does not correspond to a known state — including a `null` argument or
  /// an identifier introduced by a newer native layer than this Dart code — resolves to [BleBondState.unknown] rather
  /// than throwing. This keeps the method channel handler resilient to unexpected payloads.
  ///
  /// - Parameter [identifier]: The raw state identifier received from the platform, such as `"bonded"` or `"failed"`.
  /// - Returns: The matching [BleBondState], or [BleBondState.unknown] when no match is found.
  static BleBondState fromIdentifier(String? identifier) {
    if (identifier == null) {
      return BleBondState.unknown;
    }

    final String normalized = identifier.toLowerCase();
    for (final BleBondState state in BleBondState.values) {
      if (state.identifier == normalized) {
        return state;
      }
    }

    return BleBondState.unknown;
  }
}
