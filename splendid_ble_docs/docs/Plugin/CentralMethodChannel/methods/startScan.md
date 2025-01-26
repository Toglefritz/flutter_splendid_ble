# Method: `startScan`

## Description

Starts a scan for nearby Bluetooth Low Energy (BLE) devices and returns a stream of discovered devices.

 Scanning for BLE devices is a crucial step in establishing a BLE connection. It allows the mobile app to
 discover nearby BLE devices and gather essential information like device name, MAC address, and more. This
 method starts the scanning operation on the platform side and listens for discovered devices.

 The function takes optional `filters` and `settings` parameters that allow for more targeted device scanning.
 For example, you could specify a filter to only discover devices that are advertising a specific service.
 Similarly, `settings` allows you to adjust aspects like scan mode, report delay, and more.

 The method uses a [StreamController] to handle the asynchronous nature of BLE scanning. Every time a device is
 discovered by the native platform, the 'bleDeviceScanned' method is invoked, and the device information is
 parsed and added to the stream.

## Return Type
`Stream<BleDevice>`

## Parameters

- ``: `dynamic`
- ``: `dynamic`
