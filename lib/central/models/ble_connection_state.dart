/// Enumeration representing the possible connection states between a Bluetooth peripheral and the host platform.
///
/// * [connected]: The Bluetooth peripheral is successfully connected.
/// * [disconnected]: The Bluetooth peripheral is disconnected from the host device.
/// * [connecting]: A connection between the peripheral and the host device is in the process of being established.
/// * [disconnecting]: The peripheral and the host device are in the process of disconnecting.
/// * [failed]: An attempt to establish a connection with the peripheral failed before it was ever connected.
/// * [unknown]: The connection, or lack thereof, between the peripheral and the host device is in an unknown state.
enum BleConnectionState {
  /// The Bluetooth peripheral is successfully connected.
  connected('connected'),

  /// The Bluetooth peripheral is disconnected from the host device.
  disconnected('disconnected'),

  /// A connection between the peripheral and the host device is in the process of being established.
  connecting('connecting'),

  /// The peripheral and the host device are in the process of disconnecting.
  disconnecting('disconnecting'),

  /// An attempt to establish a connection with the peripheral failed before it was ever connected.
  ///
  /// This is distinct from [disconnected]: it represents a connection attempt that never succeeded (for example, the
  /// peripheral was out of range or rejected the connection), rather than the termination of a previously established
  /// connection. When a [BleConnectionState] of [failed] is reported, the accompanying `BleConnectionEvent` failure
  /// describes why the attempt failed, to the extent the platform provides that information.
  failed('failed'),

  /// The connection, or lack thereof, between the peripheral and the host device is in an unknown state.
  unknown('unknown');

  /// A String identifier for each [BleConnectionState] value.
  final String identifier;

  const BleConnectionState(this.identifier);

  /// Resolves a [BleConnectionState] from its String [identifier] as sent by the native platform.
  ///
  /// Matching is case-insensitive. Any value that does not correspond to a known state — including a `null` argument or
  /// an identifier introduced by a newer native layer than this Dart code — resolves to [BleConnectionState.unknown]
  /// rather than throwing. This keeps the method channel handler resilient to unexpected payloads.
  ///
  /// - Parameter [identifier]: The raw state identifier received from the platform, such as `"connected"` or
  ///   `"failed"`.
  /// - Returns: The matching [BleConnectionState], or [BleConnectionState.unknown] when no match is found.
  static BleConnectionState fromIdentifier(String? identifier) {
    if (identifier == null) {
      return BleConnectionState.unknown;
    }

    final String normalized = identifier.toLowerCase();
    for (final BleConnectionState state in BleConnectionState.values) {
      if (state.identifier == normalized) {
        return state;
      }
    }

    return BleConnectionState.unknown;
  }
}
