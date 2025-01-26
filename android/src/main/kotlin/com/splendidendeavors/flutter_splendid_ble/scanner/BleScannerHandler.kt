package com.splendidendeavors.flutter_splendid_ble.scanner

import android.bluetooth.BluetoothManager
import android.bluetooth.le.BluetoothLeScanner
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.os.Build
import androidx.annotation.RequiresApi
import io.flutter.plugin.common.MethodChannel

/**
 * The `BleScannerHandler` class is responsible for managing Bluetooth Low Energy (BLE) scanning
 * operations on Android.
 *
 * This class interacts with the Android BLE APIs to initiate, manage, and stop scanning for BLE
 * devices within range.
 *
 * Key functionalities include:
 *
 *  -   `startScan`: Initiates the scanning process, collecting information about discovered
 *      devices and sending them to the Flutter side via a method channel.
 *  -   `stopScan`: Stops the ongoing scanning process, if any.
 *
 * Here's an overview of the process:
 *
 *  -   During initialization, it sets up the `BluetoothLeScanner` using the Android Bluetooth
 *      services.
 *  -   The `startScan` method begins the scanning process, defining a callback that handles
 *      discovered devices.
 *  -   The `stopScan` method stops the scanning process using the previously defined callback.
 *  -   Additional BLE-related methods can be added to this class as needed.
 *
 * This class encapsulates the scanning functionality, providing a clean and organized way to
 * manage BLE scanning without cluttering other parts of the system.
 *
 * Note: The scanning process requires specific permissions (such as location access) and enabled
 * Bluetooth on the device. These should be handled elsewhere in the application.
 */
class BleScannerHandler(private val channel: MethodChannel, activity: Context) {
    private val bluetoothLeScanner: BluetoothLeScanner
    private var scanCallback: ScanCallback? = null

    init {
        val bluetoothManager =
            activity.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        bluetoothLeScanner = bluetoothManager.adapter.bluetoothLeScanner
    }

    /**
     * Initiates the scanning process for nearby Bluetooth Low Energy (BLE) devices.
     *
     * The `startScan` method uses the Android `BluetoothLeScanner` to begin scanning for BLE
     * devices within range. Upon discovery of a device, the information is extracted, encapsulated
     * into a `DiscoveredDevice` object, and sent to the Flutter side via a method channel.
     *
     * Key information collected from each device includes:
     *  -    Name: The name of the BLE device.
     *  -    Address: The MAC address of the BLE device.
     *  -    RSSI: The Received Signal Strength Indicator, indicating the power level detected
     *       by the receiver.
     *
     * The scanning process continues until explicitly stopped by calling the `stopScan` method.
     *
     * Note: Ensure that the necessary permissions (e.g., location access) and Bluetooth are
     * enabled on the device, as these are prerequisites for scanning BLE devices on Android. If
     * permissions have not been granted, a `SecurityException` is thrown.
     */
    fun startScan(scanFilters: List<ScanFilter>? = null, scanSettings: ScanSettings? = null) {
        try {
            // Define a scan callback
            scanCallback = object : ScanCallback() {
                override fun onScanResult(callbackType: Int, result: ScanResult?) {
                    result?.let {
                        // Extract the manufacturer data
                        val manufacturerDataMap = it.scanRecord?.manufacturerSpecificData
                        val manufacturerData = manufacturerDataMap?.let { dataMap ->
                            val stringBuilder = StringBuilder()
                            for (i in 0 until dataMap.size()) {
                                val key = dataMap.keyAt(i)
                                val value = dataMap[key]
                                value?.joinToString(separator = "") { byte ->
                                    "%02x".format(byte)
                                }?.let { hexString ->
                                    stringBuilder.append(hexString)
                                }
                            }
                            stringBuilder.toString()
                        }


                        // Create a map with device details
                        val deviceMap = mapOf(
                            "name" to it.device.name,
                            "address" to it.device.address,
                            "rssi" to it.rssi,
                            "manufacturerData" to manufacturerData
                            // ... add other details as needed
                        )

                        // Construct DiscoveredDevice (either as an object or a map)
                        val discoveredDevice = DiscoveredDevice(deviceMap)

                        // Invoke method on Flutter side
                        channel.invokeMethod("bleDeviceScanned", discoveredDevice.toMap())
                    }
                }
            }

            // Start scanning, using different forms of the overloaded `startScan` method from the
            // `BluetoothLeScanner` class depending upon whether filters and/or settings for the scan
            // were provided.
            if (scanFilters != null && scanSettings != null) {
                bluetoothLeScanner.startScan(scanFilters, scanSettings, scanCallback)
            } else {
                bluetoothLeScanner.startScan(scanCallback)
            }
        } catch (e: SecurityException) {
            channel.invokeMethod(
                "error",
                "Required Bluetooth permissions are missing: ${e.message}"
            )
        }
    }

    /**
     * Stops scanning for nearby Bluetooth devices.
     *
     * This method stops the scanning process that was initiated with startScan().
     * It does so by invoking the stopScan() method on the bluetoothLeScanner instance
     * and providing the previously stored scan callback.
     *
     * Note: Ensure that the required Bluetooth permissions have been granted before making this
     * call. This should be the case since a scan should not be ongoing if Bluetooth permissions
     * were not granted. But, nonetheless, a `SecurityException` will be thrown if this method
     * is used without the necessary permissions.
     */
    fun stopScan() {
        try {
            if (scanCallback != null) {
                bluetoothLeScanner.stopScan(scanCallback)
                scanCallback = null // Clear the callback reference
            }
        } catch (e: SecurityException) {
            channel.invokeMethod(
                "error",
                "Required Bluetooth permissions are missing: ${e.message}"
            )
        }
    }

    /**
     * Creates a ScanFilter object from the given map representation.
     *
     * This function is responsible for extracting relevant properties from the map  and
     * constructing a corresponding ScanFilter instance.
     *
     * @param filterMap The map containing the filter properties.
     * @return A ScanFilter instance corresponding to the given map.
     */
    fun createScanFilterFromMap(filterMap: Map<String, Any>): ScanFilter {
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

        return builder.build()
    }

    /**
     * Creates a ScanSettings object from the given map representation.
     *
     * This function is responsible for extracting relevant properties from the map and
     * constructing a corresponding ScanSettings instance.
     *
     * @param settingsMap The map containing the settings properties.
     * @return A ScanSettings instance corresponding to the given map.
     */
    @RequiresApi(Build.VERSION_CODES.O)
    fun createScanSettingsFromMap(settingsMap: Map<String, Any>?): ScanSettings {
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