//
//  MethodChannelMethods.swift
//  flutter_splendid_ble
//

enum CentralMethod: String, CaseIterable {
    case requestBluetoothPermissions = "requestBluetoothPermissions"
    case emitCurrentPermissionStatus = "emitCurrentPermissionStatus"
    case checkBluetoothAdapterStatus = "checkBluetoothAdapterStatus"
    case emitCurrentBluetoothStatus = "emitCurrentBluetoothStatus"
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

enum PeripheralMethod: String, CaseIterable {
    case placeholder = "placeholder"
    // ... other peripheral methods
}
