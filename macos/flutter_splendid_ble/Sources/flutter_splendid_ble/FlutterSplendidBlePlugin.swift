import Cocoa
import FlutterMacOS
import CoreBluetooth

/// `FlutterSplendidBlePlugin` serves as the central bridge between Flutter code in a Dart environment and the native Bluetooth capabilities on MacOS devices.
/// It adheres to the `FlutterPlugin` protocol to interface with Flutter, and `CBCentralManagerDelegate` to interact with the macOS Bluetooth stack.
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
/// * `FlutterSplendidBlePlugin+CentralManagerDelegate.swift` — `CBCentralManagerDelegate` and
///   `CBPeripheralManagerDelegate` callbacks along with the scan/discovery buffering helpers.
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
public class FlutterSplendidBlePlugin: NSObject, FlutterPlugin, CBCentralManagerDelegate, CBPeripheralDelegate, CBPeripheralManagerDelegate {
    
    /// A `FlutterMethodChannel` used for communication with the Dart side of the app for functionality in which the app acts as a BLE central device.
    var centralChannel: FlutterMethodChannel!
    
    /// The central manager for managing BLE operations involving the app acting as a BLE central device.
    ///
    /// `centralManager` is the core of BLE central functionality, acting as the central point for managing BLE operations. It must remain a single instance to manage
    /// the state and delegate callbacks for all BLE operations consistently.
    var centralManager: CBCentralManager!
    
    /// A fake version of the CBCentralManager that is used during testing.
    //private var fakeCentralManager: CBMCentralManagerFactory.instance
    
    /// A dictionary to store peripheral devices.
    ///
    /// The dictionary uses the peripheral's UUID string as the key and the `CBPeripheral` object as the value.
    /// This enables easy retrieval and management of peripheral connections.
    var peripheralsMap: [String: CBPeripheral] = [:]
    
    /// A set of device names used to filter the results of a scan. Only devices with names appearing in this list will be returned by the scan.
    var scanNameFilters: Set<String> = []

    /// Peripheral identifiers for which the Dart side has requested bonding observation.
    ///
    /// macOS exposes no bonding API, so bonding visibility is best-effort: the plugin only emits
    /// `bleBondState_<address>` updates for devices present in this set, derived from the lifecycle of operations on
    /// encrypted characteristics. A device is added when Dart calls `observeBondState` for it. See
    /// `FlutterSplendidBlePlugin+BondEvent.swift` for the platform-limitation details.
    var observedBondDevices: Set<String> = []
    
    /// An optional `FlutterEventSink` which allows for sending scanning result data back to the Flutter side in real-time.
    var scanResultSink: FlutterEventSink?
    
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
    /// asynchronous — CoreBluetooth queues the write and fires `didWriteValueFor` once the
    /// peripheral acknowledges it. The FlutterResult is stored here and completed in that
    /// callback so that `await characteristic.writeValue(...)` on the Dart side does not
    /// resolve until the ATT write response has been received.
    ///
    /// This is critical for encrypted characteristics: CoreBluetooth may initiate pairing
    /// before the peripheral can respond, and `didWriteValueFor` does not fire until after
    /// the bond is fully established and the write is retried successfully. Storing the
    /// result here ensures the Dart future correctly waits for that entire sequence.
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

    /// A set of device UUIDs that have been discovered during the current scan session.
    /// This tracks which devices we've seen before to differentiate between initial advertisement and scan response packets.
    var discoveredDevices: Set<UUID> = []

    /// Stores partial advertisement data for devices that support scan responses.
    /// The key is the peripheral UUID, and the value contains the initial advertisement data and RSSI.
    /// This data is merged with scan response data before being emitted to Flutter.
    var partialAdvertisementData: [UUID: (data: [String: Any], rssi: NSNumber)] = [:]

    /// How long to wait for a scan response before emitting the buffered initial advertisement.
    ///
    /// CoreBluetooth typically delivers the scan response within a few milliseconds of the
    /// first advertisement. 0.3 seconds is a conservative upper bound that prevents devices
    /// from being suppressed indefinitely when the OS only fires `didDiscover` once.
    static let scanResponseTimeoutSeconds: Double = 0.3

    /// Initializes the `FlutterBlePlugin` and sets up the central manager.
    override init() {
        super.init()
        // Initialize the central manager.
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    /// Registers the plugin with the given registrar by creating a method channel and setting the current instance as its delegate.
    /// - Parameter registrar: The `FlutterPluginRegistrar` that handles plugin registration.
    public static func register(with registrar: FlutterPluginRegistrar) {
        let centralChannel = FlutterMethodChannel(name: "flutter_splendid_ble_central", binaryMessenger: registrar.messenger)
        let instance = FlutterSplendidBlePlugin()
        instance.centralChannel = centralChannel
        registrar.addMethodCallDelegate(instance, channel: centralChannel)
    }
    
    /// This function is the entry point for handling Method Channel calls in the Flutter plugin. It routes incoming calls to the appropriate
    /// handler based on whether the call pertains to central or peripheral functionality. It uses the `isCentralMethod` and
    /// `isPeripheralMethod` functions to determine the correct routing.
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if isSharedMethod(call.method) {
            handleSharedMethod(call, result)
        } else if isCentralMethod(call.method) {
            handleCentralMethod(call, result)
        }
        else {
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
            // Check the status of the Bluetooth adapter. The `centralManager` is used for this purpose since
            // the adapter status should be the same for either the `centralManager` or `peripheralManager`.
            let status = centralManager.state == .poweredOn ? "enabled" : "notAvailable"
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
            var options: [String: Any]? = nil
            
            if let args = call.arguments as? [String: Any] {
                // Handle Scan Filters
                var expectedDeviceNames: Set<String> = []
                if let filtersMap = args["filters"] as? [[String: Any]] {
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
                    
                    // Note: macOS does not directly support scanMode and reportDelayMillis like Android does.
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
            // Note: We pass nil for serviceUUIDs to let Dart-side filtering handle all filtering
            centralManager.scanForPeripherals(withServices: nil, options: options)
            result(nil)
            
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
            
            // If this device is being observed for bonding and the write expects a response, the OS may transparently
            // initiate pairing to satisfy an encrypted characteristic before the write is acknowledged. Report that a
            // bond attempt may be in progress. This is a best-effort signal: macOS gives no explicit "pairing started"
            // callback, so the start of an acknowledged write is the closest observable proxy.
            if writeType == .withResponse && observedBondDevices.contains(deviceAddress) {
                emitBondState(deviceAddress: deviceAddress, state: "bonding", error: nil)
            }

            peripheral.writeValue(dataValue, for: characteristic, type: writeType)

            if writeType == .withResponse {
                // Store the result callback and complete it in didWriteValueFor once the
                // peripheral sends an ATT write response. For encrypted characteristics,
                // CoreBluetooth will initiate pairing first and retry the write after the
                // bond is established, so this callback fires only after pairing is complete.
                let key = "\(deviceAddress):\(characteristicUuidStr.uppercased())"
                pendingWriteResults[key] = result
            } else {
                // Write without response: no acknowledgement will arrive, so resolve now.
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
            // CoreBluetooth negotiates the connection PHY automatically on macOS.
            // The central role has no direct API to request a specific PHY after
            // connection, so this call is accepted and succeeds silently.
            result(nil)

        case CentralMethod.requestConnectionPriority.rawValue:
            // macOS does not expose a connection interval negotiation API to the
            // central role. Accepting the call silently ensures callers can use
            // a single code path across platforms.
            result(nil)

        case CentralMethod.observeBondState.rawValue:
            // macOS exposes no bonding API, so observation is best-effort: record the device so that the
            // encrypted-write path can emit `bonding`/`bonded`/`failed` proxies for it. See
            // FlutterSplendidBlePlugin+BondEvent.swift for the platform limitation. An `unknown` state is emitted
            // immediately because the actual bond state cannot be read on macOS.
            guard let arguments = call.arguments as? [String: Any],
                  let deviceAddress = arguments["address"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Device address cannot be null.", details: nil))
                return
            }

            observedBondDevices.insert(deviceAddress)
            emitBondState(deviceAddress: deviceAddress, state: "unknown", error: nil)
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
