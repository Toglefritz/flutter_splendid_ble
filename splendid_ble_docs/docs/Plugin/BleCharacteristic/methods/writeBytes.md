# Method: `writeBytes`

## Description

Writes raw bytes to this characteristic exactly as provided, without any text encoding.

 `bytes` - The bytes to be written. Each element must be in the range 0-255. Use this for devices whose BLE
 protocol interprets raw byte values (flags, length prefixes, checksums, etc.).
 `writeType` - Optional write type, defaulting to `BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT`.

 Example:
 ```dart
 await characteristic.writeBytes(bytes: <int>[0x01, 0xFF, 0x80]);
 ```

## Return Type
`Future<void>`

## Parameters

- ``: `dynamic`
- ``: `dynamic`
