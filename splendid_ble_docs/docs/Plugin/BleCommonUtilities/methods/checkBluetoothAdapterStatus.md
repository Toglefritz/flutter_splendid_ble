# Method: `checkBluetoothAdapterStatus`

## Description

Checks the status of the Bluetooth adapter on the device.

 This method communicates with the native Android code to obtain the current status of the Bluetooth adapter,
 and returns one of the values from the [BluetoothStatus] enumeration.

 * `BluetoothStatus.ENABLED`: Bluetooth is enabled and ready for connections.
 * `BluetoothStatus.DISABLED`: Bluetooth is disabled and not available for use.
 * `BluetoothStatus.NOT_AVAILABLE`: Bluetooth is not available on the device.

 Returns a Future containing the [BluetoothStatus] representing the current status of the Bluetooth adapter on
 the device.

 It can be useful to check on the status of the Bluetooth adapter prior to attempting Bluetooth operations as
 a way of improving the user experience. Checking on the state of the Bluetooth adapter allows the user to be
 notified and prompted for action if they attempt to use an applications for which Bluetooth plays a critical
 role while the Bluetooth capabilities of the host device are disabled.

## Return Type
`Future<BluetoothStatus>`

## Parameters

- `channel`: `MethodChannel`
