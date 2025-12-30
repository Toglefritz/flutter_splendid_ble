package com.splendidendeavors.flutter_splendid_ble.`interface`

import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattDescriptor
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.annotation.RequiresApi
import io.flutter.plugin.common.MethodChannel
import java.lang.Exception
import java.util.UUID

/**
 * The BleDeviceInterface class provides an interface to interact with Bluetooth Low Energy (BLE)
 * devices.
 *
 * This class is crucial for initiating and maintaining a communication channel between Android and
 * BLE devices. It relies on Android's `BluetoothGattCallback` to receive various BLE-related
 * events.
 *
 * ## Background on BLE Operations:
 *
 * - **Connecting**: Establishes a GATT connection between the Android device and the remote BLE device.
 * - **Discovering Services**: Retrieves a list of available GATT services and their associated characteristics.
 * - **Reading and Writing Characteristics**: Performs read/write operations on the GATT characteristics.
 * - **Notifications and Indications**: Enables or disables notifications/indications for a GATT characteristic.
 *
 * ## Key Functions:
 *
 * - `connect(deviceAddress: String)`: Connects to the BLE device. Utilizes the `BluetoothManager` and `BluetoothAdapter` to establish a GATT connection.
 *
 * - `disconnect(deviceAddress: String)`: Disconnects the BLE device and removes it from the internal map. Again uses the `BluetoothManager` to manage this.
 *
 * - `getCurrentConnectionState(deviceAddress: String)`: Checks the current connection state of the BLE device, which could be connecting, connected, disconnecting, or disconnected.
 *
 * - `discoverServices(deviceAddress: String)`: Initiates the service discovery process. Calls `BluetoothGatt.discoverServices()`.
 *
 * - `writeCharacteristic(...)`: Writes data to a specified characteristic.
 *
 * - `readCharacteristic(deviceAddress: String, characteristicUuid: UUID)`: Reads data from a specified characteristic.
 *
 * - `subscribeToCharacteristic(...)`: Subscribes or unsubscribes from a characteristic's notifications.
 *
 * ## Callbacks:
 *
 * - `onConnectionStateChange(...)`: Triggered when the connection state changes. Communicates the state back to the Flutter side via a method channel.
 *
 * - `onServicesDiscovered(...)`: Triggered when GATT services are discovered. Sends the list of services and their characteristics back to the Flutter side.
 *
 * - `onCharacteristicRead(...)`: Triggered when a read operation is completed on a characteristic.
 *
 * - `onCharacteristicChanged(...)`: Triggered when a characteristic's value changes, often because the device notified the Android device of a change.
 *
 * ## Threading and Asynchrony:
 *
 * The class employs `Handler(Looper.getMainLooper())` to ensure that all operations that interact with the Flutter method channel happen on the main UI thread.
 *
 * ## Error Handling:
 *
 * All functions and callbacks are wrapped in try-catch blocks to gracefully handle errors, most commonly for security exceptions due to missing permissions.
 *
 * ## Permissions:
 *
 * The class expects that Bluetooth permissions (`BLUETOOTH`, `BLUETOOTH_ADMIN`, `BLUETOOTH_CONNECT`) and location permissions are granted in the Android Manifest.
 *
 * ## Overall BLE Connection Process as Reflected in Class Implementation:
 *
 * 1. Connection is initiated with `connect()`.
 * 2. `onConnectionStateChange()` confirms the connection.
 * 3. `discoverServices()` is called to discover GATT services.
 * 4. `onServicesDiscovered()` populates available services and characteristics.
 * 5. Read/Write operations are performed using `readCharacteristic()` and `writeCharacteristic()`.
 * 6. `subscribeToCharacteristic()` can be used to subscribe to notifications.
 * 7. Data updates are received in `onCharacteristicChanged()`.
 * 8. `disconnect()` is called to terminate the connection.
 * 9. `onConnectionStateChange()` confirms the disconnection.
 *
 * This class thus encapsulates all the necessary BLE operations in a comprehensive manner.
 */

class BleDeviceInterface(
    private val channel: MethodChannel,
    private val context: Context,
) : BluetoothGattCallback() {
    /**
     * A map to store multiple BluetoothGatt instances for different devices.
     *
     * Each key-value pair represents a BluetoothGatt instance with the device's address
     * as the key and the BluetoothGatt instance as the value. It is important to track the
     * BluetoothGatt instances are each device because, for each device, the same BluetoothGatt
     * instance must be used for all interactions.
     */
    private val bluetoothGattMap: MutableMap<String, BluetoothGatt> = mutableMapOf()

    /**
     * Tracks the currently pending write operation per device.
     * Only one write can be in progress at a time per device per BLE specification.
     */
    private val pendingWrites: MutableMap<String, PendingWrite> = mutableMapOf()

    /**
     * Tracks pending subscription operations awaiting confirmation via onDescriptorWrite.
     *
     * Key format: "deviceAddress:characteristicUuid"
     * Value: PendingSubscription containing operation details and Result to complete
     */
    private val pendingSubscriptions: MutableMap<String, PendingSubscription> = mutableMapOf()

    /**
     * Get the BluetoothGatt instance for a specific device address.
     *
     * @param deviceAddress The MAC address of the Bluetooth device.
     * @return The BluetoothGatt instance if a connection has been made, or null otherwise.
     */
    private fun getBluetoothGatt(deviceAddress: String): BluetoothGatt? {
        return bluetoothGattMap[deviceAddress]
    }

    /**
     * Generates a unique key for tracking pending subscription operations.
     *
     * This key combines the device address and characteristic UUID to uniquely identify
     * a subscription operation that is awaiting confirmation from the BLE stack.
     *
     * @param deviceAddress The MAC address of the Bluetooth device
     * @param characteristicUuid The UUID of the characteristic being subscribed to
     * @return A combined key string for map lookup: "deviceAddress:characteristicUuid"
     */
    private fun getSubscriptionKey(deviceAddress: String, characteristicUuid: UUID): String {
        return "$deviceAddress:$characteristicUuid"
    }

    /**
     * Handler to execute logic on the main thread.
     *
     * BluetoothGattCallbacks can be invoked on different threads. The MethodChannel, however,
     * requires all interactions to be done on the main thread. This handler ensures that.
     */
    private val mainHandler = Handler(Looper.getMainLooper())

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
        val deviceAddress = gatt.device.address

        mainHandler.post {
            val state = when (newState) {
                BluetoothProfile.STATE_CONNECTED -> ConnectionState.CONNECTED
                BluetoothProfile.STATE_DISCONNECTED -> {
                    // Clean up pending writes when disconnected
                    pendingWrites.remove(deviceAddress)

                    // Clean up pending subscriptions when disconnected
                    pendingSubscriptions.keys.removeAll { key -> key.startsWith("$deviceAddress:") }

                    ConnectionState.DISCONNECTED
                }
                BluetoothProfile.STATE_CONNECTING -> ConnectionState.CONNECTING
                BluetoothProfile.STATE_DISCONNECTING -> ConnectionState.DISCONNECTING
                else -> ConnectionState.UNKNOWN
            }

            channel.invokeMethod("bleConnectionState_$deviceAddress", state.name)
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
     *   - "address": the Bluetooth address of the Bluetooth device.
     *   - "uuid": a string representing the UUID of the characteristic.
     *   - "properties": an integer representing the bitwise properties of the characteristic, which provide information about the operations supported by the characteristic (e.g., read, write, notify). The Flutter side should properly interpret these bitwise values to ascertain the specific properties supported by each characteristic.
     *   - "permissions": an integer representing the bitwise permissions of the characteristic, outlining the security permissions required for operations on the characteristic (e.g., whether bonding is needed). Again, proper interpretation of these bitwise values is expected on the Flutter side to determine the specific permissions set for each characteristic.
     *
     * Once constructed, this map is transmitted to the Flutter side through a MethodChannel,
     * allowing the Flutter app to have detailed insights into the services and characteristics
     * available on the remote device, thereby facilitating precise control and interaction with
     * the Bluetooth peripheral.
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

    /**
     * Initiates a connection to a Bluetooth Low Energy (BLE) device.
     *
     * In Android's BLE programming, a BluetoothGattCallback is a critical component for
     * handling various BLE events, such as connection changes, service discovery, and
     * reading/writing to/from characteristics. This callback is usually provided when you
     * initiate a GATT (Generic Attribute Profile) connection using BluetoothDevice.connectGatt()
     * method.
     *
     * Therefore, the call to BluetoothDevice.connectGatt() in this method registers this class
     * to receive BluetoothGattCallback callbacks, which are critical for many of the functions
     * used in this class.
     *
     * @param deviceAddress The Bluetooth address of the device to connect.
     */
    fun connect(deviceAddress: String) {
        val bluetoothManager =
            context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        val device = bluetoothManager.adapter.getRemoteDevice(deviceAddress)
        try {
            val gatt = device.connectGatt(context, false, this)
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

            // Clean up pending writes for this device
            pendingWrites.remove(deviceAddress)

            // Clean up pending subscriptions for this device
            pendingSubscriptions.keys.removeAll { key -> key.startsWith("$deviceAddress:") }
        } catch (e: SecurityException) {
            channel.invokeMethod(
                "error",
                "Required Bluetooth permissions are missing: ${e.message}"
            )
        }
    }

    /**
     * Gets the current connection state of a Bluetooth Low Energy (BLE) device by its Bluetooth
     * address.
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
     * especially if the initial connection was made without service discovery. This is an
     * asynchronous operation. Once service discovery is completed, the
     * BluetoothGattCallback.onServicesDiscovered()  callback is triggered.
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

    /**
     * Write data to a specific BluetoothGattCharacteristic.
     *
     * This method initiates a write operation and stores the result callback to complete later
     * when the onCharacteristicWrite callback is received. This ensures the Dart await properly
     * waits for the actual BLE write to complete.
     *
     * The BLE specification requires that only one write can be in progress at a time per device.
     * If a write is already pending, this method returns an error.
     *
     * @param deviceAddress The address of the device to write to
     * @param characteristicUuid The UUID of the characteristic to be written
     * @param value The data to be written to the characteristic
     * @param writeType The type of write operation (default, no response, signed)
     * @param result The MethodChannel.Result to complete when the write finishes
     */
    fun writeCharacteristic(
        deviceAddress: String,
        characteristicUuid: UUID,
        value: ByteArray,
        writeType: Int = BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT,
        result: MethodChannel.Result
    ) {
        // Check if a write is already pending for this device
        if (pendingWrites.containsKey(deviceAddress)) {
            result.error(
                "WRITE_IN_PROGRESS",
                "A write operation is already in progress for device $deviceAddress. Please wait for it to complete.",
                null
            )
            return
        }

        val gatt = getBluetoothGatt(deviceAddress)
        if (gatt == null) {
            result.error(
                "DEVICE_NOT_FOUND",
                "No BluetoothGatt instance found for device address: $deviceAddress",
                null
            )
            return
        }

        val service = gatt.services.find {
            it.characteristics.any { char -> char.uuid == characteristicUuid }
        }
        val characteristic = service?.getCharacteristic(characteristicUuid)

        if (characteristic == null) {
            result.error(
                "CHARACTERISTIC_NOT_FOUND",
                "Characteristic with UUID $characteristicUuid not found.",
                null
            )
            return
        }

        // Store the pending write before initiating it
        pendingWrites[deviceAddress] = PendingWrite(deviceAddress, characteristicUuid, result)

        try {
            val writeSuccess: Boolean = if (android.os.Build.VERSION.SDK_INT >= 33) {
                // New method introduced in API 33
                val writeResult = gatt.writeCharacteristic(characteristic, value, writeType)
                writeResult == BluetoothGatt.GATT_SUCCESS
            } else {
                // Old method for API levels below 33
                @Suppress("DEPRECATION")
                characteristic.value = value
                characteristic.writeType = writeType
                @Suppress("DEPRECATION")
                gatt.writeCharacteristic(characteristic)
            }

            if (!writeSuccess) {
                // Write initiation failed
                pendingWrites.remove(deviceAddress)
                result.error(
                    "WRITE_FAILED",
                    "Failed to initiate write operation",
                    null
                )
            }
            // If write initiated successfully, result will be completed in onCharacteristicWrite callback
        } catch (e: SecurityException) {
            pendingWrites.remove(deviceAddress)
            result.error(
                "PERMISSION_ERROR",
                "Required Bluetooth permissions are missing: ${e.message}",
                null
            )
        } catch (e: Exception) {
            pendingWrites.remove(deviceAddress)
            result.error(
                "WRITE_ERROR",
                "Failed to write characteristic: ${e.message}",
                null
            )
        }
    }

    /**
     * Read the value of a specific BluetoothGattCharacteristic.
     *
     * @param deviceAddress The address of the device containing the characteristic.
     * @param characteristicUuid The UUID of the characteristic to be read.
     * @return The data read from the characteristic as a list of integers.
     */
    fun readCharacteristic(deviceAddress: String, characteristicUuid: UUID) {
        val gatt = getBluetoothGatt(deviceAddress)
        if (gatt == null) {
            channel.invokeMethod(
                "error",
                "No BluetoothGatt instance found for device address: $deviceAddress"
            )
        }

        val service =
            gatt?.services?.find { it.characteristics.any { char -> char.uuid == characteristicUuid } }
        val characteristic = service?.getCharacteristic(characteristicUuid)

        if (characteristic != null) {
            // TODO check if the characteristic has read properties and throw an error if if does not

            try {
                gatt.readCharacteristic(characteristic)
            } catch (e: SecurityException) {
                channel.invokeMethod(
                    "error",
                    "Required Bluetooth permissions are missing: ${e.message}"
                )
            } catch (e: Exception) {
                channel.invokeMethod(
                    "error",
                    "Failed to read characteristic, ${characteristicUuid}: ${e.message}"
                )
            }
        } else {
            channel.invokeMethod(
                "error",
                "Characteristic with UUID $characteristicUuid not found."
            )
        }
    }

    /**
     * Callback triggered as a result of a characteristic write operation.
     *
     * This callback completes the pending write operation by calling the stored MethodChannel.Result.
     * This ensures the Dart await properly waits for the actual BLE write to complete.
     *
     * @param gatt GATT client that performed the write operation
     * @param characteristic Characteristic that was written to the remote device
     * @param status GATT operation status (BluetoothGatt.GATT_SUCCESS if successful)
     */
    override fun onCharacteristicWrite(
        gatt: BluetoothGatt,
        characteristic: BluetoothGattCharacteristic,
        status: Int
    ) {
        super.onCharacteristicWrite(gatt, characteristic, status)

        val deviceAddress = gatt.device.address

        mainHandler.post {
            // Get and remove the pending write
            val pendingWrite = pendingWrites.remove(deviceAddress)

            if (pendingWrite != null) {
                if (status == BluetoothGatt.GATT_SUCCESS) {
                    // Complete the result successfully
                    pendingWrite.result.success(null)
                } else {
                    // Complete the result with an error
                    pendingWrite.result.error(
                        "WRITE_FAILED",
                        "Failed to write characteristic: GATT status $status",
                        null
                    )
                }
            }

            // Also send onCharacteristicWrite event for listeners
            if (status == BluetoothGatt.GATT_SUCCESS) {
                channel.invokeMethod(
                    "onCharacteristicWrite",
                    mapOf(
                        "deviceAddress" to deviceAddress,
                        "characteristicUuid" to characteristic.uuid.toString(),
                        "success" to true
                    )
                )
            } else {
                channel.invokeMethod(
                    "onCharacteristicWrite",
                    mapOf(
                        "deviceAddress" to deviceAddress,
                        "characteristicUuid" to characteristic.uuid.toString(),
                        "success" to false,
                        "error" to "Failed to write characteristic: GATT status $status"
                    )
                )
            }
        }
    }

    /**
     * Callback triggered as a result of a characteristic read operation.
     *
     * This callback is invoked when a read operation completes. The value must be read
     * from the characteristic object using the deprecated .value property for API < 33,
     * or it's provided directly in the newer callback for API 33+.
     *
     * @param gatt GATT client invoked readCharacteristic
     * @param characteristic Characteristic that was read from the associated remote device
     * @param status GATT operation status
     */
    override fun onCharacteristicRead(
        gatt: BluetoothGatt,
        characteristic: BluetoothGattCharacteristic,
        status: Int
    ) {
        super.onCharacteristicRead(gatt, characteristic, status)

        if (status == BluetoothGatt.GATT_SUCCESS) {
            @Suppress("DEPRECATION")
            val value = characteristic.value ?: byteArrayOf()
            val valueList = value.map { byte -> byte.toInt() }
            // The invokeMethod call must be done on the main thread
            mainHandler.post {
                channel.invokeMethod(
                    "onCharacteristicRead", mapOf(
                        "deviceAddress" to gatt.device?.address,
                        "characteristicUuid" to characteristic.uuid.toString(),
                        "value" to valueList
                    )
                )
            }
        } else {
            // The invokeMethod call must be done on the main thread
            mainHandler.post {
                channel.invokeMethod(
                    "error",
                    "Failed to read characteristic with UUID ${characteristic.uuid}"
                )
            }
        }
    }

    /**
     * Subscribes or unsubscribes to a specific BluetoothGattCharacteristic for notifications.
     *
     * This method toggles the state of notifications for a given characteristic on a Bluetooth Low Energy (BLE) device.
     * Enabling notifications allows a client application to listen for changes in the value of the characteristic,
     * while disabling notifications stops the client from receiving such updates.
     *
     * **Important: This method is asynchronous**. The Result is NOT completed immediately. Instead, it is stored
     * in the pendingSubscriptions map and will be completed later when the onDescriptorWrite callback confirms
     * that the subscription was successfully established (or failed). This ensures proper async/await behavior
     * on the Dart/Flutter side.
     *
     * The method achieves this by doing the following:
     * 1. Retrieves the BluetoothGatt object associated with the device address.
     * 2. Locates the service that contains the characteristic, based on its UUID.
     * 3. Activates or deactivates notifications at the Android OS level by calling `setCharacteristicNotification`.
     * 4. Locates the Client Characteristic Configuration Descriptor (CCCD) associated with the characteristic.
     * 5. Writes the appropriate value (ENABLE_NOTIFICATION_VALUE/DISABLE_NOTIFICATION_VALUE) to the descriptor.
     * 6. Stores the Result in pendingSubscriptions to be completed when onDescriptorWrite is invoked.
     *
     * Enabling notifications results in the `onCharacteristicChanged()` callback being invoked whenever the characteristic's value changes.
     * This provides a way for applications to react to real-time updates from the BLE device.
     *
     * @param deviceAddress The MAC address of the target BLE device.
     * @param characteristicUuid The UUID identifying the characteristic for which to toggle notifications.
     * @param enable A boolean indicating whether to enable (true) or disable (false) notifications.
     * @param result The MethodChannel.Result to complete when the subscription is confirmed (asynchronous)
     *
     * @throws SecurityException if required Bluetooth permissions are missing.
     *
     * @see BluetoothGatt
     * @see BluetoothGattCharacteristic
     * @see BluetoothGattDescriptor
     * @see onDescriptorWrite
     */
    fun subscribeToCharacteristic(
        deviceAddress: String,
        characteristicUuid: UUID,
        enable: Boolean,
        result: MethodChannel.Result
    ) {
        //val gatt = bleConnectionHandler.getBluetoothGatt(deviceAddress)
        val gatt = getBluetoothGatt(deviceAddress)
        if (gatt == null) {
            result.error(
                "NO_GATT",
                "No BluetoothGatt instance found for device address: $deviceAddress",
                null
            )
            return
        }

        val service =
            gatt.services.find { it.characteristics.any { char -> char.uuid == characteristicUuid } }
        val characteristic = service?.getCharacteristic(characteristicUuid)

        if (characteristic == null) {
            result.error(
                "CHARACTERISTIC_NOT_FOUND",
                "Characteristic with UUID $characteristicUuid not found.",
                null
            )
            return
        }

        try {
            // This call sets locally enables notifications from the characteristic
            // within the Android operating system
            gatt.setCharacteristicNotification(characteristic, enable)

            // Find the CCCD (Client Characteristic Configuration Descriptor) based on its UUID
            val descriptor = characteristic.getDescriptor(
                UUID.fromString("00002902-0000-1000-8000-00805f9b34fb")
            )

            if (descriptor == null) {
                result.error(
                    "CCCD_NOT_FOUND",
                    "CCCD descriptor not found for characteristic $characteristicUuid",
                    null
                )
                return
            }

            // Store the pending subscription before initiating the descriptor write
            val subscriptionKey = getSubscriptionKey(deviceAddress, characteristicUuid)
            pendingSubscriptions[subscriptionKey] = PendingSubscription(
                deviceAddress,
                characteristicUuid,
                enable,
                result
            )

            // Set the descriptor value to enable or disable notifications
            val descriptorValue = if (enable) {
                BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
            } else {
                BluetoothGattDescriptor.DISABLE_NOTIFICATION_VALUE
            }

            // Write the value to the descriptor to enable/disable notifications on the device
            // Use the appropriate API based on Android version
            val writeSuccess = if (android.os.Build.VERSION.SDK_INT >= 33) {
                gatt.writeDescriptor(descriptor, descriptorValue) == BluetoothGatt.GATT_SUCCESS
            } else {
                @Suppress("DEPRECATION")
                descriptor.value = descriptorValue
                @Suppress("DEPRECATION")
                gatt.writeDescriptor(descriptor)
            }

            // If the write failed immediately, complete the result with an error
            if (!writeSuccess) {
                pendingSubscriptions.remove(subscriptionKey)
                result.error(
                    "WRITE_FAILED",
                    "Failed to initiate descriptor write for characteristic $characteristicUuid",
                    null
                )
            }
            // If writeSuccess is true, the result will be completed in onDescriptorWrite callback
        } catch (e: SecurityException) {
            // Clean up pending subscription on error
            val subscriptionKey = getSubscriptionKey(deviceAddress, characteristicUuid)
            pendingSubscriptions.remove(subscriptionKey)

            result.error(
                "PERMISSION_DENIED",
                "Required Bluetooth permissions are missing: ${e.message}",
                null
            )
        }
    }

    /**
     * Callback triggered as a result of a descriptor write operation.
     *
     * This callback is particularly important for notification subscriptions, as enabling/disabling
     * notifications requires writing to the Client Characteristic Configuration Descriptor (CCCD).
     * This method completes any pending subscription operations by calling their stored Result callbacks.
     *
     * Note: The callback signature is the same across all API levels. What changed in API 33+
     * is the writeDescriptor method signature, not the callback signature.
     *
     * @param gatt GATT client that performed the descriptor write operation
     * @param descriptor Descriptor that was written to the remote device
     * @param status GATT operation status (BluetoothGatt.GATT_SUCCESS if successful)
     */
    override fun onDescriptorWrite(
        gatt: BluetoothGatt,
        descriptor: BluetoothGattDescriptor,
        status: Int
    ) {
        super.onDescriptorWrite(gatt, descriptor, status)

        val deviceAddress = gatt.device.address
        val characteristicUuid = descriptor.characteristic.uuid
        val subscriptionKey = getSubscriptionKey(deviceAddress, characteristicUuid)

        // Check if this descriptor write is for a pending subscription
        val pendingSubscription = pendingSubscriptions.remove(subscriptionKey)

        mainHandler.post {
            if (pendingSubscription != null) {
                // This is a subscription operation - complete the Result
                if (status == BluetoothGatt.GATT_SUCCESS) {
                    pendingSubscription.result.success(null)
                } else {
                    pendingSubscription.result.error(
                        "SUBSCRIPTION_FAILED",
                        "Failed to ${if (pendingSubscription.enable) "enable" else "disable"} notifications for characteristic $characteristicUuid: GATT status $status",
                        null
                    )
                }
            } else {
                // Not a tracked subscription operation, just log error if needed
                if (status != BluetoothGatt.GATT_SUCCESS) {
                    channel.invokeMethod(
                        "error",
                        "Failed to write descriptor ${descriptor.uuid}: GATT status $status"
                    )
                }
            }
        }
    }

    /**
     * This callback is invoked when the value of a BluetoothGattCharacteristic changes.
     *
     * It is triggered by a call to setCharacteristicNotification() for the characteristic
     * which changes you want to be notified about. The value must be read from the
     * characteristic object using the deprecated .value property.
     *
     * Note: The callback signature is the same across all API levels. What changed in API 33+
     * is how you access the value (directly vs. from characteristic.value).
     *
     * @param gatt The GATT client that connects to the GATT server on the Bluetooth device.
     * @param characteristic The characteristic whose value has changed.
     */
    override fun onCharacteristicChanged(
        gatt: BluetoothGatt,
        characteristic: BluetoothGattCharacteristic,
    ) {
        super.onCharacteristicChanged(gatt, characteristic)

        @Suppress("DEPRECATION")
        val value = characteristic.value ?: byteArrayOf()
        val valueList = value.map { byte -> byte.toInt() }
        val deviceAddress = gatt.device?.address

        // Create a map with updated characteristic details
        val characteristicMap = mapOf(
            "deviceAddress" to deviceAddress,
            "characteristicUuid" to characteristic.uuid.toString(),
            "value" to valueList
        )

        // Invoke method on Flutter side
        mainHandler.post {
            channel.invokeMethod("onCharacteristicChanged", characteristicMap)
        }
    }
}
