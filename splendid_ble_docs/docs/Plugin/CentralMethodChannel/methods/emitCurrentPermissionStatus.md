# Method: `emitCurrentPermissionStatus`

## Description

Emits the current Bluetooth permission status to the Dart side.

 This method communicates with the native platform code to obtain the current Bluetooth permission status and emits it to any listeners on the Dart side.

 Listeners on the Dart side will receive one of the following enum values from [BluetoothPermissionStatus]:

 * `BluetoothPermissionStatus.GRANTED`: Indicates that Bluetooth permission is granted.
 * `BluetoothPermissionStatus.DENIED`: Indicates that Bluetooth permission is denied.

 Returns a [Stream] of [BluetoothPermissionStatus] values representing the current Bluetooth permission status on the device.

## Return Type
`Stream<BluetoothPermissionStatus>`

