package com.splendidendeavors.flutter_splendid_ble.`interface`

/**
 * The connection states reported to the Dart side for a BLE peripheral.
 *
 * The lowercase form of each value's [name] is sent in the `state` field of the connection event payload and must
 * match the identifiers of the Dart `BleConnectionState` enum.
 *
 * [FAILED] represents a connection attempt that never succeeded, as distinct from [DISCONNECTED], which represents the
 * termination of a previously established connection. Android surfaces both as `STATE_DISCONNECTED` in
 * `onConnectionStateChange`; this plugin distinguishes them by whether the device had previously reached [CONNECTED].
 */
enum class ConnectionState {
    CONNECTED,
    DISCONNECTED,
    CONNECTING,
    DISCONNECTING,
    FAILED,
    UNKNOWN
}
