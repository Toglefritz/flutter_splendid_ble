import 'ble_connection_failure.dart';
import 'ble_connection_state.dart';

/// A single connection lifecycle update for a BLE peripheral, carrying the new [state] and, when the state reflects a
/// problem, the [failure] detail that explains it.
///
/// ## Why an event rather than a bare state
///
/// Connection state alone cannot answer "why did this fail?". Both Apple and Android platforms surface failure detail
/// (a `CBError`/`CBATTError` on Apple, a GATT/HCI status integer on Android) alongside the state change, but a plain
/// [BleConnectionState] enum has nowhere to carry it. [BleConnectionEvent] couples the state with an optional
/// [BleConnectionFailure] so that the reason travels in-band with the state it describes, guaranteeing correct ordering
/// and eliminating the need for a parallel error channel.
///
/// ## When [failure] is populated
///
/// * [BleConnectionState.failed]: [failure] is always present and describes why the connection attempt never
///   succeeded.
/// * [BleConnectionState.disconnected]: [failure] is present only when the disconnection was unexpected (the platform
///   reported an error). A clean, application-initiated disconnect produces a [BleConnectionState.disconnected] event
///   with a `null` [failure].
/// * All other states ([BleConnectionState.connected], [BleConnectionState.connecting],
///   [BleConnectionState.disconnecting], [BleConnectionState.unknown]): [failure] is `null`.
///
/// Use [isFailure] as a convenience to detect any event that carries failure detail.
class BleConnectionEvent {
  /// The connection state reported by this event.
  final BleConnectionState state;

  /// The failure detail associated with this event, or `null` when the event does not represent a failure.
  ///
  /// See the class-level documentation for exactly when this field is populated for each [state].
  final BleConnectionFailure? failure;

  /// Creates a [BleConnectionEvent].
  ///
  /// - Parameter [state]: The connection state this event represents. Required.
  /// - Parameter [failure]: The accompanying failure detail, or `null` when the event is not a failure.
  const BleConnectionEvent({
    required this.state,
    this.failure,
  });

  /// Whether this event carries failure detail.
  ///
  /// Returns `true` when [failure] is non-null, which is the case for every [BleConnectionState.failed] event and for
  /// unexpected [BleConnectionState.disconnected] events.
  bool get isFailure => failure != null;

  /// Creates a [BleConnectionEvent] from the map sent across the method channel by the native platform.
  ///
  /// The native layer always sends a map for connection updates. The `state` key is resolved tolerantly via
  /// [BleConnectionState.fromIdentifier] (falling back to [BleConnectionState.unknown] for unrecognized values). A
  /// [failure] is constructed only when the payload actually describes a failure — that is, when the resolved state is
  /// [BleConnectionState.failed], or when the state is [BleConnectionState.disconnected] and the payload includes error
  /// detail (a `category`, `errorCode`, `errorDomain`, or `errorDescription`).
  ///
  /// - Parameter [map]: The decoded method channel arguments describing the connection update.
  /// - Returns: A [BleConnectionEvent] with the resolved [state] and, where applicable, populated [failure].
  factory BleConnectionEvent.fromMap(Map<Object?, Object?> map) {
    final BleConnectionState state = BleConnectionState.fromIdentifier(
      map['state'] as String?,
    );

    final bool payloadHasFailureDetail = map['category'] != null ||
        map['errorCode'] != null ||
        map['errorDomain'] != null ||
        map['errorDescription'] != null;

    final bool shouldParseFailure = state == BleConnectionState.failed ||
        (state == BleConnectionState.disconnected && payloadHasFailureDetail);

    return BleConnectionEvent(
      state: state,
      failure: shouldParseFailure ? BleConnectionFailure.fromMap(map) : null,
    );
  }

  @override
  String toString() {
    return 'BleConnectionEvent(state: ${state.identifier}, failure: $failure)';
  }
}
