# Method: `connect`

## Description

Initiates a connection to a BLE peripheral and returns a Stream representing the connection state.

 The [deviceAddress] parameter specifies the MAC address of the target device.

 This method calls the 'connect' method on the native Android implementation via a method channel, and returns a
 [Stream] that emits [ConnectionState] enum values representing the status of the connection. Because an app could
 attempt to establish a connection to multiple different peripherals at once, the platform side differentiates
 connection status updates for each peripheral by appending the peripherals' Bluetooth addresses to the
 method channel names. For example, the connection states for a particular module with address, *10:91:A8:32:8C:BA*
 would be communicated with the method channel name, "bleConnectionState_10:91:A8:32:8C:BA". In this way, a
 different [Stream] of [BleConnectionState] values is established for each Bluetooth peripheral.

## Return Type
`Stream<BleConnectionState>`

## Parameters

- ``: `dynamic`
