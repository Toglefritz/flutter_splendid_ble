package com.splendidendeavors.flutter_splendid_ble.`interface`

import android.bluetooth.BluetoothGatt

/**
 * A normalized, platform-agnostic classification of a BLE connection failure.
 *
 * Mirrors the Dart `BleConnectionFailureCategory` enum. The [identifier] values must stay in sync with the Dart
 * enum's identifiers so that the category round-trips across the method channel.
 */
enum class ConnectionFailureCategory(val identifier: String) {
    TIMEOUT("timeout"),
    PEER_TERMINATED("peerTerminated"),
    HOST_TERMINATED("hostTerminated"),
    AUTHENTICATION_FAILURE("authenticationFailure"),
    CONNECTION_LIMIT_REACHED("connectionLimitReached"),
    UNREACHABLE("unreachable"),
    UNKNOWN("unknown"),
}

/**
 * Builds the method channel payloads that describe BLE connection lifecycle updates and normalizes Android GATT/HCI
 * status codes into a cross-platform [ConnectionFailureCategory].
 *
 * ## Why this exists
 *
 * Connection updates are delivered to Dart through the `bleConnectionState_<deviceAddress>` method channel call. This
 * object centralizes construction of that call's argument map so every connection callback emits a consistent,
 * richly-detailed payload rather than a bare status string. The raw GATT status is the richest failure signal Android
 * provides (for example status 19 = terminated by peer, 8 = timeout, 133 = the generic GATT_ERROR); normalizing it
 * here lets the Dart layer branch on a single [ConnectionFailureCategory] across all platforms.
 *
 * ## Payload contract
 *
 * Every connection update sends a `Map<String, Any?>` with:
 *
 * * `state` — the lowercase [ConnectionState] name (`"connected"`, `"disconnected"`, `"failed"`, etc.).
 * * `platform` — always `"android"`; lets the Dart side interpret `errorCode`/`errorDomain`.
 * * `category` — the [ConnectionFailureCategory] identifier, present only for failure payloads.
 * * `errorCode` — the raw GATT/HCI status integer, present only for failure payloads.
 * * `errorDomain` — always `"android_gatt"` for failures.
 * * `errorDescription` — a short human-readable label for known status codes, when available.
 */
object ConnectionEventPayload {

    /** The host platform identifier sent in every connection payload from this plugin. */
    private const val PLATFORM: String = "android"

    /** The error domain reported for all Android GATT/HCI status codes. */
    private const val ERROR_DOMAIN: String = "android_gatt"

    /**
     * Builds the payload for a successful or non-failure connection update (no error detail attached).
     *
     * Use this for [ConnectionState.CONNECTED], [ConnectionState.CONNECTING], [ConnectionState.DISCONNECTING], a clean
     * [ConnectionState.DISCONNECTED], and [ConnectionState.UNKNOWN].
     *
     * @param state The connection state to report.
     * @return A map suitable for the `arguments` of the `bleConnectionState_<deviceAddress>` method channel call.
     */
    fun success(state: ConnectionState): Map<String, Any?> {
        return mapOf(
            "state" to state.name.lowercase(),
            "platform" to PLATFORM,
        )
    }

    /**
     * Builds the payload for a connection failure or an unexpected disconnection, attaching normalized and raw error
     * detail derived from the GATT [status] code.
     *
     * @param state The connection state to report — typically [ConnectionState.FAILED] for a connection attempt that
     *   never succeeded, or [ConnectionState.DISCONNECTED] for an unexpected loss of an established link.
     * @param status The raw GATT/HCI status integer from `onConnectionStateChange`.
     * @return A map suitable for the `arguments` of the `bleConnectionState_<deviceAddress>` method channel call.
     */
    fun failure(state: ConnectionState, status: Int): Map<String, Any?> {
        return mapOf(
            "state" to state.name.lowercase(),
            "platform" to PLATFORM,
            "category" to categorize(status).identifier,
            "errorCode" to status,
            "errorDomain" to ERROR_DOMAIN,
            "errorDescription" to describe(status),
        )
    }

    /**
     * Normalizes a raw GATT/HCI status code into a [ConnectionFailureCategory].
     *
     * The mapping covers the status codes most commonly seen for connection failures. Codes that are not specifically
     * mapped — including the catch-all GATT_ERROR (133) — resolve to [ConnectionFailureCategory.UNKNOWN]; the raw code
     * remains available on the payload for deeper inspection on the Dart side.
     *
     * @param status The raw GATT/HCI status integer.
     * @return The normalized failure category.
     */
    private fun categorize(status: Int): ConnectionFailureCategory {
        return when (status) {
            // 8 = connection timeout (HCI 0x08), 62 = failure to establish connection.
            0x08, 62 -> ConnectionFailureCategory.TIMEOUT
            // 19 = connection terminated by remote peer (HCI 0x13).
            19 -> ConnectionFailureCategory.PEER_TERMINATED
            // 22 = connection terminated by local host (HCI 0x16).
            22 -> ConnectionFailureCategory.HOST_TERMINATED
            // 5 = insufficient authentication, 137 = GATT auth fail / encryption failures.
            5, 137 -> ConnectionFailureCategory.AUTHENTICATION_FAILURE
            else -> ConnectionFailureCategory.UNKNOWN
        }
    }

    /**
     * Returns a short human-readable label for a known GATT/HCI status code, or a generic label including the raw code
     * when it is not specifically recognized.
     *
     * @param status The raw GATT/HCI status integer.
     * @return A description string intended for logs and diagnostics.
     */
    private fun describe(status: Int): String {
        return when (status) {
            0x08 -> "Connection timeout (status 8)"
            19 -> "Connection terminated by peer (status 19)"
            22 -> "Connection terminated by local host (status 22)"
            62 -> "Failure to establish connection (status 62)"
            5 -> "Insufficient authentication (status 5)"
            137 -> "GATT authentication failure (status 137)"
            BluetoothGatt.GATT_FAILURE, 133 -> "Generic GATT error (status 133)"
            else -> "GATT status $status"
        }
    }
}
