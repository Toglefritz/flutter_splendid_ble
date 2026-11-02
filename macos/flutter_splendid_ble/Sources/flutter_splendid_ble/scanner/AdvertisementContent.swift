import Foundation

/// The non-RSSI content of a discovered device that has been reported to the Flutter side during a scan session.
///
/// The plugin uses this value to decide whether a later advertisement from an already-reported device is worth
/// emitting again. A device is re-emitted only when this content changes. A change in RSSI alone never causes a
/// re-emission.
///
/// Individual advertisement packets often carry only part of a device's data. For example, an advertisement packet
/// without its scan response lacks the scan response's manufacturer data. To keep a partial packet from replacing
/// complete data, `merging(over:)` keeps the previously reported value for any field the new packet does not carry.
struct AdvertisementContent: Equatable {
    /// The device name, if known.
    let name: String?

    /// The manufacturer data as an uppercase hexadecimal string, starting with the two-byte manufacturer identifier.
    let manufacturerData: String?

    /// The UUIDs of the services the device advertises, as strings.
    let advertisedServiceUuids: [String]?

    /// Returns this content with any missing field filled in from `previous`.
    ///
    /// A field counts as missing when it is `nil`, or, for `advertisedServiceUuids`, when it is empty.
    ///
    /// - Parameter previous: The content most recently reported for the same device, or `nil` if none was reported.
    /// - Returns: The content to report for the device.
    func merging(over previous: AdvertisementContent?) -> AdvertisementContent {
        guard let previous = previous else { return self }

        let serviceUuids: [String]? = (advertisedServiceUuids?.isEmpty ?? true)
            ? previous.advertisedServiceUuids
            : advertisedServiceUuids

        return AdvertisementContent(
            name: name ?? previous.name,
            manufacturerData: manufacturerData ?? previous.manufacturerData,
            advertisedServiceUuids: serviceUuids
        )
    }
}
