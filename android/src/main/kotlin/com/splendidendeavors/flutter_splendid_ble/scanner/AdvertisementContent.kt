package com.splendidendeavors.flutter_splendid_ble.scanner

/**
 * The non-RSSI content of a discovered device that has been reported to the Flutter side during a scan session.
 *
 * [BleScannerHandler] uses this value to decide whether a later advertisement from an already-reported device is
 * worth emitting again. A device is re-emitted only when this content changes. A change in RSSI alone never causes a
 * re-emission.
 *
 * Individual advertisement packets often carry only part of a device's data. For example, an advertisement packet
 * without its scan response lacks the scan response's manufacturer data. To keep a partial packet from replacing
 * complete data, [mergingOver] keeps the previously reported value for any field the new packet does not carry.
 *
 * @property name The device name, if known.
 * @property manufacturerData The manufacturer data as a lowercase hexadecimal string. Each entry starts with its
 * two-byte manufacturer identifier in little-endian order.
 * @property advertisedServiceUuids The UUIDs of the services the device advertises, as strings.
 */
data class AdvertisementContent(
    val name: String?,
    val manufacturerData: String?,
    val advertisedServiceUuids: List<String>,
) {
    /**
     * Returns this content with any missing field filled in from [previous].
     *
     * A field counts as missing when it is null, or, for [advertisedServiceUuids], when it is empty.
     *
     * @param previous The content most recently reported for the same device, or null if none was reported.
     * @return The content to report for the device.
     */
    fun mergingOver(previous: AdvertisementContent?): AdvertisementContent {
        if (previous == null) return this

        return AdvertisementContent(
            name = name ?: previous.name,
            manufacturerData = manufacturerData ?: previous.manufacturerData,
            advertisedServiceUuids = advertisedServiceUuids.ifEmpty { previous.advertisedServiceUuids },
        )
    }
}
