//
//  BleScannerHandler.swift
//  flutter_ble
//
//  Created by Scott Hatfield on 10/8/23.
//

import Foundation
import CoreBluetooth
import FlutterMacOS

// The `BleScannerHandler` class manages Bluetooth Low Energy (BLE) scanning
// for the macOS platform using the `flutter_ble` plugin.
@objc class BleScannerHandler: NSObject {
    private var flutterChannel: FlutterMethodChannel?
    private var centralManager: CBCentralManager?
    private var scanCallback: ((CBPeripheral, [String: Any]) -> Void)?

    // Initialize the `BleScannerHandler` with a FlutterMethodChannel to
    // communicate with the Flutter side.
    @objc init(channel: FlutterMethodChannel) {
        self.flutterChannel = channel
        super.init()
        // Create a CBCentralManager to handle Bluetooth operations.
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    /**
     * Initiates the scanning process for nearby Bluetooth Low Energy (BLE) devices.
     *
     * The `startScan` method uses the iOS `CBCentralManager` to begin scanning for BLE
     * devices within range. Upon discovery of a device, the information is encapsulated
     * into a dictionary and sent to the Flutter side via a method channel.
     *
     * Key information collected from each device includes:
     *  -    Name: The name of the BLE device.
     *  -    Identifier: The unique identifier of the BLE device.
     *  -    RSSI: The Received Signal Strength Indicator, indicating the power level detected
     *       by the receiver.
     *
     * The scanning process continues until explicitly stopped by calling the `stopScan` method.
     *
     * Note: Ensure that the necessary permissions (e.g., Bluetooth) are enabled on the device.
     */
    @objc func startScan() {
        centralManager?.scanForPeripherals(withServices: nil, options: nil)
    }

    /**
     * Stops scanning for nearby Bluetooth devices.
     *
     * This method stops the scanning process that was initiated with startScan().
     */
    @objc func stopScan() {
        centralManager?.stopScan()
    }
}

// Extension to handle CBCentralManagerDelegate methods
extension BleScannerHandler: CBCentralManagerDelegate {
    // This method is called when the Bluetooth state changes.
    @objc func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            // Bluetooth is powered on, start scanning
            startScan()
        } else {
            // TODO Handle Bluetooth state not powered on or other errors
        }
    }

    // This method is called when a BLE device is discovered.
    @objc func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        // Extract the manufacturer data
        let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data

        // Create a dictionary with device details
        var deviceMap: [String: Any?] = [
            "name": peripheral.name,
            "address": peripheral.identifier.uuidString,
            "rssi": RSSI.intValue,
            // ... add other details as needed
        ]

        // Get manufacturer data and add it to the map
        if let manufacturerData = manufacturerData {
            deviceMap["manufacturerData"] = manufacturerData.hexString
        }

        // Send device information to Flutter side
        let jsonData = try? JSONSerialization.data(withJSONObject: deviceMap, options: [])
        if let jsonData = jsonData, let jsonString = String(data: jsonData, encoding: .utf8) {
            flutterChannel?.invokeMethod("bleDeviceScanned", arguments: jsonString)
        }
    }
}

// Extension to convert Data to a hex string
extension Data {
    var hexString: String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}
