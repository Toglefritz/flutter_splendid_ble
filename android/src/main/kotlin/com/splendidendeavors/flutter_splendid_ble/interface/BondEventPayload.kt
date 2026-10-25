package com.splendidendeavors.flutter_splendid_ble.`interface`

import android.bluetooth.BluetoothDevice

/**
 * A normalized, platform-agnostic classification of a BLE bonding failure.
 *
 * Mirrors the Dart `BleBondFailureCategory` enum. The [identifier] values must stay in sync with the Dart enum's
 * identifiers so that the category round-trips across the method channel.
 */
enum class BondFailureCategory(val identifier: String) {
    AUTHENTICATION_FAILURE("authenticationFailure"),
    AUTHENTICATION_REJECTED("authenticationRejected"),
    AUTHENTICATION_TIMEOUT("authenticationTimeout"),
    REMOTE_DEVICE_DOWN("remoteDeviceDown"),
    REMOVED("removed"),
    UNKNOWN("unknown"),
}

/**
 * The bonding states reported to the Dart side.
 *
 * The [identifier] values must stay in sync with the Dart `BleBondState` enum identifiers so that the state
 * round-trips across the method channel. [FAILED] is a synthetic state (Android itself only reports NONE/BONDING/
 * BONDED) that this plugin derives when a bond transitions back to NONE carrying an unbond reason — see
 * [BondEventPayload] for how that distinction is made.
 */
enum class BondState(val identifier: String) {
    NONE("none"),
    BONDING("bonding"),
    BONDED("bonded"),
    FAILED("failed"),
    UNKNOWN("unknown"),
}

/**
 * Builds the method channel payloads that describe BLE bonding lifecycle updates and normalizes Android unbond reason
 * codes into a cross-platform [BondFailureCategory].
 *
 * ## Why this exists
 *
 * Bonding is performed by the Android operating system, not by this plugin, but Android broadcasts rich detail about
 * what the OS is doing through `ACTION_BOND_STATE_CHANGED`: the new bond state and, on failure, an unbond reason code.
 * This object centralizes construction of the `bleBondState_<deviceAddress>` method channel call's argument map so that
 * every bonding update emits a consistent, richly-detailed payload rather than a bare state string. Normalizing the raw
 * reason code here lets the Dart layer branch on a single [BondFailureCategory] across all platforms.
 *
 * This mirrors [ConnectionEventPayload] for the connection lifecycle.
 *
 * ## Payload contract
 *
 * Every bonding update sends a `Map<String, Any?>` with:
 *
 * * `state` — the lowercase [BondState] name (`"none"`, `"bonding"`, `"bonded"`, `"failed"`).
 * * `platform` — always `"android"`; lets the Dart side interpret `errorCode`/`errorDomain`.
 * * `category` — the [BondFailureCategory] identifier, present only for failure payloads.
 * * `errorCode` — the raw unbond reason integer, present only for failure payloads.
 * * `errorDomain` — always `"android_bond"` for failures.
 * * `errorDescription` — a short human-readable label for known reason codes, when available.
 */
object BondEventPayload {

    /** The host platform identifier sent in every bonding payload from this plugin. */
    private const val PLATFORM: String = "android"

    /** The error domain reported for all Android unbond reason codes. */
    private const val ERROR_DOMAIN: String = "android_bond"

    /**
     * The sentinel value used by `BluetoothDevice.EXTRA_REASON` when no reason was supplied.
     *
     * `android.bluetooth.BluetoothDevice.UNBOND_REASON_*` constants are `@hide` in the public SDK, so the relevant
     * integer values are inlined here. These values have been stable across the Android platform for many releases.
     */
    private const val UNBOND_REASON_AUTH_FAILED: Int = 1
    private const val UNBOND_REASON_AUTH_REJECTED: Int = 2
    private const val UNBOND_REASON_AUTH_CANCELED: Int = 3
    private const val UNBOND_REASON_REMOTE_DEVICE_DOWN: Int = 4
    private const val UNBOND_REASON_DISCOVERY_IN_PROGRESS: Int = 5
    private const val UNBOND_REASON_AUTH_TIMEOUT: Int = 6
    private const val UNBOND_REASON_REPEATED_ATTEMPTS: Int = 7
    private const val UNBOND_REASON_REMOTE_AUTH_CANCELED: Int = 8
    private const val UNBOND_REASON_REMOVED: Int = 9

    /** The value `EXTRA_REASON` carries when the broadcast included no reason extra. */
    const val REASON_NONE: Int = -1

    /**
     * Builds the payload for a non-failure bonding update (no error detail attached).
     *
     * Use this for [BondState.NONE], [BondState.BONDING], and [BondState.BONDED].
     *
     * @param state The bonding state to report.
     * @return A map suitable for the `arguments` of the `bleBondState_<deviceAddress>` method channel call.
     */
    fun success(state: BondState): Map<String, Any?> {
        return mapOf(
            "state" to state.identifier,
            "platform" to PLATFORM,
        )
    }

    /**
     * Builds the payload for a bonding failure, attaching normalized and raw error detail derived from the unbond
     * [reason] code.
     *
     * @param reason The raw unbond reason integer from `ACTION_BOND_STATE_CHANGED` (`BluetoothDevice.EXTRA_REASON`).
     * @return A map suitable for the `arguments` of the `bleBondState_<deviceAddress>` method channel call.
     */
    fun failure(reason: Int): Map<String, Any?> {
        return mapOf(
            "state" to BondState.FAILED.identifier,
            "platform" to PLATFORM,
            "category" to categorize(reason).identifier,
            "errorCode" to reason,
            "errorDomain" to ERROR_DOMAIN,
            "errorDescription" to describe(reason),
        )
    }

    /**
     * Maps an Android bond-state integer (`BluetoothDevice.BOND_*`) to the corresponding [BondState] identifier for a
     * successful (non-failure) transition.
     *
     * @param bondState One of `BluetoothDevice.BOND_NONE`, `BOND_BONDING`, or `BOND_BONDED`.
     * @return The matching [BondState]; [BondState.UNKNOWN] for unrecognized values.
     */
    fun stateFor(bondState: Int): BondState {
        return when (bondState) {
            BluetoothDevice.BOND_NONE -> BondState.NONE
            BluetoothDevice.BOND_BONDING -> BondState.BONDING
            BluetoothDevice.BOND_BONDED -> BondState.BONDED
            else -> BondState.UNKNOWN
        }
    }

    /**
     * Whether a transition to `BOND_NONE` carrying the given [reason] represents a genuine bonding failure.
     *
     * Android reports both a deliberate unbond (reason [REASON_NONE], e.g. the user removed the device or no bond was
     * ever attempted) and a failed bond attempt as a transition to `BOND_NONE`. Only the latter carries a meaningful
     * reason code, so a reason other than [REASON_NONE] is treated as a failure.
     *
     * @param reason The unbond reason extra from the broadcast.
     * @return `true` when the transition should be reported as [BondState.FAILED] rather than [BondState.NONE].
     */
    fun isFailureReason(reason: Int): Boolean {
        return reason != REASON_NONE
    }

    /**
     * Normalizes a raw unbond reason code into a [BondFailureCategory].
     *
     * Reason codes that are not specifically mapped resolve to [BondFailureCategory.UNKNOWN]; the raw code remains
     * available on the payload for deeper inspection on the Dart side.
     *
     * @param reason The raw unbond reason integer.
     * @return The normalized failure category.
     */
    private fun categorize(reason: Int): BondFailureCategory {
        return when (reason) {
            UNBOND_REASON_AUTH_FAILED -> BondFailureCategory.AUTHENTICATION_FAILURE
            UNBOND_REASON_AUTH_REJECTED, UNBOND_REASON_REMOTE_AUTH_CANCELED ->
                BondFailureCategory.AUTHENTICATION_REJECTED
            UNBOND_REASON_AUTH_TIMEOUT -> BondFailureCategory.AUTHENTICATION_TIMEOUT
            UNBOND_REASON_REMOTE_DEVICE_DOWN -> BondFailureCategory.REMOTE_DEVICE_DOWN
            UNBOND_REASON_AUTH_CANCELED, UNBOND_REASON_REMOVED -> BondFailureCategory.REMOVED
            else -> BondFailureCategory.UNKNOWN
        }
    }

    /**
     * Returns a short human-readable label for a known unbond reason code, or a generic label including the raw code
     * when it is not specifically recognized.
     *
     * @param reason The raw unbond reason integer.
     * @return A description string intended for logs and diagnostics.
     */
    private fun describe(reason: Int): String {
        return when (reason) {
            UNBOND_REASON_AUTH_FAILED -> "Authentication failed (reason 1)"
            UNBOND_REASON_AUTH_REJECTED -> "Authentication rejected by peer (reason 2)"
            UNBOND_REASON_AUTH_CANCELED -> "Authentication canceled (reason 3)"
            UNBOND_REASON_REMOTE_DEVICE_DOWN -> "Remote device down (reason 4)"
            UNBOND_REASON_DISCOVERY_IN_PROGRESS -> "Discovery in progress (reason 5)"
            UNBOND_REASON_AUTH_TIMEOUT -> "Authentication timeout (reason 6)"
            UNBOND_REASON_REPEATED_ATTEMPTS -> "Repeated attempts (reason 7)"
            UNBOND_REASON_REMOTE_AUTH_CANCELED -> "Remote authentication canceled (reason 8)"
            UNBOND_REASON_REMOVED -> "Bond removed (reason 9)"
            else -> "Unbond reason $reason"
        }
    }
}
