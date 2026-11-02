package com.splendidendeavors.flutter_splendid_ble.scanner

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotEquals

/**
 * Tests for [AdvertisementContent], which decides when [BleScannerHandler] re-emits an already-reported device.
 *
 * A device is re-emitted only when its merged non-RSSI content differs from the content last emitted. These tests
 * cover the merge rules that keep partial packets from replacing complete data, and the equality checks that
 * determine whether a re-emission happens.
 */
internal class AdvertisementContentTest {
    /** Content as reported from a complete advertisement plus scan response. */
    private val complete = AdvertisementContent(
        name = "Device",
        manufacturerData = "e5020102030405060708090a0b0c",
        advertisedServiceUuids = listOf("0000180f-0000-1000-8000-00805f9b34fb"),
    )

    /** With no previous emission, the new content is used unchanged. */
    @Test
    fun mergingOver_withoutPrevious_returnsSameContent() {
        assertEquals(complete, complete.mergingOver(null))
    }

    /** A packet missing every field (e.g. an RSSI-only repeat) merges to the previous content, so no re-emission. */
    @Test
    fun mergingOver_emptyPacket_keepsPreviousContent() {
        val empty = AdvertisementContent(name = null, manufacturerData = null, advertisedServiceUuids = emptyList())

        assertEquals(complete, empty.mergingOver(complete))
    }

    /** An advertisement-only packet without scan response fields does not replace the complete data. */
    @Test
    fun mergingOver_partialPacket_keepsMissingFields() {
        val advertisementOnly = AdvertisementContent(
            name = null,
            manufacturerData = null,
            advertisedServiceUuids = listOf("0000180f-0000-1000-8000-00805f9b34fb"),
        )

        assertEquals(complete, advertisementOnly.mergingOver(complete))
    }

    /** Changed manufacturer data (e.g. an advertised type changing from unknown to real) produces new content. */
    @Test
    fun mergingOver_changedManufacturerData_producesDifferentContent() {
        val updated = complete.copy(manufacturerData = "e502ffffffffffffffffffffffff")

        val merged = updated.mergingOver(complete)

        assertEquals("e502ffffffffffffffffffffffff", merged.manufacturerData)
        assertNotEquals(complete, merged)
    }

    /** Manufacturer data arriving after an advertisement-only first emission fills in the missing field. */
    @Test
    fun mergingOver_laterScanResponse_fillsInManufacturerData() {
        val firstEmission = complete.copy(manufacturerData = null)

        val merged = complete.mergingOver(firstEmission)

        assertEquals(complete, merged)
        assertNotEquals(firstEmission, merged)
    }

    /** A changed name or service list is treated as a content change. */
    @Test
    fun mergingOver_changedNameOrServices_producesDifferentContent() {
        assertNotEquals(complete, complete.copy(name = "Renamed").mergingOver(complete))
        assertNotEquals(
            complete,
            complete.copy(advertisedServiceUuids = listOf("0000180a-0000-1000-8000-00805f9b34fb"))
                .mergingOver(complete),
        )
    }
}
