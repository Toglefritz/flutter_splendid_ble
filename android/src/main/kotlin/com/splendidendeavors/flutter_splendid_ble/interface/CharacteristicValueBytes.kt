package com.splendidendeavors.flutter_splendid_ble.`interface`

/**
 * Converts a characteristic value into the list of byte values sent to the Flutter side.
 *
 * Kotlin's [Byte] is signed, so converting it with [Byte.toInt] turns bytes from `0x80` to `0xFF` into negative
 * numbers, such as `0xA1` into -95. Each byte is masked with `0xFF` instead, so every element is in the range 0-255.
 * This matches iOS and macOS, where CoreBluetooth values are unsigned bytes, so `BleCharacteristicValue.value` holds
 * the same numbers on every platform.
 *
 * @receiver The raw bytes of a characteristic value, as reported by Android.
 * @return The bytes as unsigned values from 0 to 255, in the same order.
 */
fun ByteArray.toUnsignedByteList(): List<Int> = map { byte -> byte.toInt() and 0xFF }
