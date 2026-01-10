package com.splendidendeavors.flutter_splendid_ble

import android.bluetooth.BluetoothDevice
import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothManager
import com.splendidendeavors.flutter_splendid_ble.adapter.BluetoothAdapterHandler
import com.splendidendeavors.flutter_splendid_ble.`interface`.BleDeviceInterface
import com.splendidendeavors.flutter_splendid_ble.permissions.BluetoothPermissionsHandler
import com.splendidendeavors.flutter_splendid_ble.scanner.BleScannerHandler

import java.util.UUID

/**
 * FlutterSplendidBlePlugin is the main entry point for the Flutter Splendid BLE plugin on Android.
 *
 * This plugin provides a bridge between Flutter/Dart code and Android's native Bluetooth Low Energy
 * (BLE) functionality. It implements the FlutterPlugin interface to integrate with the Flutter engine,
 * MethodCallHandler to handle method calls from Dart, and ActivityAware to manage Android activity
 * lifecycle events.
 *
 * ## Architecture
 *
 * The plugin delegates specific BLE functionality to specialized handler classes:
 * - [BluetoothAdapterHandler]: Manages Bluetooth adapter status and state changes
 * - [BleScannerHandler]: Handles BLE device scanning operations
 * - [BleDeviceInterface]: Manages connections, service discovery, and characteristic operations
 * - [BluetoothPermissionsHandler]: Handles runtime Bluetooth permission requests
 *
 * ## Communication Channels
 *
 * The plugin uses two types of channels to communicate with Flutter:
 * - **MethodChannel** (`flutter_splendid_ble_central`): For bi-directional method calls
 * - **EventChannel** (`flutter_ble_events`): For streaming adapter status updates
 *
 * ## Lifecycle
 *
 * 1. [onAttachedToEngine]: Plugin initialization, handler creation, channel setup
 * 2. [onAttachedToActivity]: Activity binding, permission handler setup
 * 3. [onMethodCall]: Handles all method calls from Flutter
 * 4. [onDetachedFromActivity]: Activity cleanup
 * 5. [onDetachedFromEngine]: Plugin teardown, channel cleanup
 *
 * ## Method Handling
 *
 * All BLE operations from Flutter are routed through [onMethodCall], which delegates to the
 * appropriate handler based on the method name. The plugin supports:
 * - Adapter status checking and monitoring
 * - Permission requests and status checks
 * - Device scanning with filters and settings
 * - Device connection and disconnection
 * - Service discovery
 * - Characteristic read, write, and subscribe operations
 *
 * ## Error Handling
 *
 * All operations include proper error handling with descriptive error codes and messages that
 * are returned to the Flutter layer through MethodChannel.Result callbacks.
 *
 * ## Threading
 *
 * BLE operations are performed on the main thread when required by the Android BLE stack.
 * The handlers manage threading internally using Handler and Looper mechanisms.
 *
 * @see FlutterPlugin
 * @see MethodCallHandler
 * @see ActivityAware
 */
class FlutterSplendidBlePlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    /**
     * The MethodChannel that facilitates communication between Flutter and native Android.
     *
     * This channel is used for bi-directional method calls between Dart and Kotlin code.
     * All BLE operations initiated from Flutter are received through this channel, and
     * responses (including errors) are sent back through it.
     *
     * The channel is registered with the Flutter engine during plugin attachment and
     * cleaned up during detachment.
     *
     * @see onAttachedToEngine
     * @see onDetachedFromEngine
     */
    private lateinit var channel: MethodChannel

    /**
     * The EventChannel that facilitates real-time streaming from native Android to Flutter.
     *
     * This channel is used to send Bluetooth adapter status updates as a stream of events
     * from native Android to Flutter. The Dart side can listen to this stream to react to
     * changes in the Bluetooth adapter status (e.g., when Bluetooth is turned on or off).
     *
     * The EventChannel is registered with the Flutter Engine during the plugin attachment
     * process in [onAttachedToEngine].
     *
     * @see BluetoothAdapterHandler
     */
    private lateinit var eventChannel: EventChannel

    /**
     * Handler for Bluetooth adapter operations.
     *
     * This handler is responsible for:
     * - Checking the current status of the device's Bluetooth adapter
     * - Monitoring adapter state changes (powered on/off, etc.)
     * - Emitting adapter status updates through the EventChannel
     *
     * @see BluetoothAdapterHandler
     */
    private lateinit var bluetoothAdapterHandler: BluetoothAdapterHandler

    /**
     * Handler for BLE scanning operations.
     *
     * This handler manages:
     * - Starting and stopping BLE device scans
     * - Applying scan filters (by name, service UUID, etc.)
     * - Configuring scan settings (scan mode, callback type, match mode)
     * - Reporting discovered devices to Flutter
     *
     * @see BleScannerHandler
     */
    private lateinit var bleScannerHandler: BleScannerHandler

    /**
     * Interface for BLE device operations.
     *
     * This class handles all operations related to connected BLE devices:
     * - Establishing and terminating connections
     * - Discovering GATT services and characteristics
     * - Reading from and writing to characteristics
     * - Subscribing to and unsubscribing from characteristic notifications
     * - Managing the GATT connection lifecycle
     *
     * Critically, this class now implements proper write serialization to ensure that
     * only one write operation is in progress at a time per device, as required by the
     * BLE specification. Write operations are truly asynchronous - they complete when
     * the BLE stack confirms the write, not when the method returns.
     *
     * @see BleDeviceInterface
     */
    private lateinit var bleDeviceInterface: BleDeviceInterface

    /**
     * Handler for Bluetooth permission operations.
     *
     * This handler manages:
     * - Requesting runtime Bluetooth permissions on Android 12+ (BLUETOOTH_SCAN, BLUETOOTH_CONNECT)
     * - Checking current permission status
     * - Handling permission request results
     * - Managing Activity references needed for permission requests
     *
     * On Android 12 (API 31) and above, Bluetooth operations require runtime permissions.
     * This handler abstracts the permission request flow and reports results back to Flutter.
     *
     * @see BluetoothPermissionsHandler
     */
    private lateinit var bluetoothPermissionsHandler: BluetoothPermissionsHandler

    /**
     * Called when the plugin is attached to the Flutter engine.
     *
     * This method is invoked during plugin initialization and is responsible for:
     * 1. Creating and registering the MethodChannel for bi-directional communication
     * 2. Creating and registering the EventChannel for status updates
     * 3. Initializing all handler classes with necessary Android context
     * 4. Setting up the method call handler
     *
     * All handlers are initialized with references to the MethodChannel and application context
     * so they can communicate with Flutter and access Android system services.
     *
     * @param flutterPluginBinding Provides access to the binary messenger and application context
     */
    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_splendid_ble_central")
        channel.setMethodCallHandler(this)
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "flutter_ble_events")

        // Initialize BluetoothAdapterHandler
        bluetoothAdapterHandler =
            BluetoothAdapterHandler(channel, flutterPluginBinding.applicationContext)

        // Initialize BleScannerHandler
        bleScannerHandler = BleScannerHandler(channel, flutterPluginBinding.applicationContext)

        // Initialize BleConnectorHandler
        //bleConnectionHandler = BleConnectionHandler(flutterPluginBinding.applicationContext, channel)

        // Initialize the BleDeviceInterface
        bleDeviceInterface = BleDeviceInterface(channel, flutterPluginBinding.applicationContext)

        // Initialize the BluetoothPermissionsHandler
        bluetoothPermissionsHandler = BluetoothPermissionsHandler(channel, flutterPluginBinding.applicationContext)
    }

    /**
     * Handles method calls from Flutter/Dart code.
     *
     * This method acts as a router, dispatching method calls to the appropriate handler based on
     * the method name. All BLE operations initiated from Flutter pass through this method.
     *
     * ## Supported Methods
     *
     * **Adapter Operations:**
     * - `checkBluetoothAdapterStatus`: Returns current adapter status
     * - `emitCurrentBluetoothStatus`: Emits current status through EventChannel
     *
     * **Permission Operations:**
     * - `requestBluetoothPermissions`: Requests runtime Bluetooth permissions
     * - `emitCurrentPermissionStatus`: Emits current permission status
     *
     * **Scanning Operations:**
     * - `startScan`: Initiates BLE device scanning with optional filters and settings
     * - `stopScan`: Stops ongoing BLE device scan
     *
     * **Connection Operations:**
     * - `connect`: Establishes connection to a BLE device
     * - `disconnect`: Terminates connection to a BLE device
     * - `getCurrentConnectionState`: Returns current connection state for a device
     *
     * **GATT Operations:**
     * - `discoverServices`: Discovers GATT services on a connected device
     * - `readCharacteristic`: Reads value from a characteristic
     * - `writeCharacteristic`: Writes value to a characteristic (asynchronous)
     * - `subscribeToCharacteristic`: Enables notifications for a characteristic
     * - `unsubscribeFromCharacteristic`: Disables notifications for a characteristic
     *
     * ## Error Handling
     *
     * All methods include proper error handling. Errors are returned through the Result callback
     * with descriptive error codes and messages.
     *
     * ## Write Operation Special Behavior
     *
     * The `writeCharacteristic` method is unique in that it does NOT call result.success()
     * immediately. Instead, the Result is passed to BleDeviceInterface and completed later when
     * the actual BLE write operation finishes. This ensures proper async/await behavior in Dart.
     *
     * @param call The method call from Flutter, containing method name and arguments
     * @param result The result callback to complete with success or error
     */
    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "checkBluetoothAdapterStatus" -> {
                val status = bluetoothAdapterHandler.checkBluetoothAdapterStatus()
                result.success(status.name)
            }

            "emitCurrentBluetoothStatus" -> {
                bluetoothAdapterHandler.emitCurrentBluetoothStatus()
                result.success(null)
            }

            "requestBluetoothPermissions" -> {
                bluetoothPermissionsHandler.requestBluetoothPermissions(result)
            }

            "emitCurrentPermissionStatus" -> {
                bluetoothPermissionsHandler.emitCurrentPermissionStatus()
                result.success(null)
            }

            "getConnectedDevices" -> {
                result.notImplemented()
            }

            "startScan" -> {
                val filtersList = call.argument<List<Map<String, Any>>?>("filters")
                val settingsMap = call.argument<Map<String, Any>?>("settings")

                val scanFilters = filtersList?.flatMap { bleScannerHandler.createScanFiltersFromMap(it) }
                val scanSettings =
                    settingsMap?.let { bleScannerHandler.createScanSettingsFromMap(it) }

                bleScannerHandler.startScan(scanFilters, scanSettings)
                result.success(null)
            }

            "stopScan" -> bleScannerHandler.stopScan()

            "connect" -> {
                val deviceAddress = call.argument<String>("address")
                if (deviceAddress != null) {
                    bleDeviceInterface.connect(deviceAddress)
                    result.success(null)
                } else {
                    result.error("INVALID_ARGUMENT", "Device address cannot be null.", null)
                }
            }

            "discoverServices" -> {
                val deviceAddress = call.argument<String>("address")
                if (deviceAddress != null) {
                    bleDeviceInterface.discoverServices(deviceAddress)
                    result.success(null)
                } else {
                    result.error("INVALID_ARGUMENT", "Device address cannot be null.", null)
                }
            }

            "disconnect" -> {
                val deviceAddress = call.argument<String>("address")
                if (deviceAddress != null) {
                    bleDeviceInterface.disconnect(deviceAddress)
                    result.success(null)
                } else {
                    result.error("INVALID_ARGUMENT", "Device address cannot be null.", null)
                }
            }

            "getCurrentConnectionState" -> {
                val deviceAddress = call.argument<String>("address")
                if (deviceAddress != null) {
                    val connectionState =
                        bleDeviceInterface.getCurrentConnectionState(deviceAddress).lowercase()
                    result.success(connectionState)
                } else {
                    result.error("INVALID_ARGUMENT", "Device address cannot be null.", null)
                }
            }

            "writeCharacteristic" -> {
                val deviceAddress = call.argument<String>("address")
                val characteristicUuidStr = call.argument<String>("characteristicUuid")
                val stringValue = call.argument<String>("value")
                val writeType = call.argument<Int>("writeType")
                    ?: BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT

                if (deviceAddress != null && characteristicUuidStr != null && stringValue != null) {
                    val characteristicUuid = UUID.fromString(characteristicUuidStr)
                    val byteValue = stringValue.toByteArray()

                    try {
                        bleDeviceInterface.writeCharacteristic(
                            deviceAddress,
                            characteristicUuid,
                            byteValue,
                            writeType,
                            result // Pass result to complete later
                        )
                        // Don't call result.success here - it will be called in onCharacteristicWrite callback
                    } catch (e: Exception) {
                        result.error(
                            "WRITE_ERROR",
                            "Failed to write characteristic: ${e.message}",
                            null
                        )
                    }
                } else {
                    result.error(
                        "INVALID_ARGUMENT",
                        "Device address, characteristic UUID, or value cannot be null.",
                        null
                    )
                }
            }

            "readCharacteristic" -> {
                val characteristicUuidStr = call.argument<String>("characteristicUuid")
                val deviceAddress = call.argument<String>("address")

                if (characteristicUuidStr != null && deviceAddress != null) {
                    val characteristicUuid = UUID.fromString(characteristicUuidStr)

                    try {
                        bleDeviceInterface.readCharacteristic(
                            deviceAddress,
                            characteristicUuid,
                        )
                        result.success(null)
                    } catch (e: Exception) {
                        result.error(
                            "WRITE_ERROR",
                            "Failed to read characteristic: ${e.message}",
                            null
                        )
                    }
                } else {
                    result.error(
                        "INVALID_ARGUMENT",
                        "Characteristic read error: device address or characteristic UUID cannot be null.",
                        null
                    )
                }
            }

            "subscribeToCharacteristic" -> {
                val deviceAddress = call.argument<String>("address")
                val characteristicUuidStr = call.argument<String>("characteristicUuid")

                if (deviceAddress != null && characteristicUuidStr != null) {
                    val characteristicUuid = UUID.fromString(characteristicUuidStr)
                    try {
                        // Pass result to complete later when descriptor write finishes
                        bleDeviceInterface.subscribeToCharacteristic(
                            deviceAddress,
                            characteristicUuid,
                            true,
                            result // Result will be completed in onDescriptorWrite callback
                        )
                        // Don't call result.success here - it will be called in onDescriptorWrite callback
                    } catch (e: Exception) {
                        result.error(
                            "SUBSCRIBE_ERROR",
                            "Failed to subscribe to characteristic: ${e.message}",
                            null
                        )
                    }
                } else {
                    result.error(
                        "INVALID_ARGUMENT",
                        "Characteristic subscription error: device address or characteristic UUID cannot be null.",
                        null
                    )
                }
            }

            "unsubscribeFromCharacteristic" -> {
                val deviceAddress = call.argument<String>("address")
                val characteristicUuidStr = call.argument<String>("characteristicUuid")

                if (deviceAddress != null && characteristicUuidStr != null) {
                    val characteristicUuid = UUID.fromString(characteristicUuidStr)
                    try {
                        // Pass result to complete later when descriptor write finishes
                        bleDeviceInterface.subscribeToCharacteristic(
                            deviceAddress,
                            characteristicUuid,
                            false,
                            result // Result will be completed in onDescriptorWrite callback
                        )
                        // Don't call result.success here - it will be called in onDescriptorWrite callback
                    } catch (e: Exception) {
                        result.error(
                            "UNSUBSCRIBE_ERROR",
                            "Failed to unsubscribe from characteristic: ${e.message}",
                            null
                        )
                    }
                } else {
                    result.error(
                        "INVALID_ARGUMENT",
                        "Device address or characteristic UUID cannot be null.",
                        null
                    )
                }
            }

            // Throw an exception if an unknown method name is received
            else -> result.notImplemented()
        }
    }

    /**
     * Called when the plugin is detached from the Flutter engine.
     *
     * This method performs cleanup by removing the method call handler from the channel.
     * This prevents memory leaks and ensures the plugin can be properly garbage collected.
     *
     * @param binding The plugin binding being detached
     */
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    /**
     * Called when the plugin is attached to an Android Activity.
     *
     * This sets up the activity reference needed for permission requests and registers
     * the permission result listener.
     *
     * @param binding The activity plugin binding
     */
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        bluetoothPermissionsHandler.setActivity(binding.activity)
        binding.addRequestPermissionsResultListener(bluetoothPermissionsHandler)
    }

    /**
     * Called when the plugin is detached from its Activity due to configuration changes.
     *
     * Temporarily clears the activity reference. The activity will be reattached after
     * the configuration change completes.
     */
    override fun onDetachedFromActivityForConfigChanges() {
        bluetoothPermissionsHandler.setActivity(null)
    }

    /**
     * Called when the plugin is reattached to its Activity after configuration changes.
     *
     * Restores the activity reference and re-registers the permission result listener.
     *
     * @param binding The activity plugin binding
     */
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        bluetoothPermissionsHandler.setActivity(binding.activity)
        binding.addRequestPermissionsResultListener(bluetoothPermissionsHandler)
    }

    /**
     * Called when the plugin is permanently detached from its Activity.
     *
     * Clears the activity reference to prevent memory leaks.
     */
    override fun onDetachedFromActivity() {
        bluetoothPermissionsHandler.setActivity(null)
    }
}
