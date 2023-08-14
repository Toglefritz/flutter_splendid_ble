package com.splendidendeavors.flutter_ble.scanner

/**
 * The `DiscoveredDevice` class encapsulates information about a Bluetooth Low Energy (BLE) device
 * that has been discovered during a scanning operation.
 *
 * This class is used to organize the details of the discovered device, including:
 * - Name: The name of the BLE device, as broadcast by the device itself.
 * - Address: The hardware address of the BLE device, typically a MAC address.
 * - RSSI: The Received Signal Strength Indicator (RSSI), indicating the power level detected by the receiver.
 * - Manufacturer Data: Any additional manufacturer data that might be broadcast by the device.
 *
 * The class provides a convenient way to serialize this information into a map,
 * which can be sent through a method channel to the Flutter side of the application.
 */
class DiscoveredDevice(private val deviceMap: Map<String, Any?>) {
    // Serializes information about the DiscoveredDevice into a map
    fun toMap(): Map<String, Any?> {
        return deviceMap
    }
}