package com.splendidendeavors.flutter_ble.adapter

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * Manages the Bluetooth adapter on an Android device and communicates its status to the Dart side of a Flutter app.
 *
 * This class is responsible for managing the Bluetooth adapter's status on the Android device.
 * It can check the current status of the Bluetooth adapter, and also listen for changes to the adapter's status.
 * This allows the Dart side of a Flutter application to respond in real-time to changes in the Bluetooth adapter's status.
 *
 * The class uses Android's [BluetoothManager] to interact with the Bluetooth adapter and [EventChannel.EventSink] to communicate with the Dart side.
 *
 * @property channel MethodChannel used to send the [BluetoothStatus] to the Dart side.
 * @property context Android [Context] used to interact with system-level features like the Bluetooth adapter.
 *
 * @see checkBluetoothAdapterStatus for getting the current status of the Bluetooth adapter.
 * @see emitCurrentBluetoothStatus for listening to changes in the Bluetooth adapter's status.
 */
class BluetoothAdapterHandler(
    private val channel: MethodChannel,
    private val context: Context,
) {
    private val bluetoothManager: BluetoothManager =
        context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager

    /**
     * BroadcastReceiver for capturing changes in the Bluetooth adapter's status.
     *
     * This [BroadcastReceiver] listens for [BluetoothAdapter.ACTION_STATE_CHANGED] intents,
     * which are broadcast when the Bluetooth adapter on the device changes its state.
     * Upon receiving such an intent, the `onReceive` method triggers `emitCurrentBluetoothStatus`,
     * which then sends the current Bluetooth adapter status to the Dart side via the [channel].
     *
     * The [bluetoothStatusReceiver] is registered in the class initializer with a specific intent filter
     * to only listen for Bluetooth state changes, making it efficient and focused on its task.
     *
     * @see emitCurrentBluetoothStatus for the method that is called to send the updated status.
     */
    private val bluetoothStatusReceiver: BroadcastReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val action: String = intent!!.action!!
            if (BluetoothAdapter.ACTION_STATE_CHANGED == action) {
                emitCurrentBluetoothStatus()
            }
        }
    }

    init {
        val filter = IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED)
        context.registerReceiver(bluetoothStatusReceiver, filter)
        emitCurrentBluetoothStatus()  // Emit the current status when initialized
    }

    /**
     * Checks the status of the Bluetooth adapter on the device.
     *
     * This method retrieves the current state of the Bluetooth adapter using the BluetoothManager
     * and returns a value from the [BluetoothStatus] enumeration:
     *
     * - [BluetoothStatus.notAvailable]: Indicates that Bluetooth is not available on the device.
     * - [BluetoothStatus.enabled]: Indicates that Bluetooth is enabled and ready for connections.
     * - [BluetoothStatus.disabled]: Indicates that Bluetooth is disabled and not available for use.
     *
     * This method should be used to get the current adapter status at the time when the method is
     * called. However, because this method does not involve listening to or emitting values for
     * changes in the Bluetooth adapter status, the method will need to be called again each time
     * it becomes necessary to retrieve the Bluetooth adapter status. If is is advantageous to
     * listen for changes in the adapter status, use the `emitCurrentBluetoothStatus` method
     * instead.
     *
     * @return [BluetoothStatus] representing the current status of the Bluetooth adapter on the device.
     */
    fun checkBluetoothAdapterStatus(): BluetoothStatus {
        val bluetoothAdapter = bluetoothManager.adapter
        return when {
            bluetoothAdapter == null -> BluetoothStatus.notAvailable
            bluetoothAdapter.isEnabled -> BluetoothStatus.enabled
            else -> BluetoothStatus.disabled
        }
    }

    /**
     * Emits the current Bluetooth status to the Dart side.
     *
     * This method retrieves the current state of the Bluetooth adapter using the BluetoothManager
     * and sends a value to the Dart side via EventSink:
     *
     * - "notAvailable": Indicates that Bluetooth is not available on the device.
     * - "enabled": Indicates that Bluetooth is enabled and ready for connections.
     * - "disabled": Indicates that Bluetooth is disabled and not available for use.
     */
    fun emitCurrentBluetoothStatus() {
        val bluetoothAdapter = bluetoothManager.adapter
        val status = when {
            bluetoothAdapter == null -> "notAvailable"
            bluetoothAdapter.isEnabled -> "enabled"
            else -> "disabled"
        }

        // Invoke method on Flutter side
        channel.invokeMethod("adapterStateUpdated", status)
    }
}
