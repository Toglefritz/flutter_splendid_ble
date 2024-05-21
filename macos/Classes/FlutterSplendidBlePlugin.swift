import Cocoa
import FlutterMacOS
import CoreBluetooth

/// `FlutterSplendidBlePlugin` serves as the central bridge between Flutter code in a Dart environment and the native Bluetooth capabilities on MacOS devices.
/// It adheres to the `FlutterPlugin` protocol to interface with Flutter, and `CBCentralManagerDelegate` to interact with the MacOS Bluetooth stack.
///
/// The design ensures that there is a single instance of `CBCentralManager` to maintain the state of the Bluetooth adapter across the entire application.
/// It's crucial to have only one `CBCentralManager` instance in order to manage and centralize the state and delegate callbacks for BLE operations consistently.
/// This is particularly important for operations like scanning, where the discovery of peripherals should be consistent with the instances used for actual communication.
/// Maintaining a single source of truth for peripheral instances avoids duplication and state inconsistencies.
public class FlutterSplendidBlePlugin: NSObject, FlutterPlugin, CBCentralManagerDelegate, CBPeripheralDelegate, CBPeripheralManagerDelegate {
    
    /// A `FlutterMethodChannel` used for communication with the Dart side of the app for functionality in which the app acts as a BLE central device.
    private var centralChannel: FlutterMethodChannel!
    
    /// A `FlutterMethodChannel` used for communication with the Dart side of the app for functionality in which the app acts as a BLE peripheral device.
    private var peripheralChannel: FlutterMethodChannel!
    
    /// The central manager for managing BLE operations involving the app acting as a BLE central device.
    ///
    /// `centralManager` is the core of BLE central functionality, acting as the central point for managing BLE operations. It must remain a single instance to manage
    /// the state and delegate callbacks for all BLE operations consistently.
    private var centralManager: CBCentralManager!
    
    /// The peripheral manager for managing BLE operations involving the app acting as a BLE perpipheral device.
    ///
    /// `peripheralManager` is the core of BLE peripheral functionality, acting as the central point for managing BLE operations. It must remain a single instance to manage
    /// the state and delegate callbacks for all BLE operations consistently.
    private var peripheralManager: CBPeripheralManager?
    
    /// A dictionary to store peripheral devices.
    ///
    /// The dictionary uses the peripheral's UUID string as the key and the `CBPeripheral` object as the value.
    /// This enables easy retrieval and management of peripheral connections.
    private var peripheralsMap: [String: CBPeripheral] = [:]
    
    /// An optional `FlutterEventSink` which allows for sending scanning result data back to the Flutter side in real-time.
    private var scanResultSink: FlutterEventSink?
    
    // Holds the UUIDs of characteristics for which a read operation has been initiated.
    private var pendingReadRequests: [CBUUID: Bool] = [:]
    
    /// Initializes the `FlutterBlePlugin` and sets up the central manager.
    override init() {
        super.init()
        // Initialize the central manager.
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        // Initialize the peripheral manager.
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        
    }
    
    /// Registers the plugin with the given registrar by creating a method channel and setting the current instance as its delegate.
    /// - Parameter registrar: The `FlutterPluginRegistrar` that handles plugin registration.
    public static func register(with registrar: FlutterPluginRegistrar) {
        let centralChannel = FlutterMethodChannel(name: "flutter_splendid_ble_central", binaryMessenger: registrar.messenger)
        let peripheralChannel = FlutterMethodChannel(name: "flutter_splendid_ble_peripheral", binaryMessenger: registrar.messenger)
        let instance = FlutterSplendidBlePlugin()
        instance.centralChannel = centralChannel
        instance.peripheralChannel = peripheralChannel
        registrar.addMethodCallDelegate(instance, channel: centralChannel)
        registrar.addMethodCallDelegate(instance, channel: peripheralChannel)
    }
    
    /// This function is the entry point for handling Method Channel calls in the Flutter plugin. It routes incoming calls to the appropriate
    /// handler based on whether the call pertains to central or peripheral functionality. It uses the `isCentralMethod` and
    /// `isPeripheralMethod` functions to determine the correct routing.
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if isSharedMethod(call.method) {
            handleSharedMethod(call, result)
        } else if isCentralMethod(call.method) {
            handleCentralMethod(call, result)
        } else if isPeripheralMethod(call.method) {
            handlePeripheralMethod(call, result)
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
    
    /// A utility function to check if an incoming Method Channel call is related to peripheral device functionality. It returns true for peripheral
    /// device methods and false otherwise. This helps in routing the call to the correct handler.
    private func isPeripheralMethod(_ methodName: String) -> Bool {
        return PeripheralMethod.allCases.map { $0.rawValue }.contains(methodName)
    }
    
    /// Handles all Method Channel calls related to functionalityh that is shared beteen the BLE central and BLE peripheral device roles. This includes
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
            // Check the status of the Bluetooth adapter. The `centralManager` is used for this purpose since
            // the adapter status should be the same for either the `centralManager` or `peripheralManager`.
            let status = centralManager.state == .poweredOn ? "available" : "notAvailable"
            result(status)
            
        case SharedMethod.emitCurrentBluetoothStatus.rawValue:
            emitCurrentBluetoothStatus()
            result(nil)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    
    /// Handles all Method Channel calls related to the BLE central device functionality. This includes operations like scanning for BLE
    /// devices, connecting to them, and managing BLE interactions as a central device.
    private func handleCentralMethod(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        switch call.method {
        case CentralMethod.startScan.rawValue:
            // Start scanning for BLE devices
            centralManager.scanForPeripherals(withServices: nil, options: nil)
            result(nil)
            
        case CentralMethod.stopScan.rawValue:
            // Stop scanning for BLE devices
            centralManager.stopScan()
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
    
    /// Manages Method Channel calls specific to BLE peripheral device operations. It handles tasks where the host device acts as a
    /// BLE peripheral, such as advertising BLE services and managing connections from central devices.
    private func handlePeripheralMethod(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        switch call.method {
        case PeripheralMethod.createPeripheralServer.rawValue:
            if let configurationMap = call.arguments as? [String: Any] {
                do {
                    try createPeripheralServer(with: configurationMap)
                    result(nil) // Indicate success
                } catch let error as NSError {
                    // Handle the thrown error and return a FlutterError
                    result(FlutterError(code: "SERVER_CREATION_FAILED",
                                        message: "Failed to create peripheral server: \(error.localizedDescription)",
                                        details: error))
                }
            } else {
                result(FlutterError(code: "INVALID_ARGUMENTS",
                                    message: "Invalid or missing configuration for peripheral server",
                                    details: nil))
            }
        case PeripheralMethod.startAdvertising.rawValue:
            if let configurationMap = call.arguments as? [String: Any] {
                do {
                    try startAdvertising(with: configurationMap)
                    result(nil) // Indicate success
                } catch let error as NSError {
                    // Handle the thrown error and return a FlutterError
                    result(FlutterError(code: "START_ADVERTISING_FAILED",
                                        message: "Failed to start advertising: \(error.localizedDescription)",
                                        details: error))
                }
            } else {
                result(FlutterError(code: "INVALID_ARGUMENTS",
                                    message: "Invalid or missing configuration for peripheral server",
                                    details: nil))
            }
        case PeripheralMethod.stopAdvertising.rawValue:
            stopAdvertising()
            result(nil) // Indicate success
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - CBCentralManagerDelegate Methods
    
    /// Invoked when the central manager's state is updated.
    /// This method is crucial as Bluetooth central operations can only be performed when the central's state is powered on.
    /// It is also used to emit the current permission and adapter status back to the Flutter side.
    /// - Parameter central: The central manager whose state has been updated.
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        emitCurrentBluetoothStatus()
    }
    
    /// Called when a peripheral is discovered while scanning.
    /// Adds the discovered peripheral to the map if it isn't already there and prepares the device information to be sent to Flutter.
    /// - Parameters:
    ///   - central: The central manager providing this update.
    ///   - peripheral: The `CBPeripheral` that was discovered.
    ///   - advertisementData: A dictionary containing any advertisement and scan response data.
    ///   - RSSI: The received signal strength indicator (RSSI) value for the peripheral.
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        // Add the peripheral to the map
        peripheralsMap[peripheral.identifier.uuidString] = peripheral
        
        // Extract the manufacturer data
        let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data
        
        // Create a dictionary with device details
        var deviceMap: [String: Any?] = [
            "name": peripheral.name,
            "address": peripheral.identifier.uuidString,
            "rssi": RSSI.intValue,
        ]
        
        // Get manufacturer data and add it to the map
        if let manufacturerData = manufacturerData {
            deviceMap["manufacturerData"] = manufacturerData.hexString
        }
        
        // Send device information to Flutter side
        let jsonData = try? JSONSerialization.data(withJSONObject: deviceMap, options: [])
        if let jsonData = jsonData, let jsonString = String(data: jsonData, encoding: .utf8) {
            centralChannel.invokeMethod("bleDeviceScanned", arguments: jsonString)
        }
    }
    
    /// Called by the system when a connection to the peripheral is successfully established.
    /// This method triggers a callback to the Flutter side to inform it of the connection status.
    /// It is important for managing state on the Flutter side, such as updating UI elements or handling connected devices.
    /// - Parameters:
    ///   - central: The `CBCentralManager` that has initiated the connection.
    ///   - peripheral: The `CBPeripheral` to which the app has just successfully connected.
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        centralChannel.invokeMethod("bleConnectionState_\(peripheral.identifier.uuidString)", arguments: "CONNECTED")
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
    /// This delegate method is essential for cleaning up resources and updating the application state in response to the disconnection.
    /// It also notifies the Flutter layer so that the UI and other app logic can be updated to reflect the disconnection.
    /// - Parameters:
    ///   - central: The `CBCentralManager` that was connected to the peripheral.
    ///   - peripheral: The `CBPeripheral` that has disconnected.
    ///   - error: An optional `Error` that may contain the reason for the disconnection if it was not initiated by the user.
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        centralChannel.invokeMethod("bleConnectionState_\(peripheral.identifier.uuidString)", arguments: "DISCONNECTED")
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
            centralChannel.invokeMethod("error", arguments: "Service discovery failed: \(error!.localizedDescription)")
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
            centralChannel.invokeMethod("error", arguments: "Characteristics discovery failed for service \(service.uuid): \(error!.localizedDescription)")
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
        centralChannel.invokeMethod("bleServicesDiscovered_\(peripheral.identifier.uuidString)", arguments: serviceData)
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
            centralChannel.invokeMethod("error", arguments: "Failed to update notification state for characteristic \(characteristic.uuid): \(error!.localizedDescription)")
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
            centralChannel.invokeMethod("error", arguments: "Failed to update value for characteristic \(characteristic.uuid): \(error!.localizedDescription)")
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
            centralChannel.invokeMethod("onCharacteristicRead", arguments: characteristicMap)
            clearReadResponseFlag(characteristic: characteristic)
        } else {
            // This is a notification update
            centralChannel.invokeMethod("onCharacteristicChanged", arguments: characteristicMap)
        }
    }
    
    // MARK: CBPeripheralManagerDelegate methods
    
    /// Invoked when the central manager's state is updated.
    /// This method is crucial as Bluetooth peripheral operations can only be performed when the peripheral managers's state is powered on.
    /// It is also used to emit the current adapter status back to the Flutter side.
    /// - Parameter peripheral: The peripheral manager whose state has been updated.
    public func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        emitCurrentBluetoothStatus()
    }
    
    // MARK: Bluetooth Permissions Helper Methods
    
    /// The methods in this section manage Bluetooth permissions on a macOS device and communicate statuses to the Dart side of a Flutter app.
    ///
    /// Methods in this section are responsible for requesting and checking Bluetooth permissions on macOS devices.
    /// They allow the Dart side of a Flutter application to respond in real-time to changes in Bluetooth permission statuses.
    ///
    /// ## Adding Necessary Keys to Info.plist
    /// In order to request Bluetooth permissions on macOS, you need to add the following keys to your `Info.plist` file:
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
        switch centralManager.authorization {
        case .allowedAlways:
            return .granted
        case .denied:
            return .denied
        default:
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
        centralChannel.invokeMethod("permissionStatusUpdated", arguments: status)
        peripheralChannel.invokeMethod("permissionStatusUpdated", arguments: status)
    }
    
    // MARK: Adapter Status Helper Methods
    
    ///  The methods in this section manage the Bluetooth adapter on a MacOS device and communicates its status to the Dart side of a Flutter app.
    ///
    ///  This section is responsible for managing the Bluetooth adapter's status on the MacOS device. It can check the current status of the Bluetooth adapter, and also listen for changes to the adapter's status. This allows the Dart side of a Flutter application to respond in real-time to changes in the Bluetooth adapter's status.
    ///  The class uses the CoreBluetooth library to interact with the Bluetooth adapter and EventChannel.EventSink to communicate with the Dart side.
    
    /// Checks and returns the Bluetooth adapter status.
    ///
    /// This method queries the `CBCentralManager`'s `state` to determine the current status of the Bluetooth adapter on the macOS device. It returns a `BluetoothStatus` enumeration, indicating whether the adapter is not available, enabled, or disabled.
    /// - NotAvailable: Bluetooth is unsupported on the hardware.
    /// - Enabled: Bluetooth is powered on and functional.
    /// - Disabled: Bluetooth is in any state other than powered on (e.g., powered off, resetting, unauthorized, or unknown).
    ///
    /// The result is used within the `FlutterBlePlugin` to inform the Dart side about the adapter's status, which is crucial for managing Bluetooth operations such as scanning, connecting, and interacting with peripherals.
    ///
    /// - Returns: A `BluetoothStatus` enumeration that represents the current status of the Bluetooth adapter.
    func checkBluetoothAdapterStatus() -> BluetoothStatus {
        switch centralManager.state {
        case .unsupported:
            return .notAvailable
        case .unauthorized:
            return .notAvailable
        case .unknown:
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
    /// This method ensures that the Dart side is always synchronized with the actual state of the macOS device's
    /// Bluetooth adapter, enabling a reactive UI that responds correctly to state changes.
    ///
    /// - Note: This method should be invoked whenever the Bluetooth adapter's state changes, or when
    ///         the Dart side needs to recheck the adapter status (e.g., when the app resumes from the background).
    func emitCurrentBluetoothStatus() {
        let status = self.checkBluetoothAdapterStatus().rawValue
        // Invoke method on Flutter side
        centralChannel.invokeMethod("adapterStateUpdated", arguments: status)
        peripheralChannel.invokeMethod("adapterStateUpdated", arguments: status)
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
    
    // MARK: - CBPeripheralManager Methods
    
    /// An enumeration of errors that can result from attempts to create a BLE peripheral service via the `createPeripheralServer` function.
    enum PeripheralServerError: Error {
        case invalidConfiguration
        case invalidServiceUuid
        case invalidCharacteristicUuid
    }
    
    /// Creates a BLE peripheral server with specified configuration.
    /// - Parameter configurationMap: A map containing the server configuration details.
    /// - Throws: An error if the configuration is invalid or the server setup fails.
    func createPeripheralServer(with configurationMap: [String: Any]) throws {
        // Get arguments sent from the Flutter side.
        guard let primaryServiceUuidStr = configurationMap["primaryServiceUuid"] as? String,
              let primaryServiceUuid = UUID(uuidString: primaryServiceUuidStr),
              let serviceUuidsStr = configurationMap["serviceUuids"] as? [String],
              let characteristicsArray = configurationMap["characteristics"] as? [[String: Any]] else {
            throw PeripheralServerError.invalidConfiguration
        }
        
        // Create a primary service with the provided UUID.
        let primaryService = CBMutableService(type: CBUUID(nsuuid: primaryServiceUuid), primary: true)
        
        // Create and add characteristics to the primary service.
        var primaryServiceCharacteristics = [CBMutableCharacteristic]()
        for characteristicInfo in characteristicsArray {
            guard let uuidStr = characteristicInfo["uuid"] as? String,
                  let propertiesArray = characteristicInfo["properties"] as? [String],
                  let permissionsArray = characteristicInfo["permissions"] as? [String] else {
                throw PeripheralServerError.invalidCharacteristicUuid
            }
            
            let uuid = CBUUID(string: uuidStr)
            
            let properties = CBCharacteristicProperties(propertiesArray: propertiesArray)
            let permissions = CBAttributePermissions(permissionsArray: permissionsArray)
            
            let characteristic = CBMutableCharacteristic(type: uuid, properties: properties, value: nil, permissions: permissions)
            primaryServiceCharacteristics.append(characteristic)
        }
        primaryService.characteristics = primaryServiceCharacteristics
        
        // Create additional services as needed.
        var additionalServices = [CBMutableService]()
        for uuidStr in serviceUuidsStr {
            guard let uuid = UUID(uuidString: uuidStr) else {
                throw PeripheralServerError.invalidServiceUuid
            }
            let service = CBMutableService(type: CBUUID(nsuuid: uuid), primary: false)
            additionalServices.append(service)
        }
        
        // Add services to the peripheral manager.
        peripheralManager!.add(primaryService)
        additionalServices.forEach { peripheralManager!.add($0) }
    }
    
    
    /// Starts advertising this device as a BLE peripheral with the specified advertisement configuration.
    ///
    /// This method configures the BLE peripheral advertisement settings based on the provided configuration map.
    /// The configuration map should include the local name, service UUIDs, and manufacturer-specific data.
    /// The method then uses the existing `CBPeripheralManager` instance to start the advertisement.
    ///
    /// - Parameter configurationMap: A map containing the advertisement configuration details.
    ///   - `localName`: The local name of the BLE device (optional).
    ///   - `serviceUuids`: An array of service UUIDs as strings to be advertised (optional).
    ///   - `manufacturerData`: A dictionary where the key is a string representation of the manufacturer ID
    ///     (in hexadecimal) and the value is an array of bytes representing the manufacturer-specific data (optional).
    /// - Throws: An error if the configuration is invalid (e.g., missing required keys, invalid UUID format).
    func startAdvertising(with configurationMap: [String: Any]) throws {
        // Extract advertisement configuration from the arguments
        guard let localName = configurationMap["localName"] as? String?,
              let serviceUuidsStr = configurationMap["serviceUuids"] as? [String] else {
            throw PeripheralServerError.invalidConfiguration
        }
        
        // Prepare the advertisement data
        var advertisementData = [String: Any]()
        if let localName = localName {
            advertisementData[CBAdvertisementDataLocalNameKey] = localName
        }
        
        // Convert service UUID strings to CBUUIDs
        let serviceUUIDs = serviceUuidsStr.compactMap { UUID(uuidString: $0) }.map { CBUUID(nsuuid: $0) }
        if !serviceUUIDs.isEmpty {
            advertisementData[CBAdvertisementDataServiceUUIDsKey] = serviceUUIDs
        }
        
        // Start advertising
        peripheralManager?.startAdvertising(advertisementData)
    }
    
    /// Stops advertising this device as a BLE peripheral.
    ///
    /// This method stops any ongoing BLE advertisements that were previously started using the `CBPeripheralManager` instance.
    /// It ensures that the advertisement process is halted, which is useful for conserving power and managing BLE advertisement states.
    ///
    /// Usage example:
    /// ```swift
    /// stopAdvertising()
    /// ```
    func stopAdvertising() {
        // Check if the peripheral manager exists
        guard let peripheralManager = peripheralManager else {
            // Peripheral Manager is not initialized.
            return
        }
        
        // Stop advertising
        peripheralManager.stopAdvertising()
    }
    
    /// Handles the event when a central device subscribes to a characteristic of the peripheral.
    ///
    /// This method is called when a central device (client) subscribes to a characteristic of the peripheral device. Subscribing to a characteristic is an indication that the central device has established a connection and is interested in receiving notifications or indications from this characteristic.
    ///
    /// When this event occurs, the method gathers information about the connected central device, such as its identifier and name, and sends this information to the Flutter side via a method channel. This allows the Flutter application to be informed about new client connections and take appropriate actions.
    ///
    /// - Parameters:
    ///   - peripheral: The `CBPeripheralManager` instance that is managing the peripheral role.
    ///   - central: The `CBCentral` instance representing the central device that has subscribed to the characteristic.
    ///   - characteristic: The `CBCharacteristic` instance to which the central device has subscribed.
    public func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        let deviceInfo: [String: Any] = [
            "id": central.identifier.uuidString,
            "name": "Unknown" // TODO get the connected device name
        ]
        
        peripheralChannel?.invokeMethod("clientConnected", arguments: deviceInfo)
    }
    
    // MARK: Utility Methods
    
    // Utility method to get a CBPeripheral by its identifier
    private func getPeripheralByIdentifier(deviceAddress: String) -> CBPeripheral? {
        guard let peripheral = peripheralsMap[deviceAddress] else {
            centralChannel.invokeMethod("error", arguments: "Device not found.")
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

// Extensions to convert properties from arrays of strings to CBCharacteristicProperties
extension CBCharacteristicProperties {
    init(propertiesArray: [String]) {
        self.init()
        for property in propertiesArray {
            switch property {
            case "broadcast":
                self.insert(.broadcast)
            case "read":
                self.insert(.read)
            case "writeWithoutResponse":
                self.insert(.writeWithoutResponse)
            case "write":
                self.insert(.write)
            case "notify":
                self.insert(.notify)
            case "indicate":
                self.insert(.indicate)
            case "authenticatedSignedWrites":
                self.insert(.authenticatedSignedWrites)
            case "extendedProperties":
                self.insert(.extendedProperties)
            case "notifyEncryptionRequired":
                self.insert(.notifyEncryptionRequired)
            case "indicateEncryptionRequired":
                self.insert(.indicateEncryptionRequired)
            default:
                break
            }
        }
    }
}

// Extensions to convert permissions from arrays of strings to CBAttributePermissions
extension CBAttributePermissions {
    init(permissionsArray: [String]) {
        self.init()
        for permission in permissionsArray {
            switch permission {
            case "readable":
                self.insert(.readable)
            case "writeable":
                self.insert(.writeable)
            case "readEncryptionRequired":
                self.insert(.readEncryptionRequired)
            case "writeEncryptionRequired":
                self.insert(.writeEncryptionRequired)
            default:
                break
            }
        }
    }
}
