# Method: `disconnect`

## Description

Asynchronously terminates the connection between the host mobile device and a Bluetooth Low Energy (BLE) peripheral.

 Disconnecting from a BLE device is an important part of BLE best practices. Proper disconnection ensures
 that resources like memory and battery are optimized on both the mobile device and the peripheral.

 ## Importance of Disconnecting

 1. **Resource Management**: BLE connections occupy system resources. Failing to disconnect can lead to resource leakage.
 2. **Battery Optimization**: BLE connections consume battery power on both connecting and connected devices. Timely disconnection helps in prolonging battery life.
 3. **Security**: Maintaining an open connection can expose the devices to potential security risks.
 4. **Connection Limits**: BLE peripherals often have a limit on the number of concurrent connections. Disconnecting when done ensures that other devices can connect.

## Return Type
`Future<void>`

## Parameters

- `deviceAddress`: `String`
