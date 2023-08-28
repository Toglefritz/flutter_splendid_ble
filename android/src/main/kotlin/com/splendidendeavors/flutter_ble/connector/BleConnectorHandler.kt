package com.splendidendeavors.flutter_ble.connector

import android.bluetooth.*
import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodChannel

/**
 * Handles Bluetooth Low Energy (BLE) connections.
 *
 * This class is responsible for establishing, maintaining, and tearing down
 * connections to BLE devices. It provides methods to connect to and disconnect from
 * a BLE device. It also maintains the latest known state of the BLE connection and allows
 * querying this state.
 *
 * @property context The Android Context object. Required for obtaining system services and performing
 *                   BLE operations.
 * @property channel The MethodChannel used for communication with the Flutter side.
 */
class BleConnectorHandler(private val context: Context, private val channel: MethodChannel) {
    /**
     * A BluetoothGatt instance representing a GATT server on a BLE device.
     *
     * BluetoothGatt is an Android representation of a GATT server on a BLE device,
     * providing a subset of Bluetooth GATT operations. This instance is created
     * upon a successful connection to a BLE device and is used for interactions
     * with that device.
     */
    private var bluetoothGatt: BluetoothGatt? = null

    /**
     * The Bluetooth address of the device to which the current connection is established
     * or is being established.
     *
     * This Bluetooth address uniquely identifies the remote device and is used for
     * future operations on the GATT server, represented by the [bluetoothGatt] object.
     */
    private lateinit var deviceAddress: String

    /**
     * Callback object for changes in GATT client state and GATT server state.
     *
     * This object is used to receive various BluetoothGatt events that occur in response to operations
     * on the GATT server of the connected BLE device. This includes events such as changes in the
     * connection state, service discovery completion, characteristic read/write, etc.
     *
     * Particularly, the `onConnectionStateChange` method is implemented to handle and notify the
     * Flutter side about changes in the BLE device's connection state. The state can be one of the
     * following: CONNECTED, DISCONNECTED, CONNECTING, and DISCONNECTING, which are encapsulated
     * in the [ConnectionState] enum.
     */
    private val gattCallback = object : BluetoothGattCallback() {
        // The invokeMethod function can only be used on the main thread, so ensure this
        // callback executes its logic on the main thread
        val mainHandler = Handler(Looper.getMainLooper())

        override fun onConnectionStateChange(gatt: BluetoothGatt, status: Int, newState: Int) {
            mainHandler.post {
                val state = when (newState) {
                    BluetoothProfile.STATE_CONNECTED -> ConnectionState.CONNECTED
                    BluetoothProfile.STATE_DISCONNECTED -> ConnectionState.DISCONNECTED
                    BluetoothProfile.STATE_CONNECTING -> ConnectionState.CONNECTING
                    BluetoothProfile.STATE_DISCONNECTING -> ConnectionState.DISCONNECTING
                    else -> ConnectionState.UNKNOWN
                }
                channel.invokeMethod("bleConnectionState", state.name)
            }
        }
    }

    /**
     * Initiates a connection to a Bluetooth Low Energy (BLE) device.
     *
     * This function initiates a BLE connection by calling `connectGatt` on the corresponding
     * `BluetoothDevice` object.
     */
    fun connect(deviceAddress: String) {
        this.deviceAddress = deviceAddress
        val bluetoothManager =
            context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        val device = bluetoothManager.adapter.getRemoteDevice(deviceAddress)
        try {
            bluetoothGatt = device.connectGatt(context, false, gattCallback)
        } catch (e: SecurityException) {
            channel.invokeMethod(
                "error",
                "Required Bluetooth permissions are missing: ${e.message}"
            )
        }
    }

    /**
     * Disconnects from the connected Bluetooth Low Energy (BLE) device.
     *
     * This function disconnects the device by calling `disconnect` on the `BluetoothGatt` object.
     */
    fun disconnect() {
        try {
            bluetoothGatt?.disconnect()
        } catch (e: SecurityException) {
            channel.invokeMethod(
                "error",
                "Required Bluetooth permissions are missing: ${e.message}"
            )
        }
    }

    /**
     * Gets the current connection state of a Bluetooth Low Energy (BLE) device by its Bluetooth address.
     *
     * This method uses the Android `BluetoothManager` to fetch a list of all devices that are currently
     * in any of the following states: CONNECTED, CONNECTING, DISCONNECTED, or DISCONNECTING.
     * It then checks if the device with the given address is present in that list. If so,
     * it fetches and returns the current connection state of that device.
     *
     * @param deviceAddress The Bluetooth address of the device whose connection state needs to be determined.
     *
     * @return A string representation of the connection state, as defined in the `ConnectionState` enum.
     * Possible values are "CONNECTED", "CONNECTING", "DISCONNECTED", "DISCONNECTING", and "UNKNOWN".
     */
    fun getCurrentConnectionState(deviceAddress: String): String {
        val bluetoothManager =
            context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager

        try {
            // Get a list of devices that are currently in a connected or connecting state.
            val connectedDevices = bluetoothManager.getDevicesMatchingConnectionStates(
                BluetoothProfile.GATT,
                intArrayOf(
                    BluetoothProfile.STATE_CONNECTED,
                    BluetoothProfile.STATE_CONNECTING,
                    BluetoothProfile.STATE_DISCONNECTING,
                    BluetoothProfile.STATE_DISCONNECTED
                )
            )

            // Find the device in the list with the specified address.
            val targetDevice = connectedDevices.find { it.address == deviceAddress }

            // Determine the connection state of the device.
            return if (targetDevice != null) {
                when (bluetoothManager.getConnectionState(targetDevice, BluetoothProfile.GATT)) {
                    BluetoothProfile.STATE_CONNECTED -> ConnectionState.CONNECTED.name
                    BluetoothProfile.STATE_DISCONNECTED -> ConnectionState.DISCONNECTED.name
                    BluetoothProfile.STATE_CONNECTING -> ConnectionState.CONNECTING.name
                    BluetoothProfile.STATE_DISCONNECTING -> ConnectionState.DISCONNECTING.name
                    else -> ConnectionState.UNKNOWN.name
                }
            } else {
                ConnectionState.UNKNOWN.name
            }
        } catch (e: SecurityException) {
            channel.invokeMethod(
                "error",
                "Required Bluetooth permissions are missing: ${e.message}"
            )
        }

        return ConnectionState.UNKNOWN.name
    }
}