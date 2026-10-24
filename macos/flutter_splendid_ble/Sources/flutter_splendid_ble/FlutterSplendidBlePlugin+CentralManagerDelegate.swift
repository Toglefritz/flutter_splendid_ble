import FlutterMacOS
import CoreBluetooth

/// `CBCentralManagerDelegate` and `CBPeripheralManagerDelegate` conformance for `FlutterSplendidBlePlugin`.
///
/// This extension contains the Core Bluetooth callbacks that are invoked as the central manager changes
/// state, discovers peripherals, and manages connections. It also contains the scan-response buffering
/// helpers used to reconcile the initial advertisement packet with any subsequent scan response before a
/// discovered device is emitted to the Flutter side.
extension FlutterSplendidBlePlugin {
    
    // MARK: - CBCentralManagerDelegate Methods
    
    /// Invoked when the central manager's state is updated.
    /// This method is crucial as Bluetooth central operations can only be performed when the central's state is powered on.
    /// It is also used to emit the current permission and adapter status back to the Flutter side.
    /// - Parameter central: The central manager whose state has been updated.
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        emitCurrentBluetoothStatus()
    }

    /// Called when a peripheral is discovered while scanning.
    ///
    /// Adds the discovered peripheral to the map if it isn't already there and prepares the device
    /// information to be sent to Flutter.
    ///
    /// For connectable devices, CoreBluetooth may call this method twice in quick succession: once
    /// for the initial advertisement packet and once for the scan response. The scan response often
    /// carries additional data such as the complete local name or manufacturer payload. This method
    /// buffers the initial advertisement and schedules a fallback timeout so the device is always
    /// emitted even when CoreBluetooth only calls `didDiscover` once (which happens when the OS
    /// merges the two packets internally before delivery).
    ///
    /// - Parameters:
    ///   - central: The central manager providing this update.
    ///   - peripheral: The `CBPeripheral` that was discovered.
    ///   - advertisementData: A dictionary containing any advertisement and scan response data.
    ///   - RSSI: The received signal strength indicator (RSSI) value for the peripheral.
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        // If scan filters for appliance names have been specified, only continue with devices matching one of the names.
        guard scanNameFilters.isEmpty || scanNameFilters.contains(peripheral.name ?? "") else {
            return
        }
        
        // Add the peripheral to the map
        peripheralsMap[peripheral.identifier.uuidString] = peripheral
        
        // Determine if this is the first time we're seeing this device
        let isFirstDiscovery: Bool = !discoveredDevices.contains(peripheral.identifier)

        // Check if the device is connectable, which may indicate it supports scan responses
        let isConnectable: Bool = advertisementData[CBAdvertisementDataIsConnectable] as? Bool ?? false

        if isFirstDiscovery {
            discoveredDevices.insert(peripheral.identifier)

            if isConnectable {
                // Buffer the initial advertisement and schedule a fallback so the device is
                // emitted even if the scan response never arrives.
                partialAdvertisementData[peripheral.identifier] = (data: advertisementData, rssi: RSSI)
                scheduleFallbackEmit(for: peripheral)
                return
            }

            // Non-connectable devices do not send scan responses; emit now.
            emitDeviceDiscovery(peripheral: peripheral, advertisementData: advertisementData, rssi: RSSI)
        } else {
            // Subsequent callback for a known device. If we are still waiting for a scan
            // response (partial entry exists), this callback carries the merged advertisement
            // and scan response data. CoreBluetooth combines both packets into the
            // advertisementData dictionary transparently.
            if let partialData = partialAdvertisementData[peripheral.identifier] {
                // Scan response arrived in time - cancel the fallback.
                cancelFallbackEmit(for: peripheral.identifier)
                partialAdvertisementData.removeValue(forKey: peripheral.identifier)

                // Merge scan response keys over the initial advertisement data.
                var mergedAdvertisementData: [String: Any] = partialData.data
                for (key, value) in advertisementData {
                    mergedAdvertisementData[key] = value
                }

                emitDeviceDiscovery(peripheral: peripheral, advertisementData: mergedAdvertisementData, rssi: RSSI)
            }
            // Subsequent callbacks for already-emitted devices are ignored to avoid flooding
            // the Flutter side with repeated entries during a scan session.
        }
    }

    /// Schedules a fallback emission for a connectable device whose scan response may never arrive.
    ///
    /// If `scanResponseTimeoutSeconds` elapses without a subsequent `didDiscover` call, the buffered
    /// initial advertisement is emitted so the Flutter side still learns about the device.
    ///
    /// - Parameter peripheral: The peripheral whose initial advertisement is currently buffered.
    func scheduleFallbackEmit(for peripheral: CBPeripheral) {
        let peripheralId: UUID = peripheral.identifier
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            if let buffered = self.partialAdvertisementData.removeValue(forKey: peripheralId) {
                self.pendingFallbackWorkItems.removeValue(forKey: peripheralId)
                self.emitDeviceDiscovery(peripheral: peripheral, advertisementData: buffered.data, rssi: buffered.rssi)
            }
        }
        pendingFallbackWorkItems[peripheralId] = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.scanResponseTimeoutSeconds, execute: workItem)
    }

    /// Cancels the pending fallback emission for a specific peripheral.
    ///
    /// Called when the scan response arrives before the timeout, making the fallback unnecessary.
    ///
    /// - Parameter peripheralId: The UUID of the peripheral whose fallback should be cancelled.
    func cancelFallbackEmit(for peripheralId: UUID) {
        pendingFallbackWorkItems.removeValue(forKey: peripheralId)?.cancel()
    }

    /// Cancels all pending fallback emissions and removes them from the work item map.
    ///
    /// Called at the start of a new scan session or when scanning stops to prevent stale
    /// work items from firing after state has been cleared.
    func cancelAllPendingFallbacks() {
        for workItem in pendingFallbackWorkItems.values {
            workItem.cancel()
        }
        pendingFallbackWorkItems.removeAll()
    }

    /// Emits all buffered partial advertisement entries to Flutter and clears the buffer.
    ///
    /// Called when a scan session ends or restarts. Any connectable device that was buffered
    /// but never received a scan response is emitted with whatever data was available, so the
    /// Flutter side always receives a complete picture of nearby devices.
    func flushPartialAdvertisementData() {
        for (uuid, buffered) in partialAdvertisementData {
            if let peripheral = peripheralsMap[uuid.uuidString] {
                emitDeviceDiscovery(peripheral: peripheral, advertisementData: buffered.data, rssi: buffered.rssi)
            }
        }
    }

    /// Emits device discovery information to the Flutter/Dart side.
    ///
    /// This method formats the peripheral's advertisement data and sends it through the method channel
    /// to notify the Flutter side that a BLE device has been discovered.
    ///
    /// - Parameters:
    ///   - peripheral: The discovered `CBPeripheral` device.
    ///   - advertisementData: The complete advertisement data for the device.
    ///   - rssi: The received signal strength indicator (RSSI) value.
    func emitDeviceDiscovery(peripheral: CBPeripheral, advertisementData: [String: Any], rssi: NSNumber) {
        // Get a list of service UUIDs as strings, to be sent to the Dart side.
        let advertisedServiceUuids: [String]? = (advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID])?.map { $0.uuidString }

        // Create a dictionary with device details
        var deviceMap: [String: Any?] = [
            "name": peripheral.name,
            "address": peripheral.identifier.uuidString,
            "advertisedServiceUuids": advertisedServiceUuids,
            "rssi": rssi.intValue,
        ]

        // Extract the manufacturer data
        let manufacturerData: Data? = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data

        // Process the manufacturer data if it exists
        if let manufacturerData = manufacturerData {
            // Check that the data is at least 2 bytes long (to extract the manufacturer identifier)
            if manufacturerData.count >= 2 {
                // Extract the manufacturer identifier (first two bytes)
                let manufacturerIdData: Data = manufacturerData.subdata(in: 0..<2)
                // Extract the manufacturer-specific payload (the remaining bytes)
                let manufacturerPayloadData: Data = manufacturerData.subdata(in: 2..<manufacturerData.count)

                // Convert both the data parts into uppercase hexadecimal strings
                let manufacturerIdHex: String = manufacturerIdData.map { String(format: "%02X", $0) }.joined()
                let manufacturerPayloadHex: String = manufacturerPayloadData.map { String(format: "%02X", $0) }.joined()

                let formattedManufacturerData: String = "\(manufacturerIdHex)\(manufacturerPayloadHex)"

                deviceMap["manufacturerData"] = formattedManufacturerData
            }
        }

        // Send device information to Flutter side
        let jsonData: Data? = try? JSONSerialization.data(withJSONObject: deviceMap, options: [])
        if let jsonData = jsonData, let jsonString = String(data: jsonData, encoding: .utf8) {
            centralChannel.invokeMethod("bleDeviceScanned", arguments: jsonString)
        }
    }
    
    /// Called by the system when a connection to the peripheral is successfully established.
    ///
    /// This method triggers a callback to the Flutter side to inform it of the connection status.
    /// It is important for managing state on the Flutter side, such as updating UI elements or handling connected devices.
    /// - Parameters:
    ///   - central: The `CBCentralManager` that has initiated the connection.
    ///   - peripheral: The `CBPeripheral` to which the app has just successfully connected.
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        // Wait 100ms for macOS BLE stack to complete connection initialization
        // before reporting CONNECTED to Flutter
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.centralChannel.invokeMethod("bleConnectionState_\(peripheral.identifier.uuidString)", arguments: "CONNECTED")
        }
    }
    
    /// Called by the system when the central manager fails to create a connection with the peripheral.
    /// This delegate method is crucial for error handling and informing the user of a failed connection attempt.
    /// The method also communicates this failure back to the Flutter side so it can respond accordingly.
    /// - Parameters:
    ///   - central: The `CBCentralManager` that attempted the connection.
    ///   - peripheral: The `CBPeripheral` that the manager failed to connect to.
    ///   - error: An optional `Error` providing more details about the reason for the failure.
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        centralChannel.invokeMethod("bleConnectionState_\(peripheral.identifier.uuidString)", arguments: "FAILED")
    }
    
    /// Invoked when an existing connection with a peripheral is terminated, either by the peripheral or the system.
    ///
    /// This delegate method is essential for cleaning up resources and updating the application state in response to the disconnection.
    /// It also notifies the Flutter layer so that the UI and other app logic can be updated to reflect the disconnection.
    ///
    /// When a device disconnects, any pending notification state change operations are completed with an error to ensure
    /// proper cleanup and prevent resource leaks.
    ///
    /// - Parameters:
    ///   - central: The `CBCentralManager` that was connected to the peripheral.
    ///   - peripheral: The `CBPeripheral` that has disconnected.
    ///   - error: An optional `Error` that may contain the reason for the disconnection if it was not initiated by the user.
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        let deviceAddress: String = peripheral.identifier.uuidString

        // Fail any pending notification state changes for this device.
        let notificationKeysToRemove = pendingNotificationStateChanges.keys.filter { $0.hasPrefix("\(deviceAddress):") }
        for key in notificationKeysToRemove {
            if let pendingResult = pendingNotificationStateChanges.removeValue(forKey: key) {
                pendingResult(FlutterError(
                    code: "DISCONNECTED",
                    message: "Device disconnected during notification state change operation",
                    details: nil
                ))
            }
        }

        // Fail any pending write operations for this device. This covers the case where a
        // pairing-triggered write is in flight and the peripheral disconnects before the bond
        // is established, which would otherwise leave the Dart future hanging indefinitely.
        let writeKeysToRemove = pendingWriteResults.keys.filter { $0.hasPrefix("\(deviceAddress):") }
        for key in writeKeysToRemove {
            if let pendingResult = pendingWriteResults.removeValue(forKey: key) {
                pendingResult(FlutterError(
                    code: "DISCONNECTED",
                    message: "Device disconnected before write operation completed",
                    details: nil
                ))
            }
        }

        centralChannel.invokeMethod("bleConnectionState_\(deviceAddress)", arguments: "DISCONNECTED")
    }

    // MARK: CBPeripheralManagerDelegate methods
    
    /// Invoked when the central manager's state is updated.
    /// This method is crucial as Bluetooth peripheral operations can only be performed when the peripheral managers's state is powered on.
    /// It is also used to emit the current adapter status back to the Flutter side.
    /// - Parameter peripheral: The peripheral manager whose state has been updated.
    public func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        emitCurrentBluetoothStatus()
    }
}
