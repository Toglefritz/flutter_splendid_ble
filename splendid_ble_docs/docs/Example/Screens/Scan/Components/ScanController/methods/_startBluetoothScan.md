# Method: `_startBluetoothScan`

## Description

Starts a scan for nearby Bluetooth devices and adds a listener to the stream of devices detected by the scan.

 The scan is handled by the *flutter_ble* plugin. Regardless of operating system, the scan works by providing a
 callback function (in this case [_onDeviceDetected]) that is called whenever a device is detected by the scan.
 The `startScan` stream delivers an instance of [BleDevice] to the callback which contains information about
 the Bluetooth device.

 Various filters can be applied to the scanning process to limit the selection of devices returned by the scan.
 See the [ScanFilter] class for full information about the available filters. But the most common filtering
 option is typically filtering by the UUID of the primary service of the BLE devices detected by the scan. This
 allows manufacturers of Bluetooth devices to ensure that only their devices are returned by the Bluetooth scan,
 which is obviously useful for building a companion mobile app for these devices.

## Return Type
`void`

