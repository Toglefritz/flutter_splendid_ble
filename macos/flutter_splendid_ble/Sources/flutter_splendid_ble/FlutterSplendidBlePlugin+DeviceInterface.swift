import FlutterMacOS
import CoreBluetooth

/// Device interface helpers for `FlutterSplendidBlePlugin`.
///
/// The methods in this extension collectively serve as an interface for managing connections and
/// interactions with BLE devices and communicating with Bluetooth devices. They are responsible for
/// retrieving connected devices, establishing and terminating connections, querying connection state, and
/// subscribing to or unsubscribing from characteristic notifications.
extension FlutterSplendidBlePlugin {

    // MARK: Device Interface Helper Methods

    /// Gets a list of Bluetooth devices that are currently connected to the device.
    ///
    /// This function accepts a list of service UUIDs used to filter the list of connected BLE devices to return. This list must contain at least one UUID because requesting
    /// connected devices without providing a service UUID will always return an empty list (it is asking for a list of Bluetooth devices that do not have any services, which
    /// is always an empty list).
    ///
    /// - Returns: A list of connected devices.
    func getConnectedDevices(withServiceUUIDs serviceUUIDs: [String]) -> [[String: String]] {
        let uuids = serviceUUIDs.map { CBUUID(string: $0) }
        let connectedPeripherals = centralManager.retrieveConnectedPeripherals(withServices: uuids)
        
        return connectedPeripherals.map { peripheral in
            [
                "name": peripheral.name ?? "Unknown",
                "identifier": peripheral.identifier.uuidString
            ]
        }
    }

    /// Initiates a connection to a Bluetooth Low Energy (BLE) device.
    ///
    /// This function tries to initiate a connection to a BLE peripheral device with the provided UUID string.
    /// If the peripheral is not found in the `peripheralsMap`, an error is sent through the method channel.
    ///
    /// - Parameter deviceAddress: The UUID string of the peripheral device to connect to.
    func connect(deviceAddress: String) {
        guard let peripheral = peripheralsMap[deviceAddress] else {
            centralChannel.invokeMethod("error", arguments: "Device not found.")
            return
        }
        
        centralManager.connect(peripheral, options: nil)
    }
    
    /// Disconnects from a connected Bluetooth Low Energy (BLE) device.
    ///
    /// This function disconnects from a BLE peripheral device with the provided UUID string.
    /// If the peripheral is not found in the `peripheralsMap`, an error is sent through the method channel.
    ///
    /// - Parameter deviceAddress: The UUID string of the peripheral device to disconnect from.
    func disconnect(deviceAddress: String) {
        guard let peripheral = peripheralsMap[deviceAddress] else {
            centralChannel.invokeMethod("error", arguments: "Device not found.")
            return
        }
        
        centralManager.cancelPeripheralConnection(peripheral)
    }
    
    /// Retrieves the current connection state of a Bluetooth Low Energy (BLE) device.
    ///
    /// This function checks the connection state of a BLE peripheral device with the provided UUID string.
    /// If the peripheral is found in the `peripheralsMap`, its connection state is sent through the method channel.
    /// If the peripheral is not found, an error is sent through the method channel.
    ///
    /// - Parameter deviceAddress: The UUID string of the peripheral device whose connection state is to be checked.
    /// - Returns: A string representing the connection state ("CONNECTED", "DISCONNECTED", "FAILED", or "UNKNOWN").
    func getCurrentConnectionState(deviceAddress: String) -> String {
        guard let peripheral = peripheralsMap[deviceAddress] else {
            centralChannel.invokeMethod("error", arguments: "Device not found.")
            return "UNKNOWN"
        }
        
        switch peripheral.state {
        case .connected:
            return "CONNECTED"
        case .disconnected:
            return "DISCONNECTED"
        case .connecting:
            return "CONNECTING"
        case .disconnecting:
            return "DISCONNECTING"
        @unknown default:
            return "UNKNOWN"
        }
    }
    
    // MethodChannel handler for subscribing to a BLE characteristic
    func subscribeToCharacteristic(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let deviceAddress = args["address"] as? String,
              let characteristicUuidStr = args["characteristicUuid"] as? String
        else {
            result(FlutterError(code: "INVALID_ARGUMENT",
                                message: "Characteristic subscription error: device address or characteristic UUID cannot be null.",
                                details: nil))
            return
        }
        
        guard let peripheral = getPeripheralByIdentifier(deviceAddress: deviceAddress) else {
            result(FlutterError(code: "INVALID_ARGUMENT",
                                message: "No peripheral found for device address: \(deviceAddress)",
                                details: nil))
            return
        }
        
        guard let characteristicUuid = UUID(uuidString: characteristicUuidStr) else {
            result(FlutterError(code: "INVALID_ARGUMENT",
                                message: "Invalid characteristic UUID format",
                                details: nil))
            return
        }
        
        
        if let characteristic = getCharacteristicByUuid(peripheral: peripheral, uuid: characteristicUuid) {
            // Create a key to track this specific operation
            let key = "\(deviceAddress):\(characteristicUuidStr)"

            // Store the result callback to complete later when the operation finishes
            pendingNotificationStateChanges[key] = result

            // Initiate the notification state change
            // The result will be completed in didUpdateNotificationStateFor callback
            peripheral.setNotifyValue(true, for: characteristic)
        } else {
            result(FlutterError(code: "NOT_FOUND",
                                message: "Characteristic with UUID \(characteristicUuidStr) not found.",
                                details: nil))
        }
    }
    
    func unsubscribeFromCharacteristic(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let deviceAddress = args["address"] as? String,
              let characteristicUuidStr = args["characteristicUuid"] as? String,
              let characteristicUuid = UUID(uuidString: characteristicUuidStr),
              let peripheral = peripheralsMap[deviceAddress] else {
            result(FlutterError(code: "INVALID_ARGUMENT",
                                message: "Device address or characteristic UUID cannot be null.",
                                details: nil))
            return
        }
        
        let cbCharacteristicUuid = CBUUID(nsuuid: characteristicUuid)
        
        if let service = peripheral.services?.first(where: { $0.characteristics?.contains(where: { $0.uuid == cbCharacteristicUuid }) == true }),
           let characteristic = service.characteristics?.first(where: { $0.uuid == cbCharacteristicUuid }) {

            // Create a key to track this specific operation
            let key = "\(deviceAddress):\(characteristicUuidStr)"

            // Store the result callback to complete later when the operation finishes
            pendingNotificationStateChanges[key] = result

            // Initiate the notification state change
            // The result will be completed in didUpdateNotificationStateFor callback
            peripheral.setNotifyValue(false, for: characteristic)
        } else {
            result(FlutterError(code: "SUBSCRIBE_ERROR",
                                message: "Failed to unsubscribe from characteristic: Characteristic not found.",
                                details: nil))
        }
    }
}
