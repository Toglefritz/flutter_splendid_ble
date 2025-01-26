# Method: `getCurrentConnectionState`

## Description

Fetches the current connection state of a Bluetooth Low Energy (BLE) device.

 The [deviceAddress] parameter specifies the MAC address of the target device.

 This method calls the 'getCurrentConnectionState' method on the native Android implementation
 via a method channel. It then returns a [Future] that resolves to the [ConnectionState] enum,
 which represents the current connection state of the device.

 Returns a [Future] containing the [ConnectionState] representing the current connection state
 of the BLE device with the specified address.

## Return Type
`Future<BleConnectionState>`

## Parameters

- `deviceAddress`: `String`
