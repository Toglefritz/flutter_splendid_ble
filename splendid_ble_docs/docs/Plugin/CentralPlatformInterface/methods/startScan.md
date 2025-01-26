# Method: `startScan`

## Description

Starts a scan for nearby BLE devices and returns a [Stream] of [BleDevice] instances representing the BLE
 devices that were discovered. On the Flutter side, listeners can be added to this stream so they can
 respond to Bluetooth devices being discovered, for example by presenting the list in the user interface
 or enabling controllers to find and connect to specific devices.

## Return Type
`Stream<BleDevice>`

## Parameters

- ``: `dynamic`
- ``: `dynamic`
