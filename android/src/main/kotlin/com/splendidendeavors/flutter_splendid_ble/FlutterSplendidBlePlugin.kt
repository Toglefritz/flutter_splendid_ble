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

/** FlutterSplendidBlePlugin */
class FlutterSplendidBlePlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel

    // The EventChannel that facilitates real-time communication between Flutter and native Android.
    //
    // This channel is used to send Bluetooth adapter status updates from native Android to Flutter,
    // allowing the Dart side to listen to a stream of status updates. This stream can then be used
    // in the business logic to respond to changes in the Bluetooth adapter status.
    //
    // The EventChannel is registered with the Flutter Engine during the plugin attachment process
    // in the `onAttachedToEngine` method.
    private lateinit var eventChannel: EventChannel

    // The BluetoothAdapterHandler checks the status of the Bluetooth adapter on the device.
    private lateinit var bluetoothAdapterHandler: BluetoothAdapterHandler

    /// The BleScannerHandler handles all methods related to scanning for nearby Bluetooth device.
    private lateinit var bleScannerHandler: BleScannerHandler

    /// The BleConnectorHandler handles all methods related to Bluetooth device connections.
    //private lateinit var bleConnectionHandler: BleConnectionHandler

    /// The BleDeviceInterface handles all methods related to writing to, reading from, and handling
    /// subscriptions to the Bluetooth characteristics of a connected Bluetooth peripheral.
    private lateinit var bleDeviceInterface: BleDeviceInterface

    /// The BluetoothPermissionsHandler handles all methods related to requesting and checking
    /// Bluetooth permissions on Android.
    private lateinit var bluetoothPermissionsHandler: BluetoothPermissionsHandler

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
                        // The actual implementation logic for subscribing to the characteristic
                        bleDeviceInterface.subscribeToCharacteristic(
                            deviceAddress,
                            characteristicUuid,
                            true
                        )
                        result.success(null)
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
                        // The actual implementation logic for subscribing to the characteristic
                        bleDeviceInterface.subscribeToCharacteristic(
                            deviceAddress,
                            characteristicUuid,
                            false
                        )
                        result.success(null)
                    } catch (e: Exception) {
                        result.error(
                            "SUBSCRIBE_ERROR",
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

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    // ActivityAware interface methods
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        bluetoothPermissionsHandler.setActivity(binding.activity)
        binding.addRequestPermissionsResultListener(bluetoothPermissionsHandler)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        bluetoothPermissionsHandler.setActivity(null)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        bluetoothPermissionsHandler.setActivity(binding.activity)
        binding.addRequestPermissionsResultListener(bluetoothPermissionsHandler)
    }

    override fun onDetachedFromActivity() {
        bluetoothPermissionsHandler.setActivity(null)
    }
}
