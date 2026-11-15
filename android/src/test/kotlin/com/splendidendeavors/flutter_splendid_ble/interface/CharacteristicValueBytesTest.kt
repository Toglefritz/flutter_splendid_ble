package com.splendidendeavors.flutter_splendid_ble.`interface`

import kotlin.test.Test
import kotlin.test.assertEquals

/**
 * Tests for [toUnsignedByteList], which converts characteristic values before they are sent to the Flutter side.
 *
 * Binary protocols read multi-byte numbers from these values, so every byte must arrive as 0-255, as it does on iOS
 * and macOS. A signed byte silently corrupts any number it is part of.
 */
internal class CharacteristicValueBytesTest {
    /** Bytes from `0x80` to `0xFF` are reported as 128-255 rather than as negative numbers. */
    @Test
    fun toUnsignedByteList_highBytes_areNotNegative() {
        val value = byteArrayOf(0x80.toByte(), 0xA1.toByte(), 0xEA.toByte(), 0xFF.toByte())

        assertEquals(listOf(0x80, 0xA1, 0xEA, 0xFF), value.toUnsignedByteList())
    }

    /** Bytes from `0x00` to `0x7F` are reported unchanged. */
    @Test
    fun toUnsignedByteList_lowBytes_areUnchanged() {
        val value = byteArrayOf(0x00, 0x01, 0x2B, 0x7F)

        assertEquals(listOf(0x00, 0x01, 0x2B, 0x7F), value.toUnsignedByteList())
    }

    /**
     * A notification from a BOOKOO scale with 414.5 g on it keeps its weight bytes, `00 A1 EA`, intact.
     *
     * Before the fix, these bytes reached Dart as 0, -95, -22, which decoded to -0.22 g.
     */
    @Test
    fun toUnsignedByteList_scaleFrame_keepsEveryByte() {
        val frame = listOf(
            0x03, 0x0B, 0x00, 0x00, 0x00, 0x01, 0x2B, 0x00, 0xA1, 0xEA,
            0x2D, 0x00, 0x02, 0x64, 0x00, 0x96, 0x01, 0x00, 0x00, 0xB5,
        )

        assertEquals(frame, frame.map { it.toByte() }.toByteArray().toUnsignedByteList())
    }

    /** An empty value stays empty. */
    @Test
    fun toUnsignedByteList_empty_isEmpty() {
        assertEquals(emptyList(), byteArrayOf().toUnsignedByteList())
    }
}
