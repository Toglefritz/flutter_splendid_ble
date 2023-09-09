package com.splendidendeavors.flutter_ble.connector

import android.bluetooth.*
import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodChannel

/**
 * Handles Bluetooth Low Energy (BLE) connections for multiple devices.
 *
 * This class is responsible for establishing, maintaining, and tearing down
 * connections to multiple BLE devices. It provides methods to connect to and disconnect from
 * a BLE device. It also maintains the latest known state of each BLE connection and allows
 * querying these states.
 *
 * @property context The Android Context object. Required for obtaining system services and performing
 *                   BLE operations.
 * @property channel The MethodChannel used for communication with the Flutter side.
 */
class BleConnectorHandler(private val context: Context, private val channel: MethodChannel) {

    /**
     * A map to store multiple BluetoothGatt instances for different devices.
     *
     * Each key-value pair represents a BluetoothGatt instance with the device's address
     * as the key and the BluetoothGatt instance as the value.
     */
    private val bluetoothGattMap: MutableMap<String, BluetoothGatt> = mutableMapOf()

    /**
     * Callback object for changes in GATT client state and GATT server state.
     *
     * This object is responsible for handling various BluetoothGatt events that occur in response to
     * operations on the GATT server of the connected BLE device. It listens to events such as changes
     * in connection state, service discovery completion, characteristic read/write, and more.
     */
    private val gattCallback = object : BluetoothGattCallback() {
        /**
         * Handler to execute logic on the main thread.
         *
         * BluetoothGattCallbacks can be invoked on different threads. The MethodChannel, however,
         * requires all interactions to be done on the main thread. This handler ensures that.
         */
        val mainHandler = Handler(Looper.getMainLooper())

        /**
         * Called when the connection state of the GATT server changes.
         *
         * This method is invoked when the GATT server connection state changes between the device and
         * the remote BLE device we're connected to. States include CONNECTED, DISCONNECTED,
         * CONNECTING, and DISCONNECTING. This method maps those states to a ConnectionState enum and
         * forwards it to the Flutter side using the MethodChannel.
         *
         * @param gatt The GATT client.
         * @param status The status of the operation. BluetoothGatt.GATT_SUCCESS if the operation succeeds.
         * @param newState The new state, can be one of BluetoothProfile.STATE_* constants.
         */
        override fun onConnectionStateChange(gatt: BluetoothGatt, status: Int, newState: Int) {
            mainHandler.post {
                val state = when (newState) {
                    BluetoothProfile.STATE_CONNECTED -> ConnectionState.CONNECTED
                    BluetoothProfile.STATE_DISCONNECTED -> ConnectionState.DISCONNECTED
                    BluetoothProfile.STATE_CONNECTING -> ConnectionState.CONNECTING
                    BluetoothProfile.STATE_DISCONNECTING -> ConnectionState.DISCONNECTING
                    else -> ConnectionState.UNKNOWN
                }
                channel.invokeMethod("bleConnectionState_${gatt.device.address}", state.name)
            }
        }

        /**
         * Called when services have been discovered on the remote device.
         *
         * After a successful service discovery operation, this method is invoked to handle the newly
         * discovered services and their characteristics. A map is built that contains the service UUIDs
         * and their corresponding characteristics. This map is sent to the Flutter side using the
         * MethodChannel for further processing.
         *
         * @param gatt The GATT client involved in the operation.
         * @param status The status of the operation. BluetoothGatt.GATT_SUCCESS if the operation succeeds.
         */
        override fun onServicesDiscovered(gatt: BluetoothGatt, status: Int) {
            if (status == BluetoothGatt.GATT_SUCCESS) {
                mainHandler.post {
                    // Prepare a map to send to the Dart side
                    val servicesData = mutableMapOf<String, List<String>>()
                    val services = gatt.services

                    services.forEach { service ->
                        val characteristics = service.characteristics.map { it.uuid.toString() }
                        servicesData[service.uuid.toString()] = characteristics
                    }

                    // Notify the Flutter side
                    channel.invokeMethod(
                        "bleServicesDiscovered_${gatt.device.address}",
                        servicesData
                    )
                }
            }
        }
    }

    /**
     * Initiates a connection to a Bluetooth Low Energy (BLE) device.
     *
     * @param deviceAddress The Bluetooth address of the device to connect.
     */
    fun connect(deviceAddress: String) {
        val bluetoothManager =
            context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        val device = bluetoothManager.adapter.getRemoteDevice(deviceAddress)
        try {
            val gatt = device.connectGatt(context, false, gattCallback)
            bluetoothGattMap[deviceAddress] = gatt
        } catch (e: SecurityException) {
            channel.invokeMethod(
                "error",
                "Required Bluetooth permissions are missing: ${e.message}"
            )
        }

    }

    /**
     * Disconnects from a connected Bluetooth Low Energy (BLE) device.
     *
     * @param deviceAddress The Bluetooth address of the device to disconnect.
     */
    fun disconnect(deviceAddress: String) {
        try {
            bluetoothGattMap[deviceAddress]?.disconnect()
            bluetoothGattMap.remove(deviceAddress)
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
     * @param deviceAddress The Bluetooth address of the device whose connection state needs to be determined.
     *
     * @return A string representation of the connection state.
     */
    fun getCurrentConnectionState(deviceAddress: String): String {
        val bluetoothManager =
            context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        try {
            val connectedDevices = bluetoothManager.getDevicesMatchingConnectionStates(
                BluetoothProfile.GATT,
                intArrayOf(
                    BluetoothProfile.STATE_CONNECTED,
                    BluetoothProfile.STATE_CONNECTING,
                    BluetoothProfile.STATE_DISCONNECTING,
                    BluetoothProfile.STATE_DISCONNECTED
                )
            )

            val targetDevice = connectedDevices.find { it.address == deviceAddress }

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

    /**
     * Initiates manual discovery of GATT services and their characteristics.
     *
     * This method invokes the `discoverServices` method on the BluetoothGatt instance
     * to initiate service and characteristic discovery. Service discovery is an essential step
     * for learning the capabilities of the remote BLE device, represented as a hierarchy of
     * services and characteristics.
     *
     * Typically, this method is called after a successful connection to the remote BLE device,
     * especially if the initial connection was made without service discovery.
     */
    fun discoverServices(deviceAddress: String) {
        val bluetoothGatt: BluetoothGatt? = bluetoothGattMap[deviceAddress]

        try {
            // Check if BluetoothGatt instance exists; if not, service discovery can't proceed
            if (bluetoothGatt == null) {
                channel.invokeMethod(
                    "error",
                    "BluetoothGatt instance is null; can't discover services"
                )
                return
            }

            // Initiate service discovery
            val success = bluetoothGatt.discoverServices()

            // Check if the service discovery initiation was successful
            if (!success) {
                channel.invokeMethod("error", "Failed to start service discovery")
            }
        } catch (e: SecurityException) {
            channel.invokeMethod(
                "error",
                "Required Bluetooth permissions are missing: ${e.message}"
            )
        }
    }
}