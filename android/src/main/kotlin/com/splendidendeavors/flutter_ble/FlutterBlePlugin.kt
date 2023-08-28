package com.splendidendeavors.flutter_ble

import BluetoothAdapterHandler
import android.os.Build
import androidx.annotation.RequiresApi
import com.splendidendeavors.flutter_ble.connector.BleConnectorHandler
import com.splendidendeavors.flutter_ble.scanner.BleScannerHandler

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.MethodChannel.MethodCallHandler

/** FlutterBlePlugin */
class FlutterBlePlugin : FlutterPlugin, MethodCallHandler {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel

    /// The BleScannerHandler handles all methods related to scanning for nearby Bluetooth device.
    private lateinit var bleScannerHandler: BleScannerHandler

    // The BluetoothAdapterHandler checks the status of the Bluetooth adapter on the device.
    private lateinit var bluetoothAdapterHandler: BluetoothAdapterHandler

    /// The BleConnectorHandler handles all methods related to Bluetooth device connections.
    private lateinit var bleConnectorHandler: BleConnectorHandler

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_ble")
        bleScannerHandler = BleScannerHandler(channel, flutterPluginBinding.applicationContext)
        channel.setMethodCallHandler(this)
        bluetoothAdapterHandler = BluetoothAdapterHandler(flutterPluginBinding.applicationContext)
        bleConnectorHandler = BleConnectorHandler(flutterPluginBinding.applicationContext, channel)
    }

    @RequiresApi(Build.VERSION_CODES.O)
    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "checkBluetoothAdapterStatus" -> {
                val status = bluetoothAdapterHandler.checkBluetoothAdapterStatus()
                result.success(status.name)
            }

            "startScan" -> {
                val filtersList = call.argument<List<Map<String, Any>>?>("filters")
                val settingsMap = call.argument<Map<String, Any>?>("settings")

                val scanFilters = filtersList?.map { bleScannerHandler.createScanFilterFromMap(it) }
                val scanSettings =
                    settingsMap?.let { bleScannerHandler.createScanSettingsFromMap(it) }

                bleScannerHandler.startScan(scanFilters, scanSettings)
                result.success(null)
            }

            "stopScan" -> bleScannerHandler.stopScan()

            "connect" -> {
                val deviceAddress = call.argument<String>("address")
                if (deviceAddress != null) {
                    bleConnectorHandler.connect(deviceAddress)
                    result.success(null)
                } else {
                    result.error("INVALID_ARGUMENT", "Device address cannot be null.", null)
                }
            }

            "disconnect" -> {
                bleConnectorHandler.disconnect()
                result.success(null)
            }

            "getCurrentConnectionState" -> {
                val deviceAddress = call.argument<String>("address")
                if (deviceAddress != null) {
                    val connectionState = bleConnectorHandler.getCurrentConnectionState(deviceAddress).lowercase()
                    result.success(connectionState)
                } else {
                    result.error("INVALID_ARGUMENT", "Device address cannot be null.", null)
                }
            }

            // Throw an exception if an unknown method name is received
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
