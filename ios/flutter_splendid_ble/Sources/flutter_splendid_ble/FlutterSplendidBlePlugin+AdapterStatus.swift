import Flutter
import CoreBluetooth

/// Bluetooth adapter status helpers for `FlutterSplendidBlePlugin`.
///
/// The methods in this extension manage the Bluetooth adapter on an iOS device and communicate its status
/// to the Dart side of a Flutter app. They can check the current status of the Bluetooth adapter and listen
/// for changes to the adapter's status, allowing the Dart side of a Flutter application to respond in
/// real-time to changes in the Bluetooth adapter's status. The class uses the CoreBluetooth library to
/// interact with the Bluetooth adapter and EventChannel.EventSink to communicate with the Dart side.
extension FlutterSplendidBlePlugin {

    // MARK: Adapter Status Helper Methods

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
}
