package com.splendidendeavors.flutter_ble.scanner

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
@RequiresApi(Build.VERSION_CODES.LOLLIPOP)
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
     * enabled on the device, as these are prerequisites for scanning BLE devices on Android.
     */
    fun startScan(scanFilters: List<ScanFilter>? = null, scanSettings: ScanSettings? = null) {
        // Define a scan callback
        scanCallback = object : ScanCallback() {
            override fun onScanResult(callbackType: Int, result: ScanResult?) {
                result?.let {
                    // Extract the manufacturer data
                    val manufacturerDataBytes = it.scanRecord?.manufacturerSpecificData?.get(0)
                    val manufacturerData =
                        manufacturerDataBytes?.joinToString(separator = "") { byte ->
                            "%02x".format(byte)
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
    }

    /**
     * Stops scanning for nearby Bluetooth devices.
     *
     * This method stops the scanning process that was initiated with startScan().
     * It does so by invoking the stopScan() method on the bluetoothLeScanner instance
     * and providing the previously stored scan callback.
     */
    fun stopScan() {
        if (scanCallback != null) {
            bluetoothLeScanner.stopScan(scanCallback)
            scanCallback = null // Clear the callback reference
        }
    }
}