# Method: `getConnectedDevices`

## Description

Gets a list of identifiers for all connected devices.

 This method communicates with the native platform code to obtain a list of all connected devices.
 It returns a list of device identifiers as strings.

 On iOS, the identifiers returned by this method are the UUIDs of the connected peripherals. This means that the
 identifiers are specific to the iOS device on which this method is called. The same Bluetooth device will be
 associated with different identifiers on different iOS devices. Therefore, it may be necessary for the Flutter
 side to maintain a mapping between the device identifiers and the device addresses, or other identifiers, if
 cross-device consistency is required.

 On Android, the process is simpler because this method will return a list of BDA (Bluetooth Device Address)
 strings, which are unique identifiers for each connected device. These identifiers are consistent across devices.

 Returns a [Future] containing a list of [ConnectedBleDevice] objects representing Bluetooth devices.

## Return Type
`Future<List<ConnectedBleDevice>>`

## Parameters

- `serviceUUIDs`: `List<String>`
