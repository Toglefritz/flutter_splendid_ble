# Method: `emitCurrentBluetoothStatus`

## Description

Emits the current Bluetooth adapter status to the Dart side.

 This method communicates with the native Android code to obtain the current status of the Bluetooth adapter
 and emits it to any listeners on the Dart side.

 Listeners on the Dart side will receive one of the following enum values from [BluetoothStatus]:

 * `BluetoothStatus.enabled`: Indicates that Bluetooth is enabled and ready for connections.
 * `BluetoothStatus.disabled`: Indicates that Bluetooth is disabled and not available for use.
 * `BluetoothStatus.notAvailable`: Indicates that Bluetooth is not available on the device.

 Returns a [Future] containing a [Stream] of [BluetoothStatus] values representing the current status
 of the Bluetooth adapter on the device.

## Return Type
`Stream<BluetoothStatus>`

