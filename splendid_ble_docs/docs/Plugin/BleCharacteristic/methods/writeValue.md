# Method: `writeValue`

## Description

Writes a string to this characteristic.

 `value` - The string to be written. It is encoded as UTF-8 before being sent, so only ASCII characters map to
 single bytes with the same value. To send arbitrary byte values, use `writeBytes` instead.
 `writeType` - Optional write type, defaulting to `BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT`.

## Return Type
`Future<void>`

## Parameters

- ``: `dynamic`
- ``: `dynamic`
