import Flutter
import CoreBluetooth

/// Bluetooth permission helpers for `FlutterSplendidBlePlugin`.
///
/// The methods in this extension manage Bluetooth permissions on an iOS device and communicate statuses to
/// the Dart side of a Flutter app. They are responsible for requesting and checking Bluetooth permissions,
/// allowing the Dart side of a Flutter application to respond in real-time to changes in Bluetooth
/// permission statuses.
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
extension FlutterSplendidBlePlugin {

    // MARK: Bluetooth Permissions Helper Methods

    /// Requests and checks the Bluetooth permission status.
    ///
    /// This method returns the Bluetooth permission status. It uses the authorization property of the CBCentralManager to determine
    /// the current authorization status.
    ///
    /// - Returns: BluetoothPermissionStatus indicating the current permission status. (.granted, .denied, or .unknown)
    func requestBluetoothPermissions() -> BluetoothPermissionStatus {
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
    func emitCurrentPermissionStatus() {
        let status: String = requestBluetoothPermissions().rawValue
        // Invoke method on Flutter side
        channel.invokeMethod("permissionStatusUpdated", arguments: status)
    }
}
