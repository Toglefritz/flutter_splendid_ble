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
class BleConnectionHandler(private val context: Context, private val channel: MethodChannel) {
    /**
     * A map to store multiple BluetoothGatt instances for different devices.
     *
     * Each key-value pair represents a BluetoothGatt instance with the device's address
     * as the key and the BluetoothGatt instance as the value.
     */
    private val bluetoothGattMap: MutableMap<String, BluetoothGatt> = mutableMapOf()

    /**
     * Get the BluetoothGatt instance for a specific device address.
     *
     * @param deviceAddress The MAC address of the Bluetooth device.
     * @return The BluetoothGatt instance if a connection has been made, or null otherwise.
     */
    fun getBluetoothGatt(deviceAddress: String): BluetoothGatt? {
        return bluetoothGattMap[deviceAddress]
    }

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
         * This callback is invoked following a successful service discovery operation initiated on a GATT client represented by the parameter 'gatt'. Within the scope of this method, a map containing detailed information about the discovered services and their respective characteristics is constructed.
         *
         * The map is structured as follows:
         * - The keys are strings representing the UUIDs of the discovered services.
         * - The values are lists of maps, where each map represents a characteristic and contains the following keys:
         *   - "uuid": a string representing the UUID of the characteristic.
         *   - "properties": an integer representing the bitwise properties of the characteristic, which provide information about the operations supported by the characteristic (e.g., read, write, notify). The Flutter side should properly interpret these bitwise values to ascertain the specific properties supported by each characteristic.
         *   - "permissions": an integer representing the bitwise permissions of the characteristic, outlining the security permissions required for operations on the characteristic (e.g., whether bonding is needed). Again, proper interpretation of these bitwise values is expected on the Flutter side to determine the specific permissions set for each characteristic.
         *
         * Once constructed, this map is transmitted to the Flutter side through a MethodChannel, allowing the Flutter app to have detailed insights into the services and characteristics available on the remote device, thereby facilitating precise control and interaction with the Bluetooth peripheral.
         *
         * @param gatt The GATT client involved in the operation, providing an interface to interact with the Bluetooth GATT layer.
         * @param status The status of the service discovery operation, where BluetoothGatt.GATT_SUCCESS indicates a successful operation.
         */
        override fun onServicesDiscovered(gatt: BluetoothGatt, status: Int) {
            if (status == BluetoothGatt.GATT_SUCCESS) {
                mainHandler.post {
                    // Prepare a map to send to the Dart side
                    val servicesData = mutableMapOf<String, List<Map<String, Any>>>()

                    val services = gatt.services
                    services.forEach { service ->
                        val characteristics = service.characteristics.map { characteristic ->
                            mapOf(
                                "address" to gatt.device.address,
                                "uuid" to characteristic.uuid.toString(),
                                "properties" to characteristic.properties, // This will return an int representation of the properties
                                "permissions" to characteristic.permissions // This will return an int representation of the permissions
                            )
                        }
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