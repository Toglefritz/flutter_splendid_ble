import Flutter
import CoreBluetooth

/// `CBPeripheralDelegate` conformance for `FlutterSplendidBlePlugin`.
///
/// This extension contains the Core Bluetooth callbacks that are invoked for an individual connected
/// peripheral: service and characteristic discovery, notification state changes, characteristic value
/// updates (reads and notifications), and write acknowledgements. Each callback forwards the relevant
/// information to the Flutter side and, where applicable, completes the pending `FlutterResult` that was
/// stored when the corresponding operation was requested.
extension FlutterSplendidBlePlugin {

    // MARK: CBPeripheralDelegate Methods
    
    /// Invoked when a peripheral's services have been successfully discovered.
    /// This delegate method checks for any errors in service discovery and initiates the discovery of characteristics for each service.
    /// It is critical for progressing the BLE discovery process, enabling the app to access service-related information and act upon it.
    /// If an error occurs during service discovery, it communicates this to the Flutter layer for appropriate handling in the UI or other app logic.
    /// - Parameters:
    ///   - peripheral: The `CBPeripheral` providing this information, representing the BLE device whose services have been discovered.
    ///   - error: An optional `Error` object containing details of the failure if the service discovery process did not succeed.
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            channel.invokeMethod("error", arguments: "Service discovery failed: \(error!.localizedDescription)")
            return
        }
        
        guard let services = peripheral.services else { return }
        
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    /// Invoked when the characteristics of a specific service have been discovered.
    /// This delegate method is called following a successful call to `discoverCharacteristics(_:for:)`.
    /// If characteristics are discovered successfully, it compiles the characteristic information into a structured format
    /// and communicates this back to the Flutter layer for further processing or UI updates.
    /// In case of an error during characteristics discovery, it reports the error back to the Flutter layer.
    /// - Parameters:
    ///   - peripheral: The `CBPeripheral` providing this information, representing the BLE device whose service characteristics have been discovered.
    ///   - service: The `CBService` object containing the characteristics that were discovered.
    ///   - error: An optional `Error` object containing details of the failure if the characteristics discovery process did not succeed.
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else {
            // Notify the Flutter layer about the characteristics discovery failure with an error message.
            channel.invokeMethod("error", arguments: "Characteristics discovery failed for service \(service.uuid): \(error!.localizedDescription)")
            return
        }
        
        // Prepare a dictionary to hold service and characteristic data.
        var serviceData = [String: Any]()
        var characteristicsData = [[String: Any]]()
        
        // Iterate over each characteristic discovered and append its details to the characteristics data array.
        service.characteristics?.forEach { characteristic in
            characteristicsData.append([
                "address": peripheral.identifier.uuidString, // The address of the peripheral.
                "uuid": characteristic.uuid.uuidString,     // The UUID of the characteristic.
                "properties": characteristic.properties.rawValue, // The properties of the characteristic, as a raw value.
            ])
        }
        
        // Assign the array of characteristic data to the corresponding service UUID in the service data dictionary.
        serviceData[service.uuid.uuidString] = characteristicsData
        
        // Invoke a method on the Flutter side with the service data, signaling that characteristics have been discovered.
        channel.invokeMethod("bleServicesDiscovered_\(peripheral.identifier.uuidString)", arguments: serviceData)
    }
    
    /// Invoked when the notification state has been updated for a characteristic.
    ///
    /// This callback is triggered as a response to a call to `setNotifyValue(_:for:)` on a `CBPeripheral` instance,
    /// indicating whether notifications or indications are enabled or disabled for a given characteristic.
    ///
    /// This method completes the pending FlutterResult that was stored in subscribeToCharacteristic() or
    /// unsubscribeFromCharacteristic(), ensuring proper async/await behavior in Dart. The Flutter method
    /// call doesn't return until the notification state change actually completes.
    ///
    /// - Parameters:
    ///   - peripheral: The `CBPeripheral` providing this update, representing the BLE device whose characteristic's notification state has changed.
    ///   - characteristic: The `CBCharacteristic` for which the notification state has been updated.
    ///   - error: An optional `Error` object that contains the reason for the failure if the notification state update was unsuccessful.
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        let deviceAddress: String = peripheral.identifier.uuidString
        let characteristicUuidStr: String = characteristic.uuid.uuidString
        let key: String = "\(deviceAddress):\(characteristicUuidStr)"

        // Get and remove the pending result if one exists
        if let pendingResult = pendingNotificationStateChanges.removeValue(forKey: key) {
            // Complete the Flutter method call
            if let error = error {
                pendingResult(FlutterError(
                    code: "NOTIFICATION_STATE_CHANGE_FAILED",
                    message: "Failed to update notification state for characteristic \(characteristic.uuid): \(error.localizedDescription)",
                    details: nil
                ))
            } else {
                pendingResult(nil)
            }
        } else {
            // No pending result - might be from an old implementation or unexpected call
            if let error = error {
                channel.invokeMethod("error", arguments: "Failed to update notification state for characteristic \(characteristic.uuid): \(error.localizedDescription)")
            }
        }
    }
    
    /// Invoked when a peripheral has updated the value for a characteristic.
    /// This delegate method is called when a peripheral sends a notification or indication that a characteristic's value has changed,
    /// or in response to a read request either initiated by the `readValue(for:)` method or a direct read request from the central device.
    /// Errors encountered during the operation are handled within this callback. If no error occurs, the new value is processed and
    /// communicated to the Flutter side through a method channel call. This facilitates real-time data communication with the Flutter app.
    /// - Parameters:
    ///   - peripheral: The `CBPeripheral` that has sent the updated value. It represents the BLE device from which the data is coming.
    ///   - characteristic: The `CBCharacteristic` containing the updated value.
    ///   - error: An optional `Error` detailing what went wrong during the operation, if anything.
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            channel.invokeMethod("error", arguments: "Failed to update value for characteristic \(characteristic.uuid): \(error!.localizedDescription)")
            return
        }
        
        // If the value update was successful, the new characteristic value is formatted into a list of integers.
        let valueList = characteristic.value?.map { Int($0) } ?? []
        
        // Prepare the information to be sent to the Flutter side, including the device address and characteristic details.
        let deviceAddress = peripheral.identifier.uuidString
        let characteristicMap: [String: Any] = [
            "deviceAddress": deviceAddress,
            "characteristicUuid": characteristic.uuid.uuidString,
            "value": valueList
        ]
        
        // Check if this update is the result of a read request or a notification.
        if isReadResponse(characteristic: characteristic) {
            // This is a read response
            channel.invokeMethod("onCharacteristicRead", arguments: characteristicMap)
            clearReadResponseFlag(characteristic: characteristic)
        } else {
            // This is a notification update
            channel.invokeMethod("onCharacteristicChanged", arguments: characteristicMap)
        }
    }
    
    /// Invoked when a write operation on a characteristic completes.
    /// This delegate method is called after a write to a characteristic has been performed,
    /// indicating whether the write was successful or if an error occurred.
    ///
    /// - Parameters:
    ///   - peripheral: The `CBPeripheral` that completed the write operation.
    ///   - characteristic: The `CBCharacteristic` that was written to.
    ///   - error: An optional `Error` detailing what went wrong during the write operation, if anything.
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        let deviceAddress = peripheral.identifier.uuidString
        let key = "\(deviceAddress):\(characteristic.uuid.uuidString)"

        if let error = error {
            // Complete the pending Dart future with an error so the await on writeValue() throws.
            if let pendingResult = pendingWriteResults.removeValue(forKey: key) {
                pendingResult(FlutterError(
                    code: "WRITE_FAILED",
                    message: "Failed to write characteristic: \(error.localizedDescription)",
                    details: nil
                ))
            }

            // Also notify any legacy listeners via the method channel event.
            let errorMap: [String: Any] = [
                "deviceAddress": deviceAddress,
                "characteristicUuid": characteristic.uuid.uuidString,
                "success": false,
                "error": "Failed to write characteristic: \(error.localizedDescription)"
            ]
            channel.invokeMethod("onCharacteristicWrite", arguments: errorMap)
        } else {
            // Complete the pending Dart future successfully.
            if let pendingResult = pendingWriteResults.removeValue(forKey: key) {
                pendingResult(nil)
            }

            // Also notify any legacy listeners via the method channel event.
            let successMap: [String: Any] = [
                "deviceAddress": deviceAddress,
                "characteristicUuid": characteristic.uuid.uuidString,
                "success": true
            ]
            channel.invokeMethod("onCharacteristicWrite", arguments: successMap)
        }
    }
}
