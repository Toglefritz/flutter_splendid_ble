import FlutterMacOS

/// `FlutterBlePlugin` serves as the main class for the Flutter plugin, integrating the Bluetooth functionality and permissions.
///
/// This class works as the central unit of the Flutter Bluetooth plugin. It is responsible for registering the plugin,
/// coordinating the Bluetooth functionalities (adapter status checks and updates), and also handling Bluetooth permissions.
/// It utilizes two helper classes: `BluetoothAdapterHandler` and `BluetoothPermissionHandler`.
///
/// To register this plugin, the `register(with:)` function needs to be called usually within the AppDelegate file on the Flutter side.
///
/// For proper functioning, the `BluetoothPermissionHandler` requires "NSBluetoothAlwaysUsageDescription"
/// and "NSBluetoothPeripheralUsageDescription" keys to be added to the Info.plist file.
public class FlutterBlePlugin: NSObject, FlutterPlugin {
    
    /// An instance of the `BluetoothPermissionHandler` class for requesting and checking Bluetooth permissions.
    private var bluetoothPermissionHandler: BluetoothPermissionHandler?
    
    /// An instance of the `BluetoothAdapterHandler` class for checking and emitting the status of the Bluetooth adapter.
    private var bluetoothAdapterHandler: BluetoothAdapterHandler?
    
    /// An instance of the `BleScannerHandler` class for Bluetooth scanning.
    private var bleScannerHandler: BleScannerHandler?
    
    /// Registers the Flutter plugin with a given `FlutterPluginRegistrar`.
    ///
    /// - Parameter registrar: The `FlutterPluginRegistrar` with which to register the plugin.
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_ble", binaryMessenger: registrar.messenger)
        
        let instance = FlutterBlePlugin()
        instance.bluetoothAdapterHandler = BluetoothAdapterHandler(channel: channel)
        instance.bluetoothPermissionHandler = BluetoothPermissionHandler(channel: channel)
        instance.bleScannerHandler = BleScannerHandler(channel: channel)
        
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    /// Handles the incoming method calls from the Dart side.
    ///
    /// - Parameters:
    ///   - call: The `FlutterMethodCall` object representing the method called.
    ///   - result: A closure that expects a return value or FlutterResult to be passed in as an argument.
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
            // Handles request to obtain Bluetooth permissions.
        case "requestBluetoothPermissions":
            let permissionStatus = bluetoothPermissionHandler?.requestBluetoothPermissions().rawValue ?? "unknown"
            result(permissionStatus)
            
            // Handles request to emit the current Bluetooth permission status.
        case "emitCurrentPermissionStatus":
            bluetoothPermissionHandler?.emitCurrentPermissionStatus()
            result(nil)
            
            // Handles request to check the status of the Bluetooth adapter.
        case "checkBluetoothAdapterStatus":
            let status = bluetoothAdapterHandler?.checkBluetoothAdapterStatus().rawValue ?? "notAvailable"
            result(status)
            
            // Handles request to emit the current status of the Bluetooth adapter.
        case "emitCurrentBluetoothStatus":
            bluetoothAdapterHandler?.emitCurrentBluetoothStatus()
            result(nil)
            
            // Handles request to start Bluetooth scanning.
        case "startScan":
            bleScannerHandler?.startScan()
            result(nil)
            
            // Handles request to stop Bluetooth scanning.
        case "stopScan":
            bleScannerHandler?.stopScan()
            result(nil)
            
            // Case where the method called from Dart is not implemented here.
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
