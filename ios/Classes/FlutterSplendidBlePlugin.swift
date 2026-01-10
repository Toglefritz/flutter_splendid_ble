import Flutter
import UIKit
import CoreBluetooth

/// `FlutterSplendidBlePlugin` serves as the central bridge between Flutter code in a Dart environment and the native Bluetooth capabilities on iOS devices.
/// It adheres to the `FlutterPlugin` protocol to interface with Flutter, and `CBCentralManagerDelegate` to interact with the iOS Bluetooth stack.
///
/// The design ensures that there is a single instance of `CBCentralManager` to maintain the state of the Bluetooth adapter across the entire application.
/// It's crucial to have only one `CBCentralManager` instance in order to manage and centralize the state and delegate callbacks for BLE operations consistently.
/// This is particularly important for operations like scanning, where the discovery of peripherals should be consistent with the instances used for actual communication.
/// Maintaining a single source of truth for peripheral instances avoids duplication and state inconsistencies.
public class FlutterSplendidBlePlugin: NSObject, FlutterPlugin, CBCentralManagerDelegate, CBPeripheralDelegate {
    /// A `FlutterMethodChannel` used for communication with the Dart side of the app.
    private var channel: FlutterMethodChannel!
    
    /// The central manager for managing BLE operations.
    ///
    /// `centralManager` is the core of Bluetooth functionality, acting as the central point for managing BLE operations. It must remain a single instance to manage
    /// the state and delegate callbacks for all BLE operations consistently.
    private var centralManager: CBCentralManager!
    
    /// A dictionary to store peripheral devices.
    ///
    /// The dictionary uses the peripheral's UUID string as the key and the `CBPeripheral` object as the value.
    /// This enables easy retrieval and management of peripheral connections.
    private var peripheralsMap: [String: CBPeripheral] = [:]
    
    /// A set of device names used to filter the results of a scan. Only devices with names appearing in this list will be returned by the scan.
    private var scanNameFilters: Set<String> = []
    
    // Holds the UUIDs of characteristics for which a read operation has been initiated.
    private var pendingReadRequests: [CBUUID: Bool] = [:]
    
    /// Initializes the `FlutterSplendidBlePlugin` and sets up the central manager.
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    /// registerWiths the plugin with the given registrar by creating a method channel and setting the current instance as its delegate.
    /// - Parameter registrar: The `FlutterPluginRegistrar` that handles plugin registration.
    public static func register(with registrar: FlutterPluginRegistrar) {
        let centralChannel = FlutterMethodChannel(name: "flutter_splendid_ble_central", binaryMessenger: registrar.messenger())
        
        let instance = FlutterSplendidBlePlugin()
        instance.channel = centralChannel
        registrar.addMethodCallDelegate(instance, channel: centralChannel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if isSharedMethod(call.method) {
            handleSharedMethod(call, result)
        } else if isCentralMethod(call.method) {
            handleCentralMethod(call, result)
        } else {
            // The provided method did not match any of those defined in MethodChannelMethods.swift
            result(FlutterMethodNotImplemented)
        }
    }
    
    /// A utility function to check if an incoming Method Channel call is related to shared functionality used for both the central
    /// and the peripheral roles. It returns true for shared device methods and false otherwise. This helps in routing the call to the correct handler.
    private func isSharedMethod(_ methodName: String) -> Bool {
        return SharedMethod.allCases.map { $0.rawValue }.contains(methodName)
    }
    
    /// A utility function to check if an incoming Method Channel call is related to central device functionality. It returns true for central
    /// device methods and false otherwise. This helps in routing the call to the correct handler.
    private func isCentralMethod(_ methodName: String) -> Bool {
        return CentralMethod.allCases.map { $0.rawValue }.contains(methodName)
    }
    
    /// Handles all Method Channel calls related to functionality that is shared between the BLE central and BLE peripheral device roles. This includes
    /// operations like requesting permissions and checking on the status of the host device's Bluetooth adapter.
    private func handleSharedMethod(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        switch call.method {
        case SharedMethod.requestBluetoothPermissions.rawValue:
            let permissionStatus: String = requestBluetoothPermissions().rawValue
            result(permissionStatus)
            
        case SharedMethod.emitCurrentPermissionStatus.rawValue:
            emitCurrentPermissionStatus()
            result(nil)
            
        case SharedMethod.checkBluetoothAdapterStatus.rawValue:
            // Check the status of the Bluetooth adapter
            let status = centralManager.state == .poweredOn ? "available" : "notAvailable"
            result(status)
            
        case SharedMethod.emitCurrentBluetoothStatus.rawValue:
            emitCurrentBluetoothStatus()
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    /// Handles all Method Channel calls related to functionality that is shared between the BLE central and BLE peripheral device roles. This includes
    /// operations like requesting permissions and checking on the status of the host device's Bluetooth adapter.
    private func handleCentralMethod(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        switch call.method {
        case CentralMethod.getConnectedDevices.rawValue:
            if let arguments = call.arguments as? [String: Any],
               let serviceUUIDs = arguments["serviceUUIDs"] as? [String] {
                let connectedDevices = getConnectedDevices(withServiceUUIDs: serviceUUIDs)
                result(connectedDevices)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENTS",
                                    message: "Expected a list of service UUIDs.",
                                    details: nil))
            }
            
        case CentralMethod.startScan.rawValue:
            var serviceUUIDs: [CBUUID]? = nil
            var options: [String: Any]? = nil
            
            if let args = call.arguments as? [String: Any] {
                // Handle Scan Filters
                var expectedDeviceNames: Set<String> = []
                if let filtersMap = args["filters"] as? [[String: Any]] {
                    // Service UUID filters
                    serviceUUIDs = filtersMap.compactMap { filterDict in
                        if let uuidStrings = filterDict["serviceUuids"] as? [String] {
                            return uuidStrings.compactMap { CBUUID(string: $0) }
                        }
                        return nil
                    }.flatMap { $0 }
                    
                    // Collect expected device names
                    for filter in filtersMap {
                        if let deviceName = filter["deviceName"] as? String {
                            expectedDeviceNames.insert(deviceName)
                        }
                    }
                    
                    self.scanNameFilters = expectedDeviceNames
                }
                
                // Handle Scan Settings
                if let settingsMap = args["settings"] as? [String: Any] {
                    // Configure options based on settingsMap if needed.
                    if let allowDuplicates = settingsMap["allowDuplicates"] as? Bool {
                        options = [CBCentralManagerScanOptionAllowDuplicatesKey: NSNumber(value: allowDuplicates)]
                    }
                    
                    // Note: iOS does not directly support scanMode and reportDelayMillis like Android does.
                    // These settings will be ignored.
                }
            }
            
            // Clear previous scan session data
            discoveredDevices.removeAll()
            partialAdvertisementData.removeAll()

            // Start scanning with optional service UUIDs and options.
            centralManager.scanForPeripherals(withServices: serviceUUIDs, options: options)
            result(nil)
            
        case CentralMethod.stopScan.rawValue:
            // Stop scanning for BLE devices
            centralManager.stopScan()
            // Clear scan session data
            discoveredDevices.removeAll()
            partialAdvertisementData.removeAll()
            result(nil)
            
        case CentralMethod.connect.rawValue:
            if let arguments = call.arguments as? [String: Any],
               let deviceAddress = arguments["address"] as? String {
                connect(deviceAddress: deviceAddress)
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Device address cannot be null.", details: nil))
            }
            
        case CentralMethod.disconnect.rawValue:
            if let arguments = call.arguments as? [String: Any],
               let deviceAddress = arguments["address"] as? String {
                disconnect(deviceAddress: deviceAddress)
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Device address cannot be null.", details: nil))
            }
            
        case CentralMethod.getCurrentConnectionState.rawValue:
            if let arguments = call.arguments as? [String: Any],
               let deviceAddress = arguments["address"] as? String {
                let connectionState = getCurrentConnectionState(deviceAddress: deviceAddress).lowercased()
                result(connectionState)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Device address cannot be null.", details: nil))
            }
            
        case CentralMethod.discoverServices.rawValue:
            guard let args = call.arguments as? [String: Any],
                  let deviceAddress = args["address"] as? String,
                  let peripheral = peripheralsMap[deviceAddress] else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Device address cannot be null.", details: nil))
                return
            }
            peripheral.delegate = self
            peripheral.discoverServices(nil)
            result(nil)
            
        case CentralMethod.writeCharacteristic.rawValue:
            // First, ensure that we're dealing with a dictionary of arguments.
            guard let arguments = call.arguments as? [String: Any] else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Arguments are not in the expected format", details: nil))
                return
            }
            
            // Extract arguments safely.
            guard let deviceAddress = arguments["address"] as? String,
                  let characteristicUuidStr = arguments["characteristicUuid"] as? String,
                  let stringValue = arguments["value"] as? String,
                  let peripheral = getPeripheralByIdentifier(deviceAddress: deviceAddress),
                  let characteristicUuid = UUID(uuidString: characteristicUuidStr),
                  let characteristic = getCharacteristicByUuid(peripheral: peripheral, uuid: characteristicUuid) else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Device address, characteristic UUID, or value cannot be null.", details: nil))
                return
            }
            
            let dataValue = Data(stringValue.utf8)
            let writeTypeValue = arguments["writeType"] as? Int ?? CBCharacteristicWriteType.withResponse.rawValue
            guard let writeType = CBCharacteristicWriteType(rawValue: writeTypeValue) else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid write type provided.", details: nil))
                return
            }
            
            peripheral.writeValue(dataValue, for: characteristic, type: writeType)
            result(nil)
            
        case CentralMethod.readCharacteristic.rawValue:
            guard let arguments = call.arguments as? [String: Any],
                  let characteristicUuidStr = arguments["characteristicUuid"] as? String,
                  let deviceAddress = arguments["address"] as? String,
                  let peripheral = getPeripheralByIdentifier(deviceAddress: deviceAddress),
                  let characteristicUuid = UUID(uuidString: characteristicUuidStr),
                  let characteristic = getCharacteristicByUuid(peripheral: peripheral, uuid: characteristicUuid) else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Device address or characteristic UUID cannot be null", details: nil))
                return
            }
            
            setReadRequestFlag(for: characteristic)
            peripheral.readValue(for: characteristic)
            result(nil)
            
        case CentralMethod.subscribeToCharacteristic.rawValue:
            subscribeToCharacteristic(call: call, result: result)
            
        case CentralMethod.unsubscribeFromCharacteristic.rawValue:
            unsubscribeFromCharacteristic(call: call, result: result)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - CBCentralManagerDelegate Methods
    
    /// Invoked when the central manager's state is updated.
    /// This method is crucial as Bluetooth operations can only be performed when the central's state is powered on.
    /// It is also used to emit the current permission and adapter status back to the Flutter side.
    /// - Parameter central: The central manager whose state has been updated.
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        emitCurrentPermissionStatus()
    }

    /// Gets a list of Bluetooth devices that are currently connected to the device.
    ///
    /// This function accepts a list of service UUIDs used to filter the list of connected BLE devices to return. This list must contain at least one UUID because requesting
    /// connected devices without providing a service UUID will always return an empty list (it is asking for a list of Bluetooth devices that do not have any services, which
    /// is always an empty list).
    ///
    /// - Returns: A list of connected devices.
    private func getConnectedDevices(withServiceUUIDs serviceUUIDs: [String]) -> [[String: String]] {
        let uuids = serviceUUIDs.map { CBUUID(string: $0) }
        let connectedPeripherals = centralManager.retrieveConnectedPeripherals(withServices: uuids)
        
        return connectedPeripherals.map { peripheral in
            [
                "name": peripheral.name ?? "Unknown",
                "identifier": peripheral.identifier.uuidString
            ]
        }
    }
    
    // A list of UUIDs discovered by the scanning process. This is used to determine if a peripheral about which data is sent in the didDiscover method
    // below, was discovered previously. This information is, in turn, used to infer if a device has sent additional information to the device in a
    // scan response.
    var discoveredDevices: [UUID] = []
    
    /// Called when a peripheral is discovered while scanning.
    ///
    /// Adds the discovered peripheral to the map if it isn't already there and prepares the device information to be sent to Flutter.
    /// - Parameters:
    ///   - central: The central manager providing this update.
    ///   - peripheral: The `CBPeripheral` that was discovered.
    ///   - advertisementData: A dictionary containing any advertisement and scan response data.
    ///   - RSSI: The received signal strength indicator (RSSI) value for the peripheral.
    ///
    /// This function handles the discovery of BLE peripherals during a scan. It processes the advertisement data received from the peripheral
    /// and prepares the device information to be sent to the Dart side of a Flutter application. The function supports BLE peripherals with
    /// scannable advertisement data by leveraging the OS's automatic scan request mechanism.
    ///
    /// For BLE peripherals that support scannable advertisement data, the OS will automatically make a scan request after receiving the initial
    /// advertisement packet. As a result, the `didDiscover` function will be called twice in quick succession for these devices:
    ///
    /// 1. The first call is triggered by the initial advertisement packet.
    /// 2. The second call is triggered by the scan response packet.
    ///
    /// When this happens, the `CBPeripheral` will include additional advertisement data in the scan response, combining it with the initial data.
    /// The function tracks the advertisement data for each discovered peripheral and waits for the scan response before sending the complete
    /// data to the Dart side. This ensures that all relevant advertisement data, including manufacturer data, is captured and processed.
    ///
    /// The function uses two dictionaries to achieve this:
    /// - `partialAdvertisementData`: Stores partial advertisement data for each peripheral.
    /// - `scanResponseReceived`: Tracks whether the scan response has been received for each peripheral.
    ///
    /// The function checks the type of advertisement packet to determine if it should expect more data in a scan response. If the scan response
    /// has been received, the function combines the initial advertisement data with the scan response data and sends the complete information
    /// to the Dart side.
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
            // Mark this device as discovered
            discoveredDevices.insert(peripheral.identifier)

            // If the device is connectable, it might send a scan response. Store the initial data and wait.
            if isConnectable {
                partialAdvertisementData[peripheral.identifier] = (data: advertisementData, rssi: RSSI)
                return // Don't emit yet - wait for potential scan response
            }

            // Device is not connectable, so no scan response is expected. Emit immediately.
            emitDeviceDiscovery(peripheral: peripheral, advertisementData: advertisementData, rssi: RSSI)
        } else {
            // This is a subsequent discovery - likely a scan response or duplicate advertisement

            // Check if we have stored partial data (meaning we're waiting for scan response)
            if let partialData = partialAdvertisementData[peripheral.identifier] {
                // This is the scan response. Merge the data and emit.
                var mergedAdvertisementData: [String: Any] = partialData.data

                // Merge the scan response data into the initial advertisement data
                for (key, value) in advertisementData {
                    mergedAdvertisementData[key] = value
                }

                // Clean up the partial data storage
                partialAdvertisementData.removeValue(forKey: peripheral.identifier)

                // Emit the complete device information with merged data
                emitDeviceDiscovery(peripheral: peripheral, advertisementData: mergedAdvertisementData, rssi: RSSI)
            } else {
                // We've seen this device before but aren't waiting for scan response
                // This is a duplicate advertisement - emit it
                emitDeviceDiscovery(peripheral: peripheral, advertisementData: advertisementData, rssi: RSSI)
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
    private func emitDeviceDiscovery(peripheral: CBPeripheral, advertisementData: [String: Any], rssi: NSNumber) {
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
            channel.invokeMethod("bleDeviceScanned", arguments: jsonString)
        }
    }
    
    /// Called by the system when a connection to the peripheral is successfully established.
    ///
    /// This method triggers a callback to the Flutter side to inform it of the connection status.
    ///
    /// ## Important: Connection Readiness and Race Conditions
    ///
    /// When this delegate method is called, the physical BLE connection has been established,
    /// but the iOS BLE stack may still be performing internal initialization steps such as:
    /// - MTU negotiation (handled automatically by iOS)
    /// - Connection parameter updates
    /// - Internal state synchronization
    ///
    /// Immediately reporting CONNECTED to Flutter at this point can cause race conditions where
    /// Flutter attempts to write to characteristics before the connection is fully ready, resulting
    /// in write failures or hangs.
    ///
    /// To prevent this, we introduce a small delay (100ms) before reporting CONNECTED to Flutter.
    /// This allows the iOS BLE stack to complete its initialization sequence. This delay is:
    /// - Short enough to not impact user experience
    /// - Long enough for iOS to complete connection initialization
    /// - Consistent with Apple's recommended best practices for BLE connections
    ///
    /// ## Alternative Approaches Considered
    ///
    /// - **Waiting for service discovery**: Too slow and requires explicit service discovery
    /// - **Checking maximumWriteValueLength**: Not reliable as it may not update immediately
    /// - **Using peripheral.state**: Already in .connected state at this callback
    ///
    /// The delayed approach is simple, reliable, and used by many production BLE applications.
    ///
    /// - Parameters:
    ///   - central: The `CBCentralManager` that has initiated the connection.
    ///   - peripheral: The `CBPeripheral` to which the app has just successfully connected.
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        // Wait 100ms for iOS BLE stack to complete connection initialization
        // before reporting CONNECTED to Flutter
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.channel.invokeMethod("bleConnectionState_\(peripheral.identifier.uuidString)", arguments: "CONNECTED")
        }
    }
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        channel.invokeMethod("bleConnectionState_\(peripheral.identifier.uuidString)", arguments: "FAILED")
    }
    
    /// Invoked when an existing connection with a peripheral is terminated, either by the peripheral or the system.
    /// This delegate method is essential for cleaning up resources and updating the application state in response to the disconnection.
    /// It also notifies the Flutter layer so that the UI and other app logic can be updated to reflect the disconnection.
    /// - Parameters:
    ///   - central: The `CBCentralManager` that was connected to the peripheral.
    ///   - peripheral: The `CBPeripheral` that has disconnected.
    ///   - error: An optional `Error` that may contain the reason for the disconnection if it was not initiated by the user.
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        channel.invokeMethod("bleConnectionState_\(peripheral.identifier.uuidString)", arguments: "DISCONNECTED")
    }
    
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
    /// This callback is triggered as a response to a call to `setNotifyValue(_:for:)` on a `CBPeripheral` instance,
    /// indicating whether notifications or indications are enabled or disabled for a given characteristic.
    /// If there's an error, it is handled internally, and further error handling or user notification may be implemented as needed.
    /// Upon a successful update, additional logic to handle the new notification state can be implemented.
    /// - Parameters:
    ///   - peripheral: The `CBPeripheral` providing this update, representing the BLE device whose characteristic's notification state has changed.
    ///   - characteristic: The `CBCharacteristic` for which the notification state has been updated.
    ///   - error: An optional `Error` object that contains the reason for the failure if the notification state update was unsuccessful.
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            channel.invokeMethod("error", arguments: "Failed to update notification state for characteristic \(characteristic.uuid): \(error!.localizedDescription)")
            return
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

        if let error = error {
            // Write failed - notify Flutter with error details
            let errorMap: [String: Any] = [
                "deviceAddress": deviceAddress,
                "characteristicUuid": characteristic.uuid.uuidString,
                "success": false,
                "error": "Failed to write characteristic: \(error.localizedDescription)"
            ]
            channel.invokeMethod("onCharacteristicWrite", arguments: errorMap)
        } else {
            // Write succeeded - notify Flutter
            let successMap: [String: Any] = [
                "deviceAddress": deviceAddress,
                "characteristicUuid": characteristic.uuid.uuidString,
                "success": true
            ]
            channel.invokeMethod("onCharacteristicWrite", arguments: successMap)
        }
    }

    // MARK: Bluetooth Permissions Helper Methods
    
    /// The methods in this section manage Bluetooth permissions on an iOS device and communicate statuses to the Dart side of a Flutter app.
    ///
    /// Methods in this section are responsible for requesting and checking Bluetooth permissions on iOS devices.
    /// They allow the Dart side of a Flutter application to respond in real-time to changes in Bluetooth permission statuses.
    ///
    /// ## Adding Necessary Keys to Info.plist
    /// In order to request Bluetooth permissions on iOS, you need to add the following keys to your `Info.plist` file:
    ///
    /// - `NSBluetoothAlwaysUsageDescription`: A message describing why the app needs the Bluetooth permission, shown in the permission dialog.
    /// - `NSBluetoothPeripheralUsageDescription`: Another message describing why the app needs to connect to Bluetooth peripherals, shown in the permission dialog.
    ///
    /// ```xml
    /// <key>NSBluetoothAlwaysUsageDescription</key>
    /// <string>We need Bluetooth access to connect to BLE devices.</string>
    /// <key>NSBluetoothPeripheralUsageDescription</key>
    /// <string>We need Bluetooth access to communicate with BLE devices.</string>
    /// ```
    
    /// Requests and checks the Bluetooth permission status.
    ///
    /// This method returns the Bluetooth permission status. It uses the authorization property of the CBCentralManager to determine
    /// the current authorization status.
    ///
    /// - Returns: BluetoothPermissionStatus indicating the current permission status. (.granted, .denied, or .unknown)
    private func requestBluetoothPermissions() -> BluetoothPermissionStatus {
        if #available(iOS 13.0, *) {
            switch centralManager.authorization {
            case .allowedAlways:
                return .granted
            case .denied:
                return .denied
            default:
                return .unknown
            }
        } else {
            return .unknown
        }
    }
    
    /// Sends the current Bluetooth permission status to the Dart side.
    ///
    /// This method checks the current Bluetooth permission status and sends it to the Dart side via the FlutterMethodChannel.
    /// It uses the `requestBluetoothPermissions()` method to get the current status.
    private func emitCurrentPermissionStatus() {
        let status: String = requestBluetoothPermissions().rawValue
        // Invoke method on Flutter side
        channel.invokeMethod("permissionStatusUpdated", arguments: status)
    }
    
    // MARK: Adapter Status Helper Methods
    
    ///  The methods in this section manage the Bluetooth adapter on an iOS device and communicates its status to the Dart side of a Flutter app.
    ///
    ///  This section is responsible for managing the Bluetooth adapter's status on the iOS device. It can check the current status of the Bluetooth adapter, and also listen for changes to the adapter's status. This allows the Dart side of a Flutter application to respond in real-time to changes in the Bluetooth adapter's status.
    ///  The class uses the CoreBluetooth library to interact with the Bluetooth adapter and EventChannel.EventSink to communicate with the Dart side.
    
    /// Checks and returns the Bluetooth adapter status.
    ///
    /// This method queries the `CBCentralManager`'s `state` to determine the current status of the Bluetooth adapter on the iOS device. It returns a `BluetoothStatus` enumeration, indicating whether the adapter is not available, enabled, or disabled.
    /// - NotAvailable: Bluetooth is unsupported on the hardware.
    /// - Enabled: Bluetooth is powered on and functional.
    /// - Disabled: Bluetooth is in any state other than powered on (e.g., powered off, resetting, unauthorized, or unknown).
    ///
    /// The result is used within the `FlutterSplendidBlePlugin` to inform the Dart side about the adapter's status, which is crucial for managing Bluetooth operations such as scanning, connecting, and interacting with peripherals.
    ///
    /// - Returns: A `BluetoothStatus` enumeration that represents the current status of the Bluetooth adapter.
    func checkBluetoothAdapterStatus() -> BluetoothStatus {
        switch centralManager.state {
        case .unsupported:
            return .notAvailable
        case .poweredOn:
            return .enabled
        default:
            return .disabled
        }
    }
    
    /// Emits the current Bluetooth adapter status to the Dart side of the Flutter application.
    ///
    /// This function calls `checkBluetoothAdapterStatus` to obtain the current state of the Bluetooth adapter.
    /// It then converts this status into a raw value which represents a string understandable on the Dart side.
    /// This string is then sent over the FlutterMethodChannel to inform the Flutter application about the
    /// current status of the Bluetooth adapter, which can be one of the following:
    /// - "notAvailable": The device hardware does not support Bluetooth.
    /// - "enabled": The Bluetooth is turned on and ready for communication.
    /// - "disabled": The Bluetooth is not available for use (turned off, in an error state, etc.).
    ///
    /// The status is important for the Flutter application to handle UI updates accordingly and to manage
    /// Bluetooth operations based on the availability of the Bluetooth adapter.
    ///
    /// This method ensures that the Dart side is always synchronized with the actual state of the iOS device's
    /// Bluetooth adapter, enabling a reactive UI that responds correctly to state changes.
    ///
    /// - Note: This method should be invoked whenever the Bluetooth adapter's state changes, or when
    ///         the Dart side needs to recheck the adapter status (e.g., when the app resumes from the background).
    func emitCurrentBluetoothStatus() {
        let status = self.checkBluetoothAdapterStatus().rawValue
        // Invoke method on Flutter side
        channel.invokeMethod("adapterStateUpdated", arguments: status)
    }
    
    // MARK: Device Interface Helper Methods
    /// The methods in this section collectively serve as an interface for managing connections and interactions with BLE devices and communicating
    /// with Bluetooth devices.
    ///
    /// The methods in this section are responsible for establishing and terminating connections to BLE devices.
    
    /// Initiates a connection to a Bluetooth Low Energy (BLE) device.
    ///
    /// This function tries to initiate a connection to a BLE peripheral device with the provided UUID string.
    /// If the peripheral is not found in the `peripheralsMap`, an error is sent through the method channel.
    ///
    /// - Parameter deviceAddress: The UUID string of the peripheral device to connect to.
    func connect(deviceAddress: String) {
        guard let peripheral = peripheralsMap[deviceAddress] else {
            channel.invokeMethod("error", arguments: "Device not found.")
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
            channel.invokeMethod("error", arguments: "Device not found.")
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
            channel.invokeMethod("error", arguments: "Device not found.")
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
    private func subscribeToCharacteristic(call: FlutterMethodCall, result: @escaping FlutterResult) {
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
            peripheral.setNotifyValue(true, for: characteristic)
            result(nil) // Indicate that the request was processed
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
            peripheral.setNotifyValue(false, for: characteristic)
            result(nil) // Success
        } else {
            result(FlutterError(code: "SUBSCRIBE_ERROR",
                                message: "Failed to unsubscribe from characteristic: Characteristic not found.",
                                details: nil))
        }
    }
    
    // MARK: Utility Methods
    
    // Utility method to get a CBPeripheral by its identifier
    private func getPeripheralByIdentifier(deviceAddress: String) -> CBPeripheral? {
        guard let peripheral = peripheralsMap[deviceAddress] else {
            channel.invokeMethod("error", arguments: "Device not found.")
            return nil
        }
        
        return peripheral
    }
    
    // Utility method to find a characteristic on a peripheral by its UUID
    private func getCharacteristicByUuid(peripheral: CBPeripheral, uuid: UUID) -> CBCharacteristic? {
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
