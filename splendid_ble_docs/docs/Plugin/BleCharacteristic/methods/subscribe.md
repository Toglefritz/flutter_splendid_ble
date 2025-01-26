# Method: `subscribe`

## Description

Subscribes to a Bluetooth characteristic to listen for updates.

 A caller to this function will receive a [Stream] of [BleCharacteristicValue] objects. A caller should listen
 to this stream and establish a callback function invoked each time a new value is emitted to the stream. Once
 subscribed, any updates to the characteristic value will be sent as a stream of [BleCharacteristicValue] objects.

## Return Type
`Stream<BleCharacteristicValue>`

