import FlutterMacOS
import CoreBluetooth

/// Utility helpers for `FlutterSplendidBlePlugin`.
///
/// This extension contains small, reusable helpers used throughout the plugin: looking up a peripheral or
/// characteristic by identifier, and tracking whether a characteristic value update is the response to an
/// explicit read request (as opposed to a notification).
extension FlutterSplendidBlePlugin {

    // MARK: Utility Methods
    
    // Utility method to get a CBPeripheral by its identifier
    func getPeripheralByIdentifier(deviceAddress: String) -> CBPeripheral? {
        guard let peripheral = peripheralsMap[deviceAddress] else {
            centralChannel.invokeMethod("error", arguments: "Device not found.")
            return nil
        }
        
        return peripheral
    }
    
    /// Parses a characteristic UUID string sent from Dart into a `CBUUID`.
    ///
    /// CoreBluetooth reports 16-bit and 32-bit Bluetooth SIG UUIDs in their short form (for example `FF11`), so the
    /// Dart side passes back whatever string service discovery returned. `Foundation.UUID(uuidString:)` only accepts the
    /// 36-character form and would reject those values. `CBUUID(string:)` accepts the 4, 8, and 36-character forms, and
    /// `CBUUID` equality treats a short UUID and its expansion on the Bluetooth Base UUID as the same value.
    ///
    /// - Parameter string: The UUID string in any form `CBUUID` supports.
    /// - Returns: The parsed `CBUUID`, or `nil` when the string is not a valid UUID. `CBUUID(string:)` raises an
    ///   Objective-C exception for malformed input, so the format is validated first.
    func parseCharacteristicUuid(_ string: String) -> CBUUID? {
        let hexDigits = CharacterSet(charactersIn: "0123456789abcdefABCDEF")
        let isHex: (String) -> Bool = { $0.unicodeScalars.allSatisfy { hexDigits.contains($0) } }
        switch string.count {
        case 4, 8:
            return isHex(string) ? CBUUID(string: string) : nil
        case 36:
            return UUID(uuidString: string) != nil ? CBUUID(string: string) : nil
        default:
            return nil
        }
    }

    // Utility method to find a characteristic on a peripheral by its UUID
    func getCharacteristicByUuid(peripheral: CBPeripheral, uuid cbuuid: CBUUID) -> CBCharacteristic? {
        for service in peripheral.services ?? [] {
            if let characteristic = service.characteristics?.first(where: { $0.uuid == cbuuid }) {
                return characteristic
            }
        }
        return nil
    }
    
    /// Registers a read operation on a Bluetooth characteristic
    func setReadRequestFlag(for characteristic: CBCharacteristic) {
        pendingReadRequests[characteristic.uuid] = true
    }
    
    /// Determines if a read operation on a Bluetooth characteristic is currently in progress,
    func isReadResponse(characteristic: CBCharacteristic) -> Bool {
        return pendingReadRequests[characteristic.uuid] ?? false
    }
    
    /// Clears the flag that determines if a read operation on a Bluetooth characteristic is currently in progress.
    func clearReadResponseFlag(characteristic: CBCharacteristic) {
        pendingReadRequests[characteristic.uuid] = nil
    }
}

// Extension to convert Data to a hex string
extension Data {
    var hexString: String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}
