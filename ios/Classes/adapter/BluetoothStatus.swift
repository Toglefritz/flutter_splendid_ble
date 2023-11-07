//
//  BluetoothStatus.swift
//  flutter_ble
//
//  Enumeration representing the possible statuses of the Bluetoot adapter.
//      - enabled: The Bluetooth adapter is enabled and ready for use.
//      - disabled: The Bluetooth adapter is disabled and needs to be enabled before use.
//      - notAvailable: The device does not have a Bluetooth adapter.
//

import Foundation

enum BluetoothStatus: String {
    case notAvailable = "notAvailable"
    case enabled = "enabled"
    case disabled = "disabled"
}
