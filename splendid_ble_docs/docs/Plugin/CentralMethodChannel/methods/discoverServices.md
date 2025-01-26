# Method: `discoverServices`

## Description

Initiates the service discovery process for a connected Bluetooth Low Energy (BLE) device and returns a
 [Stream] of discovered services and their characteristics.

 The service discovery process is a crucial step after establishing a BLE connection. It involves querying the
 connected peripheral to enumerate the services it offers along with their associated characteristics and
 descriptors. These services can represent various functionalities provided by the device, such as heart rate
 monitoring, temperature sensing, etc.

 The method uses a [StreamController] to handle the asynchronous nature of service discovery. The native
 platform code Android sends updates when new services and characteristics are discovered, which are then parsed
 and added to the stream.

 ## How Service Discovery Works

 1. After connecting to a BLE device, you invoke the `discoverServices()` method, passing in the device address.
 2. The native code kicks off the service discovery process.
 3. As services and their characteristics are discovered, they are sent back to the Flutter app.
 4. These updates are received in the `_handleBleServicesDiscovered` method (not shown here), which then
    notifies all listeners to the stream.

## Return Type
`Stream<List<BleService>>`

## Parameters

- `deviceAddress`: `String`
