import 'ble_bond_failure.dart';
import 'ble_bond_state.dart';

/// A single bonding lifecycle update for a BLE peripheral, carrying the new [state] and, when the state reflects a
/// problem, the [failure] detail that explains it.
///
/// ## Why an event rather than a bare state
///
/// Bonding state alone cannot answer "why did this fail?". Android surfaces a failure reason (an unbond reason code)
/// alongside the transition to an unbonded state, but a plain [BleBondState] enum has nowhere to carry it.
/// [BleBondEvent] couples the state with an optional [BleBondFailure] so that the reason travels in-band with the state
/// it describes, guaranteeing correct ordering and eliminating the need for a parallel error channel. This mirrors the
/// design of `BleConnectionEvent` for the connection lifecycle.
///
/// ## When [failure] is populated
///
/// * [BleBondState.failed]: [failure] is always present and describes why the bond attempt failed, to the extent the
///   platform provides that information.
/// * All other states ([BleBondState.none], [BleBondState.bonding], [BleBondState.bonded], [BleBondState.unknown]):
///   [failure] is `null`.
///
/// Use [isFailure] as a convenience to detect any event that carries failure detail.
class BleBondEvent {
  /// The bonding state reported by this event.
  final BleBondState state;

  /// The failure detail associated with this event, or `null` when the event does not represent a failure.
  ///
  /// See the class-level documentation for exactly when this field is populated for each [state].
  final BleBondFailure? failure;

  /// Creates a [BleBondEvent].
  ///
  /// - Parameter [state]: The bonding state this event represents. Required.
  /// - Parameter [failure]: The accompanying failure detail, or `null` when the event is not a failure.
  const BleBondEvent({
    required this.state,
    this.failure,
  });

  /// Whether this event carries failure detail.
  ///
  /// Returns `true` when [failure] is non-null, which is the case for every [BleBondState.failed] event.
  bool get isFailure => failure != null;

  /// Creates a [BleBondEvent] from the map sent across the method channel by the native platform.
  ///
  /// The native layer always sends a map for bonding updates. The `state` key is resolved tolerantly via
  /// [BleBondState.fromIdentifier] (falling back to [BleBondState.unknown] for unrecognized values). A [failure] is
  /// constructed only when the resolved state is [BleBondState.failed].
  ///
  /// - Parameter [map]: The decoded method channel arguments describing the bonding update.
  /// - Returns: A [BleBondEvent] with the resolved [state] and, where applicable, populated [failure].
  factory BleBondEvent.fromMap(Map<Object?, Object?> map) {
    final BleBondState state = BleBondState.fromIdentifier(
      map['state'] as String?,
    );

    return BleBondEvent(
      state: state,
      failure: state == BleBondState.failed ? BleBondFailure.fromMap(map) : null,
    );
  }

  @override
  String toString() {
    return 'BleBondEvent(state: ${state.identifier}, failure: $failure)';
  }
}
