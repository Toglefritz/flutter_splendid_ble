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
///
/// ## File Organization
///
/// The implementation of this class is split across several files for readability. Each file contains an
/// extension of `FlutterSplendidBlePlugin` grouping a cohesive set of responsibilities:
///
/// * `FlutterSplendidBlePlugin.swift` — The class declaration, stored properties, initialization, plugin
///   registration, and Method Channel call routing (this file).
/// * `FlutterSplendidBlePlugin+CentralManagerDelegate.swift` — `CBCentralManagerDelegate` callbacks along
///   with the scan/discovery buffering helpers.
/// * `FlutterSplendidBlePlugin+PeripheralDelegate.swift` — `CBPeripheralDelegate` callbacks.
/// * `FlutterSplendidBlePlugin+Permissions.swift` — Bluetooth permission helper methods.
/// * `FlutterSplendidBlePlugin+AdapterStatus.swift` — Bluetooth adapter status helper methods.
/// * `FlutterSplendidBlePlugin+DeviceInterface.swift` — Connection management and characteristic
///   subscription helpers.
/// * `FlutterSplendidBlePlugin+Utilities.swift` — Peripheral/characteristic lookup utilities, read-request
///   bookkeeping, and the `Data` hex-string helper.
///
/// Because all of these files compile into the same module target, properties and helpers that are shared
/// across the extensions use the default internal access level rather than `private` (which is file-scoped
/// in Swift). None of these members are part of the plugin's public API.
public class FlutterSplendidBlePlugin: NSObject, FlutterPlugin, CBCentralManagerDelegate, CBPeripheralDelegate {
    /// A `FlutterMethodChannel` used for communication with the Dart side of the app.
    var channel: FlutterMethodChannel!
    
    /// The central manager for managing BLE operations.
    ///
    /// `centralManager` is the core of Bluetooth functionality, acting as the central point for managing BLE operations. It must remain a single instance to manage
    /// the state and delegate callbacks for all BLE operations consistently.
    var centralManager: CBCentralManager!
    
    /// A dictionary to store peripheral devices.
    ///
    /// The dictionary uses the peripheral's UUID string as the key and the `CBPeripheral` object as the value.
    /// This enables easy retrieval and management of peripheral connections.
    var peripheralsMap: [String: CBPeripheral] = [:]
    
    /// A set of device names used to filter the results of a scan. Only devices with names appearing in this list will be returned by the scan.
    var scanNameFilters: Set<String> = []
    
    // Holds the UUIDs of characteristics for which a read operation has been initiated.
    var pendingReadRequests: [CBUUID: Bool] = [:]
    
    /// Tracks pending notification state change operations with their FlutterResult callbacks.
    ///
    /// When subscribeToCharacteristic() or unsubscribeFromCharacteristic() is called,
    /// the operation is asynchronous. The FlutterResult is stored here and completed
    /// later in the didUpdateNotificationStateFor callback. This ensures proper async/await
    /// behavior in Dart - the Flutter method doesn't return until the notification state
    /// change actually completes.
    ///
    /// Key format: "deviceAddress:characteristicUUID"
    /// Value: The FlutterResult callback to complete when the operation finishes
    var pendingNotificationStateChanges: [String: FlutterResult] = [:]

    /// Tracks pending characteristic write operations with their FlutterResult callbacks.
    ///
    /// When writeCharacteristic() is called with write type `.withResponse`, the operation is
    /// asynchronous — Core Bluetooth queues the write and fires `didWriteValueFor` once the
    /// peripheral acknowledges it. The FlutterResult is stored here and completed in that
    /// callback so that `await characteristic.writeValue(...)` on the Dart side does not
    /// resolve until the ATT write response has been received.
    ///
    /// Key format: "deviceAddress:characteristicUUID"
    /// Value: The FlutterResult callback to complete when the write is acknowledged
    var pendingWriteResults: [String: FlutterResult] = [:]

    /// Pending fallback work items keyed by peripheral UUID.
    ///
    /// When a connectable device's first advertisement is buffered, a `DispatchWorkItem` is
    /// scheduled to emit the buffered data after `scanResponseTimeoutSeconds` if no scan
    /// response arrives first. Storing the items here allows them to be cancelled precisely
    /// when the scan response does arrive, or swept when the scan session ends.
    var pendingFallbackWorkItems: [UUID: DispatchWorkItem] = [:]

    // A list of UUIDs discovered by the scanning process. This is used to determine if a peripheral about which data is sent in the didDiscover method
    // below, was discovered previously. This information is, in turn, used to infer if a device has sent additional information to the device in a
    // scan response.
    var discoveredDevices: Set<UUID> = []
    
    /// A dictionary to store partial advertisement data for peripherals that support scan responses.
    ///
    /// This dictionary maps peripheral UUIDs to tuples containing their initial advertisement data and RSSI values.
    /// It is used to temporarily store advertisement data from connectable devices while waiting for potential
    /// scan response packets that may contain additional information like manufacturer data.
    ///
    /// The dictionary is automatically cleaned up when scan responses are received or when scanning stops.
    var partialAdvertisementData: [UUID: (data: [String: Any], rssi: NSNumber)] = [:]

    /// How long to wait for a scan response before emitting the buffered initial advertisement.
    ///
    /// CoreBluetooth typically delivers the scan response within a few milliseconds of the
    /// first advertisement. 0.3 seconds is a conservative upper bound that prevents devices
    /// from being suppressed indefinitely when the OS only fires `didDiscover` once.
    static let scanResponseTimeoutSeconds: Double = 0.3

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
            
            // Cancel any pending fallback emissions and flush devices that were buffered
            // during a previous scan session but never received a scan response.
            cancelAllPendingFallbacks()
            flushPartialAdvertisementData()

            // Clear previous scan session data
            discoveredDevices.removeAll()
            partialAdvertisementData.removeAll()

            // Start scanning with optional service UUIDs and options.
            centralManager.scanForPeripherals(withServices: serviceUUIDs, options: options)
            result(nil)
            
        case CentralMethod.stopScan.rawValue:
            // Stop scanning for BLE devices
            centralManager.stopScan()
            // Cancel pending fallback timers and flush any connectable devices that were
            // buffered but never received a scan response. Without this, those devices
            // would be dropped silently when the scan ends.
            cancelAllPendingFallbacks()
            flushPartialAdvertisementData()
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

            if writeType == .withResponse {
                // Store the result callback and complete it in didWriteValueFor once the
                // peripheral sends an ATT write response. This ensures that the Dart-side
                // await on writeValue() resolves only after the write is acknowledged,
                // giving callers accurate per-write timing information.
                let key = "\(deviceAddress):\(characteristicUuidStr)"
                pendingWriteResults[key] = result
            } else {
                // Write without response: the peripheral will not send an acknowledgement,
                // so resolve immediately.
                result(nil)
            }

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

        case CentralMethod.requestPreferredPhy.rawValue:
            // CoreBluetooth negotiates the connection PHY automatically on iOS.
            // The central role has no direct API to request a specific PHY after
            // connection, so this call is accepted and succeeds silently. Callers
            // do not need platform-specific branching.
            result(nil)

        case CentralMethod.requestConnectionPriority.rawValue:
            // iOS does not expose a connection interval negotiation API to the
            // central role. Accepting the call silently ensures callers can use
            // a single code path across platforms.
            result(nil)

        case CentralMethod.readConnectionParameters.rawValue:
            // Core Bluetooth does not expose the active link parameters (PHY,
            // connection interval, supervision timeout) to the central role.
            // Returning nil tells the Dart layer to display "not available" for all fields.
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
