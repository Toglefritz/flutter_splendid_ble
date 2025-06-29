import 'dart:async';
import 'dart:convert';

import '../central/models/ble_characteristic.dart';
import '../central/models/ble_characteristic_value.dart';
import '../central/models/ble_connection_state.dart';
import '../central/models/ble_service.dart';
import '../central/models/scan_filter.dart';
import '../central/models/scan_settings.dart';
import '../shared/models/ble_device.dart';
import '../shared/models/bluetooth_permission_status.dart';
import '../shared/models/bluetooth_status.dart';
import 'central_platform_interface.dart';
import 'extensions/scan_filter_list_extensions.dart';
import 'models/connected_ble_device.dart';

/// A fake implementation of [CentralPlatformInterface] designed for use in unit and widget tests.
///
/// This class simulates Bluetooth interactions without requiring actual hardware or platform channels. It allows
/// developers to run tests on Flutter apps that use Bluetooth features without depending on physical BLE devices or
/// native platform code.
///
/// ### Usage
///
/// To use in a test, override the singleton instance of [CentralPlatformInterface]:
///
/// ```dart
/// setUp(() {
///   CentralPlatformInterface.instance = FakeCentralMethodChannel();
/// });
/// ```
///
/// You can then add fake devices and services to simulate Bluetooth interactions:
///
/// ```dart
/// // Set the fake implementation before running tests
/// final FakeCentralMethodChannel fake = CentralPlatformInterface.instance as FakeCentralMethodChannel;
///
/// // Add a fake device to the scan results
/// fake.addFakeDevice(BleDevice(name: 'Test Device', address: '00:11:22:33:44:55', rssi: -60));
///
/// // Set fake services for the fake device
/// fake.setServices('00:11:22:33:44:55', [
///   BleService(
///     serviceUuid: '180D',
///     characteristics: [
///       BleCharacteristic(uuid: '2A37', address: '00:11:22:33:44:55'),
///     ],
///   ),
/// ]);
///
/// // Set a mock read value for a specific characteristic
/// fake.setMockReadValue('2A37', utf8.encode('42'));
/// ```
class FakeCentralMethodChannel extends CentralPlatformInterface {
  /// A stream controller used to emit the current Bluetooth adapter status to listeners.
  final StreamController<BluetoothStatus> _bluetoothStatusController = StreamController<BluetoothStatus>.broadcast();

  /// A stream controller used to emit the current Bluetooth permission status to listeners.
  final StreamController<BluetoothPermissionStatus> _permissionStatusController =
      StreamController<BluetoothPermissionStatus>.broadcast();

  /// A stream controller that emits fake BLE devices found during scanning.
  final StreamController<BleDevice> _scanResultsController = StreamController<BleDevice>.broadcast();

  /// A map of device addresses to their associated BLE connection state stream controllers.
  /// Used to simulate and emit connection state updates for individual devices.
  final Map<String, StreamController<BleConnectionState>> _connectionControllers = {};

  /// A map of device addresses to their associated BLE services stream controllers.
  /// Used to simulate the result of service discovery.
  final Map<String, StreamController<List<BleService>>> _serviceControllers = {};

  /// A map of characteristic UUIDs to their associated stream controllers for subscribed values.
  /// Used to simulate characteristic notifications and indications.
  final Map<String, StreamController<BleCharacteristicValue>> _characteristicStreams = {};

  /// A list of fake BLE devices that will be returned during scanning or queries for connected devices.
  final List<BleDevice> _fakeDevices = [];

  /// A map of device addresses to a list of their simulated BLE services.
  /// Used to simulate the service discovery response.
  final Map<String, List<BleService>> _servicesByDevice = {};

  /// A map of device addresses to their current simulated BLE connection states.
  final Map<String, BleConnectionState> _connectionStates = {};

  /// A map storing mock read values for specific characteristics.
  final Map<String, List<int>> _mockReadValues = {};

  /// Adds a mock BLE device to the scan result pool.
  void addFakeDevice(BleDevice device) {
    _fakeDevices.add(device);
  }

  /// Sets mock services for a given device address.
  void setServices(String deviceAddress, List<BleService> services) {
    _servicesByDevice[deviceAddress] = services;
  }

  /// Sets a mock read value for a specific characteristic UUID.
  void setMockReadValue(String characteristicUuid, List<int> value) {
    _mockReadValues[characteristicUuid] = value;
  }

  @override
  Future<BluetoothStatus> checkBluetoothAdapterStatus() async {
    return BluetoothStatus.enabled;
  }

  @override
  Stream<BluetoothStatus> emitCurrentBluetoothStatus() {
    return _bluetoothStatusController.stream;
  }

  @override
  Future<BluetoothPermissionStatus> requestBluetoothPermissions() async {
    return BluetoothPermissionStatus.granted;
  }

  @override
  Stream<BluetoothPermissionStatus> emitCurrentPermissionStatus() {
    return _permissionStatusController.stream;
  }

  @override
  Future<List<ConnectedBleDevice>> getConnectedDevices(List<String> serviceUUIDs) async {
    final List<ConnectedBleDevice> fakeConnectedDevices = _fakeDevices
        .map(
          (BleDevice device) => ConnectedBleDevice(
            name: device.name ?? '',
            address: device.address,
            advertisedServiceUuids: device.advertisedServiceUuids,
          ),
        )
        .toList();

    return fakeConnectedDevices;
  }

  @override
  Stream<BleDevice> startScan({List<ScanFilter>? filters, ScanSettings? settings}) {
    // Simulate a scan by adding fake devices after a short delay.
    Future.delayed(const Duration(milliseconds: 100), () {
      for (final BleDevice device in _fakeDevices) {
        // Check that the device matches the filters. The filtering logic is the same as the logic used in
        // `CentralMethodChannel`. However, note that the filtering applied by the native side is not used here so it is
        // not a perfect match.
        if(filters?.deviceMatchesFilters(device) ?? true) {
          _scanResultsController.add(device);
        }
        // If the device does not match the filters, it is ignored.
      }
    });

      return _scanResultsController.stream;
  }

  @override
  Future<void> stopScan() async {
    await _scanResultsController.close();
  }

  @override
  Stream<BleConnectionState> connect({required String deviceAddress}) {
    final controller = StreamController<BleConnectionState>.broadcast();
    _connectionControllers[deviceAddress] = controller;

    // Simulate a connection process with a delay.
    Future.delayed(const Duration(milliseconds: 50), () {
      controller
        ..add(BleConnectionState.connecting)
        ..add(BleConnectionState.connected);
      _connectionStates[deviceAddress] = BleConnectionState.connected;
    });

    return controller.stream;
  }

  @override
  Future<void> disconnect(String deviceAddress) async {
    _connectionControllers[deviceAddress]?.add(BleConnectionState.disconnected);
    _connectionStates[deviceAddress] = BleConnectionState.disconnected;
  }

  @override
  Future<BleConnectionState> getCurrentConnectionState(String deviceAddress) async {
    return _connectionStates[deviceAddress] ?? BleConnectionState.disconnected;
  }

  @override
  Stream<List<BleService>> discoverServices(String deviceAddress) {
    final controller = StreamController<List<BleService>>.broadcast();
    _serviceControllers[deviceAddress] = controller;

    Future.delayed(const Duration(milliseconds: 30), () {
      controller.add(_servicesByDevice[deviceAddress] ?? []);
    });

    return controller.stream;
  }

  @override
  Future<void> writeCharacteristic({
    required BleCharacteristic characteristic,
    required String value,
    int? writeType,
  }) async {
    // No-op for mock. Could add logging or tracking.
  }

  @override
  Future<BleCharacteristicValue> readCharacteristic({
    required BleCharacteristic characteristic,
    required Duration timeout,
  }) async {
    final List<int> value = _mockReadValues[characteristic.uuid] ?? utf8.encode('mock_value');

    return BleCharacteristicValue(
      deviceAddress: characteristic.address,
      characteristicUuid: characteristic.uuid,
      value: value,
    );
  }

  @override
  Stream<BleCharacteristicValue> subscribeToCharacteristic(BleCharacteristic characteristic) {
    final controller = StreamController<BleCharacteristicValue>.broadcast();
    _characteristicStreams[characteristic.uuid] = controller;

    return controller.stream;
  }

  @override
  void unsubscribeFromCharacteristic(BleCharacteristic characteristic) {
    _characteristicStreams[characteristic.uuid]?.close();
    _characteristicStreams.remove(characteristic.uuid);
  }
}
