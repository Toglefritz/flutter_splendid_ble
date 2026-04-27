package com.splendidendeavors.flutter_splendid_ble.scanner

import android.bluetooth.BluetoothManager
import android.bluetooth.le.BluetoothLeScanner
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
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
     * Handler bound to the main looper, used to post delayed fallback emissions for devices
     * that are connectable but whose scan response never arrives within the expected window.
     */
    private val mainHandler: Handler = Handler(Looper.getMainLooper())

    /**
     * How long to wait for a scan response before emitting the initial advertisement data
     * as-is. The scan response from a connectable device almost always arrives within a
     * single scan interval (tens of milliseconds), so 300 ms is a conservative upper bound
     * that avoids suppressing devices indefinitely.
     */
    private companion object {
        const val SCAN_RESPONSE_TIMEOUT_MS: Long = 300L
    }

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

    /**
     * Pending fallback runnables keyed by device address. Each runnable emits the buffered
     * initial advertisement for a connectable device if no scan response has arrived by the
     * time the timeout fires. Storing the runnables allows them to be cancelled when the scan
     * response does arrive before the timeout or when the scan is stopped.
     */
    private val pendingFallbackRunnables: MutableMap<String, Runnable> = mutableMapOf()

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
            // Cancel and clear any state from a previous scan session. Pending fallback
            // runnables are removed before clearing the partial data so the runnables do not
            // fire after the new scan starts.
            cancelAllPendingFallbacks()
            discoveredDevices.clear()
            partialAdvertisementData.clear()

            // Define a scan callback
            scanCallback = object : ScanCallback() {
                override fun onScanResult(callbackType: Int, result: ScanResult?) {
                    result?.let {
                        val resultServiceUuids: Set<UUID> = it.scanRecord?.serviceUuids
                            ?.map { parcelUuid -> parcelUuid.uuid }
                            ?.toSet() ?: emptySet()

                        val filterServiceUuids: Set<UUID> = scanFilters?.mapNotNull { filter ->
                            try {
                                val field: java.lang.reflect.Field =
                                    ScanFilter::class.java.getDeclaredField("mUuid")
                                field.isAccessible = true
                                (field.get(filter) as? ParcelUuid)?.uuid
                            } catch (e: Exception) {
                                null
                            }
                        }?.toSet() ?: emptySet()

                        val uuidFilterMatches: Boolean = filterServiceUuids.isEmpty() ||
                                resultServiceUuids.any { uuid -> uuid in filterServiceUuids }

                        if (!uuidFilterMatches) return

                        val deviceAddress: String = it.device.address
                        val isFirstDiscovery: Boolean = !discoveredDevices.contains(deviceAddress)

                        if (isFirstDiscovery) {
                            discoveredDevices.add(deviceAddress)

                            // Connectable devices can send a scan response packet that carries
                            // additional data (e.g. the complete local name or manufacturer
                            // payload). Buffer the initial result and schedule a fallback so
                            // the device is always emitted, even if the scan response never
                            // arrives within the timeout window.
                            if (it.isConnectable) {
                                partialAdvertisementData[deviceAddress] = it
                                scheduleFallbackEmit(deviceAddress, it, scanFilters)
                                return
                            }

                            // Non-connectable devices do not send scan responses; emit now.
                            emitDeviceDiscovery(it, scanFilters)
                        } else {
                            // Subsequent callback for a known device. If we are still waiting
                            // for a scan response (partial entry exists), this callback carries
                            // the merged advertisement + scan response data. Android combines
                            // both packets into the ScanResult transparently.
                            val partialData: ScanResult? = partialAdvertisementData[deviceAddress]
                            if (partialData != null) {
                                // Cancel the fallback - scan response arrived in time.
                                cancelFallbackEmit(deviceAddress)
                                partialAdvertisementData.remove(deviceAddress)
                                emitDeviceDiscovery(it, scanFilters)
                            }
                            // Duplicate advertisements for already-emitted devices are ignored
                            // to prevent flooding the Flutter side with repeated entries.
                        }
                    }
                }
            }

            // Build effective scan settings. When no caller-provided settings are supplied,
            // construct defaults that disable legacy mode on API 26+ so that extended
            // advertisement data (including split scan response payloads) is reported.
            val effectiveSettings: ScanSettings = scanSettings ?: buildDefaultScanSettings()

            if (scanFilters != null) {
                bluetoothLeScanner.startScan(scanFilters, effectiveSettings, scanCallback)
            } else {
                bluetoothLeScanner.startScan(emptyList(), effectiveSettings, scanCallback)
            }
        } catch (e: SecurityException) {
            channel.invokeMethod(
                "error",
                "Required Bluetooth permissions are missing: ${e.message}"
            )
        }
    }

    /**
     * Builds a default [ScanSettings] instance.
     *
     * On API 26 (Android 8) and above, legacy mode is disabled so the scanner can receive
     * extended advertising PDUs. This is required for devices that split advertisement data
     * across the primary packet and a scan response. On older API levels the builder defaults
     * are used unchanged because the non-legacy APIs are not available.
     */
    private fun buildDefaultScanSettings(): ScanSettings {
        val builder = ScanSettings.Builder()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            builder.setLegacy(false)
        }
        return builder.build()
    }

    /**
     * Schedules a fallback emission for a connectable device whose scan response has not yet
     * arrived. If [SCAN_RESPONSE_TIMEOUT_MS] elapses without a subsequent callback, the
     * buffered initial advertisement result is emitted so the Flutter side still learns about
     * the device.
     *
     * @param deviceAddress The MAC address of the device being buffered.
     * @param initialResult The initial ScanResult received for this device.
     * @param scanFilters The active scan filters, forwarded to [emitDeviceDiscovery].
     */
    private fun scheduleFallbackEmit(
        deviceAddress: String,
        initialResult: ScanResult,
        scanFilters: List<ScanFilter>?,
    ) {
        val runnable = Runnable {
            // Only emit if the device is still in the buffer (scan response never arrived).
            val buffered: ScanResult? = partialAdvertisementData.remove(deviceAddress)
            if (buffered != null) {
                pendingFallbackRunnables.remove(deviceAddress)
                emitDeviceDiscovery(buffered, scanFilters)
            }
        }
        pendingFallbackRunnables[deviceAddress] = runnable
        mainHandler.postDelayed(runnable, SCAN_RESPONSE_TIMEOUT_MS)
    }

    /**
     * Cancels a pending fallback emission for the given device address. Called when the scan
     * response arrives before the timeout, making the fallback unnecessary.
     *
     * @param deviceAddress The MAC address whose pending runnable should be cancelled.
     */
    private fun cancelFallbackEmit(deviceAddress: String) {
        pendingFallbackRunnables.remove(deviceAddress)?.let { mainHandler.removeCallbacks(it) }
    }

    /**
     * Cancels all pending fallback runnables. Used when a scan session ends to prevent stale
     * runnables from firing after [stopScan] clears the state maps.
     */
    private fun cancelAllPendingFallbacks() {
        for (runnable in pendingFallbackRunnables.values) {
            mainHandler.removeCallbacks(runnable)
        }
        pendingFallbackRunnables.clear()
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
                scanCallback = null
            }

            // Cancel pending fallback runnables first so they do not fire after state is cleared.
            cancelAllPendingFallbacks()

            // Flush any connectable devices that were buffered but never received a scan
            // response. Without this, those devices would be silently dropped when the scan
            // ends, which means the Flutter side would never learn about them at all.
            for ((_, bufferedResult) in partialAdvertisementData) {
                emitDeviceDiscovery(bufferedResult, null)
            }

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
     * Creates a [ScanSettings] object from the given map representation.
     *
     * Keys recognised in [settingsMap]:
     * - `scanMode`: int corresponding to [ScanSettings.SCAN_MODE_*] constants
     * - `reportDelayMillis`: Long, delay before batched results are reported
     * - `matchMode`: int, how aggressively to match advertisements (API 23+)
     * - `callbackType`: int, controls which events trigger the callback (API 23+)
     * - `numOfMatches`: int, number of matches per filter before callback fires (API 23+)
     * - `legacy`: Boolean, whether to restrict scanning to legacy PDUs (API 26+)
     * - `phy`: int, PHY used for scanning (API 26+)
     *
     * @param settingsMap The map containing the settings properties.
     * @return A [ScanSettings] instance configured from the provided map.
     */
    fun createScanSettingsFromMap(settingsMap: Map<String, Any>?): ScanSettings {
        val builder = ScanSettings.Builder()

        settingsMap?.get("scanMode")?.let { builder.setScanMode(it as Int) }
        settingsMap?.get("reportDelayMillis")?.let { builder.setReportDelay((it as Number).toLong()) }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            settingsMap?.get("matchMode")?.let { builder.setMatchMode(it as Int) }
            settingsMap?.get("callbackType")?.let { builder.setCallbackType(it as Int) }
            settingsMap?.get("numOfMatches")?.let { builder.setNumOfMatches(it as Int) }
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // When the caller does not provide an explicit legacy value, default to false so
            // that extended advertising PDUs and scan responses are both delivered.
            val legacyValue: Boolean = settingsMap?.get("legacy") as? Boolean ?: false
            builder.setLegacy(legacyValue)
            settingsMap?.get("phy")?.let { builder.setPhy(it as Int) }
        }

        return builder.build()
    }
}