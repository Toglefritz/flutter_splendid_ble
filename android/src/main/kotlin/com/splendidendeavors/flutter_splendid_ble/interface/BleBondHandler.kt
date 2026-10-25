package com.splendidendeavors.flutter_splendid_ble.`interface`

import android.annotation.SuppressLint
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import io.flutter.plugin.common.MethodChannel

/**
 * Observes the operating-system-managed bonding process for BLE peripherals and forwards bonding lifecycle updates to
 * the Dart side.
 *
 * ## The operating system owns bonding
 *
 * Bonding (pairing) is performed entirely by the Android Bluetooth stack, not by this plugin. A Flutter app can
 * *provoke* bonding — by interacting with an encrypted characteristic, or by explicitly calling
 * `BluetoothDevice.createBond()` — but the pairing exchange itself is driven by the OS. What Android *does* expose,
 * however, is the `ACTION_BOND_STATE_CHANGED` broadcast, which reports every bond-state transition and, on failure,
 * an unbond reason code. This handler subscribes to that broadcast and translates it into the plugin's cross-platform
 * bonding diagnostics.
 *
 * ## How updates reach Dart
 *
 * Each bonding transition is sent to Dart as a `bleBondState_<deviceAddress>` method channel call whose arguments are
 * built by [BondEventPayload]. This mirrors how connection updates are delivered via `bleConnectionState_<address>`
 * and how adapter updates are delivered by `BluetoothAdapterHandler` — the same BroadcastReceiver pattern is used here.
 *
 * @property channel The [MethodChannel] used to send bonding updates to the Dart side.
 * @property context The Android [Context] used to register the broadcast receiver and resolve device addresses.
 *
 * @see BondEventPayload for the payload contract and reason-code normalization.
 */
class BleBondHandler(
    private val channel: MethodChannel,
    private val context: Context,
) {
    private val bluetoothManager: BluetoothManager =
        context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager

    private companion object {
        /**
         * The intent-extra key for the unbond reason on an `ACTION_BOND_STATE_CHANGED` broadcast.
         *
         * Equivalent to the `@hide` `BluetoothDevice.EXTRA_REASON` constant, inlined here because that constant is not
         * part of the public SDK. The string value is stable across Android platform releases.
         */
        const val EXTRA_REASON_KEY: String = "android.bluetooth.device.extra.REASON"
    }

    /**
     * Whether [bondStateReceiver] is currently registered with the Android system.
     *
     * Guards against double-registration (which would deliver duplicate broadcasts) and against unregistering a
     * receiver that was never registered (which throws). Registration is lazy: it happens the first time Dart begins
     * observing any device's bond state.
     */
    private var isReceiverRegistered: Boolean = false

    /**
     * BroadcastReceiver for capturing changes in a peripheral's bond state.
     *
     * Listens for [BluetoothDevice.ACTION_BOND_STATE_CHANGED] intents, which the Android Bluetooth stack broadcasts
     * whenever a device transitions between `BOND_NONE`, `BOND_BONDING`, and `BOND_BONDED`. For each intent, the new
     * bond state and (on failure) the unbond reason are extracted and forwarded to Dart via [emitBondState].
     *
     * @see emitBondState for the method that builds and sends the payload.
     */
    private val bondStateReceiver: BroadcastReceiver = object : BroadcastReceiver() {
        @SuppressLint("MissingPermission")
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action != BluetoothDevice.ACTION_BOND_STATE_CHANGED) {
                return
            }

            @Suppress("DEPRECATION")
            val device: BluetoothDevice =
                intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE) ?: return

            val newBondState: Int = intent.getIntExtra(
                BluetoothDevice.EXTRA_BOND_STATE,
                BluetoothDevice.ERROR,
            )
            // BluetoothDevice.EXTRA_REASON is a hidden (@hide) constant in the public SDK, so its underlying intent
            // key string is referenced directly. This value has been stable across Android releases and is the only
            // way to read the unbond reason that accompanies a failed bond attempt.
            val reason: Int = intent.getIntExtra(
                EXTRA_REASON_KEY,
                BondEventPayload.REASON_NONE,
            )

            emitBondState(device.address, newBondState, reason)
        }
    }

    /**
     * Begins observing bond-state changes for the device with the given [deviceAddress].
     *
     * The underlying `ACTION_BOND_STATE_CHANGED` broadcast is system-wide rather than per-device, so the first call
     * registers a single receiver that handles every device; subsequent calls are no-ops for registration. After
     * ensuring the receiver is active, the device's *current* bond state is emitted immediately so that a late
     * subscriber receives the present state without waiting for the next transition.
     *
     * @param deviceAddress The MAC address of the peripheral whose bond state should be observed.
     */
    fun observeBondState(deviceAddress: String) {
        ensureReceiverRegistered()
        emitCurrentBondState(deviceAddress)
    }

    /**
     * Registers [bondStateReceiver] with the system if it is not already registered.
     *
     * Registration is idempotent via [isReceiverRegistered]; the shared receiver stays registered for the lifetime of
     * the handler once the first device is observed.
     */
    private fun ensureReceiverRegistered() {
        if (isReceiverRegistered) {
            return
        }

        val filter = IntentFilter(BluetoothDevice.ACTION_BOND_STATE_CHANGED)
        context.registerReceiver(bondStateReceiver, filter)
        isReceiverRegistered = true
    }

    /**
     * Emits the current (synchronously-readable) bond state for the given [deviceAddress].
     *
     * Reads `BluetoothDevice.getBondState()` and forwards it as a non-failure bonding update. If the address cannot be
     * resolved to a [BluetoothDevice], an `unknown` state is reported so the Dart stream still receives an initial
     * value.
     *
     * @param deviceAddress The MAC address of the peripheral.
     */
    @SuppressLint("MissingPermission")
    private fun emitCurrentBondState(deviceAddress: String) {
        val device: BluetoothDevice? = runCatching {
            bluetoothManager.adapter?.getRemoteDevice(deviceAddress)
        }.getOrNull()

        if (device == null) {
            channel.invokeMethod(
                "bleBondState_$deviceAddress",
                BondEventPayload.success(BondState.UNKNOWN),
            )
            return
        }

        val bondState: Int = runCatching { device.bondState }
            .getOrDefault(BluetoothDevice.BOND_NONE)

        channel.invokeMethod(
            "bleBondState_$deviceAddress",
            BondEventPayload.success(BondEventPayload.stateFor(bondState)),
        )
    }

    /**
     * Builds and sends the bonding update for a single transition reported by the broadcast receiver.
     *
     * A transition to `BOND_NONE` is ambiguous on Android: it represents both a deliberate unbond (no reason, a clean
     * `none`) and a failed bond attempt (a reason code is present). [BondEventPayload.isFailureReason] disambiguates
     * the two, so a failed attempt is reported as `failed` with full reason detail while a clean unbond is reported as
     * `none`.
     *
     * @param deviceAddress The MAC address of the peripheral this transition concerns.
     * @param newBondState The new bond state (`BluetoothDevice.BOND_*`).
     * @param reason The unbond reason extra from the broadcast, or [BondEventPayload.REASON_NONE] if none was supplied.
     */
    private fun emitBondState(deviceAddress: String, newBondState: Int, reason: Int) {
        val payload: Map<String, Any?> =
            if (newBondState == BluetoothDevice.BOND_NONE &&
                BondEventPayload.isFailureReason(reason)
            ) {
                BondEventPayload.failure(reason)
            } else {
                BondEventPayload.success(BondEventPayload.stateFor(newBondState))
            }

        channel.invokeMethod("bleBondState_$deviceAddress", payload)
    }

    /**
     * Unregisters the broadcast receiver, if registered.
     *
     * Should be called when the plugin is detached from the Flutter engine to avoid leaking the receiver. Safe to call
     * when the receiver was never registered.
     */
    fun dispose() {
        if (isReceiverRegistered) {
            runCatching { context.unregisterReceiver(bondStateReceiver) }
            isReceiverRegistered = false
        }
    }
}
