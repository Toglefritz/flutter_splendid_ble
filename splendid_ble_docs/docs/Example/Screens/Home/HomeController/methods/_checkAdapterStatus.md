# Method: `_checkAdapterStatus`

## Description

Checks the status of the Bluetooth adapter on the host device (assuming one is present).

 Before the Bluetooth scan can be started or any other Bluetooth operations can be performed, the Bluetooth
 capabilities of the host device must be available. This method establishes a listener on the current state
 of the host device's Bluetooth adapter, which is represented by the enum, [BluetoothStatus].

## Return Type
`Future<void>`

