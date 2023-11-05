import FlutterMacOS
import CoreBluetooth

/// `FlutterBlePlugin` serves as the central bridge between Flutter code in a Dart environment and the native Bluetooth capabilities on MacOS devices.
/// It adheres to the `FlutterPlugin` protocol to interface with Flutter, and `CBCentralManagerDelegate` to interact with the MacOS Bluetooth stack.
///
/// The design ensures that there is a single instance of `CBCentralManager` to maintain the state of the Bluetooth adapter across the entire application.
/// It's crucial to have only one `CBCentralManager` instance in order to manage and centralize the state and delegate callbacks for BLE operations consistently.
/// This is particularly important for operations like scanning, where the discovery of peripherals should be consistent with the instances used for actual communication.
/// Maintaining a single source of truth for peripheral instances avoids duplication and state inconsistencies.
public class FlutterBlePlugin: NSObject, FlutterPlugin, CBCentralManagerDelegate, CBPeripheralDelegate {
    /// A `FlutterMethodChannel` used for communication with the Dart side of the app.
    private var channel: FlutterMethodChannel!
    
    /// The central manager for managing BLE operations.
    ///
    /// `centralManager` is the core of Bluetooth functionality, acting as the central point for managing BLE operations. It must remain a single instance to manage
    /// the state and delegate callbacks for all BLE operations consistently.
    private var centralManager: CBCentralManager!
    
    /// A dictionary that maintains a connection with the peripherals that are currently connected.
    /// The keys are the string representations of the peripheral's unique identifiers, and the values are the `CBPeripheral` instances themselves.
    /// This allows for quick retrieval and management of peripherals that the application has established a connection with.
    private var connectedPeripherals = [String: CBPeripheral]()
    
    /// An optional `FlutterEventSink` which allows for sending scanning result data back to the Flutter side in real-time.
    private var scanResultSink: FlutterEventSink?
    
    // Holds the UUIDs of characteristics for which a read operation has been initiated.
    private var pendingReadRequests: [CBUUID: Bool] = [:]
    
    /// Initializes the `FlutterBlePlugin` and sets up the central manager.
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    /// Registers the plugin with the given registrar by creating a method channel and setting the current instance as its delegate.
    /// - Parameter registrar: The `FlutterPluginRegistrar` that handles plugin registration.
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_ble", binaryMessenger: registrar.messenger)
        let instance = FlutterBlePlugin()
        instance.channel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    /// Handles incoming method calls from Flutter and directs them to the appropriate functions based on the method name.
    /// - Parameters:
    ///   - call: The `FlutterMethodCall` object containing the method name and arguments from Flutter.
    ///   - result: The `FlutterResult` callback to return results or errors back to the Flutter side.
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "requestBluetoothPermissions":
            let permissionStatus: String = requestBluetoothPermissions().rawValue
            result(permissionStatus)
            
        case "emitCurrentPermissionStatus":
            emitCurrentPermissionStatus()
            result(nil)
            
        case "checkBluetoothAdapterStatus":
            // Check the status of the Bluetooth adapter
            let status = centralManager.state == .poweredOn ? "available" : "notAvailable"
            result(status)
            
        case "emitCurrentBluetoothStatus":
            emitCurrentBluetoothStatus()
            result(nil)
            
        case "startScan":
            // Start scanning for BLE devices
            centralManager.scanForPeripherals(withServices: nil, options: nil)
            result(nil)
            
        case "stopScan":
            // Stop scanning for BLE devices
            centralManager.stopScan()
            result(nil)
            
        case "connect":
            if let arguments = call.arguments as? [String: Any],
               let deviceAddress = arguments["address"] as? String {
                connect(deviceAddress: deviceAddress)
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Device address cannot be null.", details: nil))
            }
            
        case "disconnect":
            if let arguments = call.arguments as? [String: Any],
               let deviceAddress = arguments["address"] as? String {
                disconnect(deviceAddress: deviceAddress)
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Device address cannot be null.", details: nil))
            }
            
        case "getCurrentConnectionState":
            if let arguments = call.arguments as? [String: Any],
               let deviceAddress = arguments["address"] as? String {
                let connectionState = getCurrentConnectionState(deviceAddress: deviceAddress).lowercased()
                result(connectionState)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Device address cannot be null.", details: nil))
            }
            
        case "discoverServices":
            guard let args = call.arguments as? [String: Any],
                  let deviceAddress = args["address"] as? String,
                  let peripheral = peripheralsMap[deviceAddress] else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Device address cannot be null.", details: nil))
                return
            }
            peripheral.delegate = self
            peripheral.discoverServices(nil)
            result(nil)
            
        case "writeCharacteristic":
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
            
        case "readCharacteristic":
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
            
        case "subscribeToCharacteristic":
            subscribeToCharacteristic(call: call, result: result)
            
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
            // ... add other details as needed
        ]
        
        // Get manufacturer data and add it to the map
        if let manufacturerData = manufacturerData {
            deviceMap["manufacturerData"] = manufacturerData.hexString
        }
        
        // Send device information to Flutter side
        let jsonData = try? JSONSerialization.data(withJSONObject: deviceMap, options: [])
        if let jsonData = jsonData, let jsonString = String(data: jsonData, encoding: .utf8) {
            channel.invokeMethod("bleDeviceScanned", arguments: jsonString)
        }
    }
    
    /// Called by the system when a connection to the peripheral is successfully established.
    /// This method triggers a callback to the Flutter side to inform it of the connection status.
    /// It is important for managing state on the Flutter side, such as updating UI elements or handling connected devices.
    /// - Parameters:
    ///   - central: The `CBCentralManager` that has initiated the connection.
    ///   - peripheral: The `CBPeripheral` to which the app has just successfully connected.
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        channel.invokeMethod("bleConnectionState_\(peripheral.identifier.uuidString)", arguments: "CONNECTED")
    }
    
    /// Called by the system when the central manager fails to create a connection with the peripheral.
    /// This delegate method is crucial for error handling and informing the user of a failed connection attempt.
    /// The method also communicates this failure back to the Flutter side so it can respond accordingly.
    /// - Parameters:
    ///   - central: The `CBCentralManager` that attempted the connection.
    ///   - peripheral: The `CBPeripheral` that the manager failed to connect to.
    ///   - error: An optional `Error` providing more details about the reason for the failure.
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
        
        // TODO Handle the notification state update if needed
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
        channel.invokeMethod("permissionStateUpdated", arguments: status)
    }
    
    // MARK: Adapter Status Helper Methods
    ///  The methods in this section manage the Bluetooth adapter on a MacOS device and communicates its status to the Dart side of a Flutter app.
    ///
    ///  This section is responsible for managing the Bluetooth adapter's status on the MacOS device. It can check the current status of the Bluetooth adapter, and also listen for changes to the adapter's status. This allows the Dart side of a Flutter application to respond in real-time to changes in the Bluetooth adapter's status.
    ///  The class uses the CoreBluetooth library to interact with the Bluetooth adapter and EventChannel.EventSink to communicate with the Dart side.
    
    /// Method to check the Bluetooth adapter status
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
    
    /// Emit current Bluetooth adapter status to the Dart side
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
    
    /// A dictionary to store peripheral devices.
    ///
    /// The dictionary uses the peripheral's UUID string as the key and the `CBPeripheral` object as the value.
    /// This enables easy retrieval and management of peripheral connections.
    private var peripheralsMap: [String: CBPeripheral] = [:]
    
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
