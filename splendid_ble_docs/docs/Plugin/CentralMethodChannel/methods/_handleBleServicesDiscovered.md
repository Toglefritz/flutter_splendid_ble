# Method: `_handleBleServicesDiscovered`

## Description

Sets a handler for processing the discovered BLE services and characteristics for a specific peripheral device.

 Service and characteristic discovery is a fundamental step in BLE communication.
 Once a connection with a BLE peripheral is established, the central device (in this case, our Flutter app)
 must discover the services offered by the peripheral to understand how to communicate with it effectively.
 Each service can have multiple characteristics, which are like "channels" of communication.
 By understanding these services and characteristics, our Flutter app can read from or write to
 these channels to facilitate meaningful exchanges of data.

 The purpose of this method is to convert the raw service and characteristic data received from the method channel
 into a structured format (a list of [BleService] objects) for Dart, and then pass them through the provided stream controller.

 [deviceAddress] is the MAC address of the target BLE device.
 [servicesDiscoveredController] is the stream controller through which the discovered services will be emitted to listeners.

## Return Type
`void`

## Parameters

- `deviceAddress`: `String`
- `servicesDiscoveredController`: `StreamController<List<BleService>>`
