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
import android.os.ParcelUuid
import java.util.UUID

import android.util.Log

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

    /**
     * Set of device addresses that have been discovered during the current scan session.
     * This tracks which devices we've seen before to differentiate between initial advertisement
     * and scan response packets.
     */
    private val discoveredDevices: MutableSet<String> = mutableSetOf()

    /**
     * Stores partial advertisement data for devices that support scan responses.
     * The key is the device address, and the value contains the initial ScanResult.
     * This data is merged with scan response data before being emitted to Flutter.
     */
    private val partialAdvertisementData: MutableMap<String, ScanResult> = mutableMapOf()

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
            // Clear previous scan session data
            discoveredDevices.clear()
            partialAdvertisementData.clear()

            // Define a scan callback
            scanCallback = object : ScanCallback() {
                override fun onScanResult(callbackType: Int, result: ScanResult?) {
                    result?.let {
                        val resultServiceUuids: Set<UUID> = it.scanRecord?.serviceUuids?.map { parcelUuid -> parcelUuid.uuid }?.toSet() ?: emptySet()
                        val filterServiceUuids: Set<UUID> = scanFilters?.mapNotNull { filter ->
                            try {
                                val field: java.lang.reflect.Field = ScanFilter::class.java.getDeclaredField("mUuid")
                                field.isAccessible = true
                                (field.get(filter) as? ParcelUuid)?.uuid
                            } catch (e: Exception) {
                                null
                            }
                        }?.toSet() ?: emptySet()

                        val uuidFilterMatches: Boolean = filterServiceUuids.isEmpty() || resultServiceUuids.any { uuid -> uuid in filterServiceUuids }

                        if (!uuidFilterMatches) return

                        val deviceAddress: String = it.device.address
                        val isFirstDiscovery: Boolean = !discoveredDevices.contains(deviceAddress)

                        // Check if the device is connectable (may indicate scan response support)
                        val isConnectable: Boolean = it.isConnectable

                        if (isFirstDiscovery) {
                            // Mark this device as discovered
                            discoveredDevices.add(deviceAddress)

                            // If the device is connectable, it might send a scan response. Store the initial data and wait.
                            if (isConnectable) {
                                partialAdvertisementData[deviceAddress] = it
                                return // Don't emit yet - wait for potential scan response
                            }

                            // Device is not connectable, so no scan response is expected. Emit immediately.
                            emitDeviceDiscovery(it, scanFilters)
                        } else {
                            // This is a subsequent discovery - likely a scan response or duplicate advertisement

                            // Check if we have stored partial data (meaning we're waiting for scan response)
                            val partialData: ScanResult? = partialAdvertisementData[deviceAddress]
                            if (partialData != null) {
                                // This is the scan response. The ScanResult already contains merged data.
                                // Android automatically merges advertisement + scan response data in the ScanResult.
                                // Clean up the partial data storage
                                partialAdvertisementData.remove(deviceAddress)

                                // Emit the complete device information with merged data
                                emitDeviceDiscovery(it, scanFilters)
                            } else {
                                // We've seen this device before but aren't waiting for scan response
                                // This is a duplicate advertisement - emit it
                                emitDeviceDiscovery(it, scanFilters)
                            }
                        }
                    }
                }
            }

            // Start scanning, using different forms of the overloaded `startScan` method from the
            // `BluetoothLeScanner` class depending upon whether filters and/or settings for the scan
            // were provided.
            if (scanFilters != null && scanSettings != null) {
                bluetoothLeScanner.startScan(scanFilters, scanSettings, scanCallback)
            } else if (scanFilters != null) {
                bluetoothLeScanner.startScan(scanFilters, ScanSettings.Builder().build(), scanCallback)
            } else if (scanSettings != null) {
                bluetoothLeScanner.startScan(emptyList(), scanSettings, scanCallback)
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
     * Emits device discovery information to the Flutter/Dart side.
     *
     * This method formats the scan result's advertisement data and sends it through the method channel
     * to notify the Flutter side that a BLE device has been discovered.
     *
     * @param scanResult The discovered device's ScanResult containing complete advertisement data.
     * @param scanFilters The filters used for the scan (for UUID filtering).
     */
    private fun emitDeviceDiscovery(scanResult: ScanResult, scanFilters: List<ScanFilter>?) {
        // Extract the manufacturer data
        val manufacturerDataMap = scanResult.scanRecord?.manufacturerSpecificData
        val manufacturerData: String? = manufacturerDataMap?.let { dataMap ->
            val stringBuilder = StringBuilder()
            for (i in 0 until dataMap.size()) {
                val key: Int = dataMap.keyAt(i)
                val value: ByteArray? = dataMap[key]
                value?.joinToString(separator = "") { byte ->
                    "%02x".format(byte)
                }?.let { hexString ->
                    stringBuilder.append(hexString)
                }
            }
            stringBuilder.toString()
        }

        // Create a map with device details
        val deviceMap: Map<String, Any?> = mapOf(
            "name" to scanResult.device.name,
            "address" to scanResult.device.address,
            "rssi" to scanResult.rssi,
            "manufacturerData" to manufacturerData,
            "advertisedServiceUuids" to (scanResult.scanRecord?.serviceUuids?.map { parcelUuid -> parcelUuid.toString() } ?: emptyList()),
        )

        // Construct DiscoveredDevice
        val discoveredDevice = DiscoveredDevice(deviceMap)

        // Invoke method on Flutter side
        channel.invokeMethod("bleDeviceScanned", discoveredDevice.toMap())
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
            // Clear scan session data
            discoveredDevices.clear()
            partialAdvertisementData.clear()
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
    fun createScanFiltersFromMap(filterMap: Map<String, Any>): List<ScanFilter> {
        val baseBuilder: (UUID?) -> ScanFilter.Builder = { uuid ->
            val builder = ScanFilter.Builder()

            filterMap["deviceName"]?.let {
                builder.setDeviceName(it as String)
            }

            filterMap["deviceAddress"]?.let {
                builder.setDeviceAddress(it as String)
            }

            uuid?.let {
                builder.setServiceUuid(ParcelUuid(it))
            }

            filterMap["manufacturerData"]?.let {
                val manufacturerId = (it as Map<*, *>)["manufacturerId"] as Int
                val manufacturerData = (it["manufacturerData"] as? String)?.toByteArray()
                val manufacturerDataMask = (it["manufacturerDataMask"] as? String)?.toByteArray()
                if (manufacturerData != null) {
                    builder.setManufacturerData(manufacturerId, manufacturerData, manufacturerDataMask)
                }
            }

            builder
        }

        val serviceUuids = filterMap["serviceUuids"] as? List<*>

        return if (serviceUuids != null && serviceUuids.isNotEmpty()) {
            serviceUuids.mapNotNull {
                try {
                    val uuid = UUID.fromString(it as String)
                    baseBuilder(uuid).build()
                } catch (e: IllegalArgumentException) {
                    null
                }
            }
        } else {
            listOf(baseBuilder(null).build())
        }
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