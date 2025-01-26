# Method: `readCharacteristic`

## Description

Reads the value of a specified Bluetooth characteristic.

 This method asynchronously fetches the value of a specified Bluetooth characteristic from a connected device
 and returns it as a [BleCharacteristicValue] instance.

 The method will throw a [TimeoutException] if it does not receive a response within the specified [timeout].
 This safeguards against situations where the asynchronous operation hangs indefinitely.

 Note: A [TimeoutException] does not necessarily indicate a failure in reading the characteristic, but rather
 that a response was not received in the given timeframe. Ensure that the timeout value is appropriate for the
 expected device response times and consider retrying the operation if necessary.

 - `address`: The MAC address of the Bluetooth device. This uniquely identifies
   the device and is used to fetch the associated BluetoothGatt instance.
 - `characteristicUuid`: The UUID of the characteristic whose value is to be read.
   This UUID should match one of the characteristics available on the connected
   Bluetooth device.
 - `timeout`: The maximum amount of time this function will wait for a response from
   the platform side. If this duration is exceeded without receiving a response,
   a [TimeoutException] will be thrown. Ensure that this duration accounts for
   potential delays in device communication.

 Returns a `Future<BleCharacteristicValue>` that completes with the characteristic value once it has been read.

 Example usage:
 ```dart
 try {
   BleCharacteristicValue characteristicValue = await readCharacteristic(
     address: '00:1A:7D:DA:71:13',
     characteristicUuid: '00002a00-0000-1000-8000-00805f9b34fb',
     timeout: Duration(seconds: 10),
   );
   print(characteristicValue.value);
 } catch (e) {
   print('Failed to read characteristic: $e');
 }
 ```

## Return Type
`Future<BleCharacteristicValue>`

## Parameters

- ``: `dynamic`
- ``: `dynamic`
