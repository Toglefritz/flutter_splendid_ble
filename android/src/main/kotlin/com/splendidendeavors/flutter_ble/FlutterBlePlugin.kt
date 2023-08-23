package com.splendidendeavors.flutter_ble

import BluetoothAdapterHandler
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanSettings
import android.os.Build
import androidx.annotation.RequiresApi
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

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_ble")
        bleScannerHandler = BleScannerHandler(channel, flutterPluginBinding.applicationContext)
        channel.setMethodCallHandler(this)
        bluetoothAdapterHandler = BluetoothAdapterHandler(flutterPluginBinding.applicationContext)
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

                val scanFilters = filtersList?.map { createScanFilterFromMap(it) }
                val scanSettings = settingsMap?.let { createScanSettingsFromMap(it) }

                bleScannerHandler.startScan(scanFilters, scanSettings)
                result.success(null)
            }

            "stopScan" -> bleScannerHandler.stopScan()

            // Throw an exception if an unknown method name is received
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    // Creates a ScanFilter object from the given map representation.
    //
    // This function is responsible for extracting relevant properties from the map  and
    // constructing a corresponding ScanFilter instance.
    //
    // @param filterMap The map containing the filter properties.
    // @return A ScanFilter instance corresponding to the given map.
    private fun createScanFilterFromMap(filterMap: Map<String, Any>): ScanFilter {
        val builder = ScanFilter.Builder()

        // Extract properties from the filterMap and apply them to the builder
        filterMap["deviceName"]?.let { builder.setDeviceName(it as String) }
        filterMap["deviceAddress"]?.let { builder.setDeviceAddress(it as String) }
        filterMap["manufacturerData"]?.let {
            val manufacturerId = (it as Map<*, *>)["manufacturerId"] as Int
            val manufacturerData = (it["manufacturerData"] as? String)?.toByteArray()
            val manufacturerDataMask = (it["manufacturerDataMask"] as? String)?.toByteArray()
            if (manufacturerData != null) {
                builder.setManufacturerData(manufacturerId, manufacturerData, manufacturerDataMask)
            }
        }
        // ... Add other properties as needed

        return builder.build()
    }

    // Creates a ScanSettings object from the given map representation.
    //
    // This function is responsible for extracting relevant properties from the map and
    // constructing a corresponding ScanSettings instance.
    //
    // @param settingsMap The map containing the settings properties.
    // @return A ScanSettings instance corresponding to the given map.
    @RequiresApi(Build.VERSION_CODES.O)
    private fun createScanSettingsFromMap(settingsMap: Map<String, Any>?): ScanSettings {
        val builder = ScanSettings.Builder()

        // Extract properties from the settingsMap and apply them to the builder
        settingsMap?.get("scanMode")?.let { builder.setScanMode(it as Int) }
        settingsMap?.get("reportDelayMillis")?.let { builder.setReportDelay(it as Long) }
        settingsMap?.get("matchMode")?.let { builder.setMatchMode(it as Int) }
        settingsMap?.get("callbackType")?.let { builder.setCallbackType(it as Int) }
        settingsMap?.get("numOfMatches")?.let { builder.setNumOfMatches(it as Int) }
        settingsMap?.get("legacy")?.let { builder.setLegacy(it as Boolean) }
        settingsMap?.get("phy")?.let { builder.setPhy(it as Int) }
        // ... Add other properties as needed

        return builder.build()
    }

}
