# Method: `requestBluetoothPermissions`

## Description

Requests Bluetooth permissions from the user.

 This method communicates with the native platform code to request Bluetooth permissions.
 It returns one of the values from the [BluetoothPermissionStatus] enumeration.

 * `BluetoothPermissionStatus.GRANTED`: Permission is granted.
 * `BluetoothPermissionStatus.DENIED`: Permission is denied.

 Returns a [Future] containing the [BluetoothPermissionStatus] representing whether permission was granted or not.

## Return Type
`Future<BluetoothPermissionStatus>`

