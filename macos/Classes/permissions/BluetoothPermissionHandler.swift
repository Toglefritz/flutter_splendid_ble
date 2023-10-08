import CoreBluetooth
import FlutterMacOS

/// Manages Bluetooth permissions on an iOS or macOS device and communicates its status to the Dart side of a Flutter app.
///
/// This class is responsible for requesting and checking Bluetooth permissions on the iOS or macOS device.
/// It allows the Dart side of a Flutter application to respond in real-time to changes in Bluetooth permission status.
///
/// The class uses CoreBluetooth's CBCentralManager to interact with Bluetooth permissions and a FlutterMethodChannel to
/// communicate with the Dart side.
///
/// ## Adding Necessary Keys to Info.plist
/// In order to request Bluetooth permissions on iOS or macOS, you need to add the following keys to your `Info.plist` file:
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
///
/// @property channel: FlutterMethodChannel used to send the BluetoothPermissionStatus to the Dart side.
class BluetoothPermissionHandler: NSObject, CBCentralManagerDelegate {
    
    private var centralManager: CBCentralManager!
    private let channel: FlutterMethodChannel
    
    /// Initializes the BluetoothPermissionHandler class.
    ///
    /// The initializer sets the FlutterMethodChannel and instantiates the CBCentralManager.
    /// The CBCentralManager will trigger the Bluetooth permission dialog to the user if it hasn't been triggered before.
    ///
    /// - Parameter channel: The FlutterMethodChannel to communicate with the Dart side.
    init(channel: FlutterMethodChannel) {
        self.channel = channel
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: true])
    }
    
    /// Requests and checks the Bluetooth permission status.
    ///
    /// This method returns the Bluetooth permission status. It uses the authorization property of the CBCentralManager to determine
    /// the current authorization status.
    ///
    /// - Returns: BluetoothPermissionStatus indicating the current permission status. (.granted, .denied, or .unknown)
    func requestBluetoothPermissions() -> BluetoothPermissionStatus {
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
    func emitCurrentPermissionStatus() {
        let status = self.requestBluetoothPermissions().rawValue
        // Invoke method on Flutter side
        channel.invokeMethod("permissionStateUpdated", arguments: status)
    }
    
    /// CBCentralManagerDelegate method to handle updates in Bluetooth state.
    ///
    /// This delegate method is automatically called whenever there is a change in Bluetooth state, including permission changes.
    /// When called, it invokes `emitCurrentPermissionStatus()` to send the updated permission status to the Dart side.
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // Emit the permission status when the state is updated
        self.emitCurrentPermissionStatus()
    }
}
