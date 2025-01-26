# Method: `readValue`

## Description

Asynchronously retrieves the value of the characteristic.

 This method provides a flexible way to read the characteristic's value from a BLE device
 and interpret it as either a raw byte list (`List<int>`) or as a UTF-8 decoded string (`String`).

 Generics are employed to allow the caller to specify the desired return type, either `String` or `List<int>`.

 If you want the value as a string:
 ```dart
 String value = await myChar.readValue<String>(address: 'device-address');
 ```

 If you need the raw bytes:
 ```dart
 List<int> bytes = await myChar.readValue<List<int>>();
 ```

 If a type other than `String` or `List<int>` is used, an `ArgumentError` is thrown.

## Return Type
`Future<T>`

## Parameters

- ``: `dynamic`
