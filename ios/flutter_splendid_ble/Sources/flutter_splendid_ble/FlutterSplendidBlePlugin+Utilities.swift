import Flutter
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
            channel.invokeMethod("error", arguments: "Device not found.")
            return nil
        }
        
        return peripheral
    }
    
    // Utility method to find a characteristic on a peripheral by its UUID
    func getCharacteristicByUuid(peripheral: CBPeripheral, uuid: UUID) -> CBCharacteristic? {
        let cbuuid = CBUUID(nsuuid: uuid)
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
