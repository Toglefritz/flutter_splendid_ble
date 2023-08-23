package com.splendidendeavors.flutter_ble.adapter

/**
 * Enumeration representing the possible statuses of the Bluetooth adapter.
 * - enabled: The Bluetooth adapter is enabled and ready for use.
 * - disabled: The Bluetooth adapter is disabled and needs to be enabled before use.
 * - notAvailable: The device does not have a Bluetooth adapter.
 */
enum class BluetoothStatus {
    enabled,
    disabled,
    notAvailable
}