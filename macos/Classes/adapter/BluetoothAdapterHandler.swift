import CoreBluetooth
import FlutterMacOS

//
//  BluetoothAdapterHandler.swift
//  flutter_ble
//
//  Manages the Bluetooth adapter on an Android device and communicates its status to the Dart side of a Flutter app.
//  This class is responsible for managing the Bluetooth adapter's status on the iOS device. It can check the current status of the Bluetooth adapter, and also listen for changes to the adapter's status. This allows the Dart side of a Flutter application to respond in real-time to changes in the Bluetooth adapter's status.
//  The class uses the CoreBluetooth library to interact with the Bluetooth adapter and EventChannel.EventSink to communicate with the Dart side.
class BluetoothAdapterHandler: NSObject, CBCentralManagerDelegate {
    
    private var centralManager: CBCentralManager!
    private let channel: FlutterMethodChannel
    
    // Initialization
    init(channel: FlutterMethodChannel) {
        self.channel = channel
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // Method to check the Bluetooth adapter status
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
    
    // Emit current Bluetooth adapter status to the Dart side
    func emitCurrentBluetoothStatus() {
        let status = self.checkBluetoothAdapterStatus().rawValue
        // Invoke method on Flutter side
        channel.invokeMethod("adapterStateUpdated", arguments: status)
    }
    
    // CBCentralManagerDelegate Method
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // Emit the Bluetooth status when the state is updated
        self.emitCurrentBluetoothStatus()
    }
}
