/// An enumeration of method channel names for functions shared between BLE central and BLE peripheral functionality.
enum SharedMethod: String, CaseIterable {
    case requestBluetoothPermissions = "requestBluetoothPermissions"
    case emitCurrentPermissionStatus = "emitCurrentPermissionStatus"
    case checkBluetoothAdapterStatus = "checkBluetoothAdapterStatus"
    case emitCurrentBluetoothStatus = "emitCurrentBluetoothStatus"
}

/// An enumeration of of method channel names for functions called from apps acting as BLE central devices.
enum CentralMethod: String, CaseIterable {
    case startScan = "startScan"
    case stopScan = "stopScan"
    case connect = "connect"
    case disconnect = "disconnect"
    case getCurrentConnectionState = "getCurrentConnectionState"
    case discoverServices = "discoverServices"
    case writeCharacteristic = "writeCharacteristic"
    case readCharacteristic = "readCharacteristic"
    case subscribeToCharacteristic = "subscribeToCharacteristic"
    case unsubscribeFromCharacteristic = "unsubscribeFromCharacteristic"
}

/// An enumeration of of method channel names for functions called from apps acting as BLE peripheral devices.
enum PeripheralMethod: String, CaseIterable {
    case createPeripheralServer = "createPeripheralServer"
    // TODO add other peripheral methods
}
