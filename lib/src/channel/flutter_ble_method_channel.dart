import 'dart:async';
import 'package:flutter/services.dart';

import '../../flutter_ble_platform_interface.dart';
import '../../models/ble_connection_state.dart';
import '../../models/ble_device.dart';
import '../../models/bluetooth_status.dart';
import '../../models/scan_filter.dart';
import '../../models/scan_settings.dart';

/// An implementation of [FlutterBlePlatform] that uses method channels.
class MethodChannelFlutterBle extends FlutterBlePlatform {
  /// The method channel used to interact with the native platform.
  final MethodChannel _channel = const MethodChannel('flutter_ble');

  /// Checks the status of the Bluetooth adapter on the device.
  ///
  /// This method communicates with the native Android code to obtain the current status of the
  /// Bluetooth adapter, and returns one of the values from the [BluetoothStatus] enumeration.
  ///
  /// * [BluetoothStatus.ENABLED]: Bluetooth is enabled and ready for connections.
  /// * [BluetoothStatus.DISABLED]: Bluetooth is disabled and not available for use.
  /// * [BluetoothStatus.NOT_AVAILABLE]: Bluetooth is not available on the device.
  ///
  /// Returns a Future containing the [BluetoothStatus] representing the current status of the
  /// Bluetooth adapter on the device.
  @override
  Future<BluetoothStatus> checkBluetoothAdapterStatus() async {
    final String statusString = await _channel.invokeMethod('checkBluetoothAdapterStatus');
    return BluetoothStatus.values.firstWhere((e) => e.identifier == statusString);
  }

  /// Emits the current Bluetooth adapter status to the Dart side.
  ///
  /// This method communicates with the native Android code to obtain the current status of the Bluetooth adapter
  /// and emits it to any listeners on the Dart side.
  ///
  /// Listeners on the Dart side will receive one of the following enum values from [BluetoothStatus]:
  ///
  /// * [BluetoothStatus.enabled]: Indicates that Bluetooth is enabled and ready for connections.
  /// * [BluetoothStatus.disabled]: Indicates that Bluetooth is disabled and not available for use.
  /// * [BluetoothStatus.notAvailable]: Indicates that Bluetooth is not available on the device.
  ///
  /// Returns a [Future] containing a [Stream] of [BluetoothStatus] values representing the current status
  /// of the Bluetooth adapter on the device.
  @override
  Stream<BluetoothStatus> emitCurrentBluetoothStatus() {
    final StreamController<BluetoothStatus> streamController = StreamController<BluetoothStatus>.broadcast();

    // Listen to the platform side for Bluetooth adapter status updates.
    _channel.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'adapterStateUpdated') {
        final String statusString = call.arguments as String;

        // Convert the string status to its corresponding enum value
        final BluetoothStatus status = BluetoothStatus.values.firstWhere(
          (e) => e.identifier == statusString,
          orElse: () => BluetoothStatus.notAvailable,
        ); // Default to notAvailable if the string does not match any enum value

        streamController.add(status);
      }
    });

    // Begin emitting Bluetooth adapter status updates from the platform side.
    _channel.invokeMethod('emitCurrentBluetoothStatus');

    return streamController.stream;
  }

  /// Starts a scan for nearby BLE devices.
  ///
  /// Returns a stream of [BleDevice] objects representing each discovered device.
  @override
  Stream<BleDevice> startScan({List<ScanFilter>? filters, ScanSettings? settings}) {
    StreamController<BleDevice> streamController = StreamController<BleDevice>.broadcast();

    // Listen to the platform side for scanned devices.
    _channel.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'bleDeviceScanned') {
        BleDevice device = BleDevice.fromMap(call.arguments);
        streamController.add(device);
      }
    });

    // Convert filters and settings into map representations if provided.
    final List<Map<String, dynamic>>? filtersMap = filters?.map((filter) => filter.toMap()).toList();
    final Map<String, dynamic>? settingsMap = settings?.toMap();

    // Begin the scan on the platform side, including the filters and settings in the method call if provided.
    _channel.invokeMethod('startScan', {
      'filters': filtersMap,
      'settings': settingsMap,
    });

    return streamController.stream;
  }

  /// Stops an ongoing Bluetooth scan.
  @override
  void stopScan() {
    _channel.invokeMethod('stopScan');
  }

  /// Initiates a connection to a BLE peripheral and returns a Stream representing
  /// the connection state.
  ///
  /// The [deviceAddress] parameter specifies the MAC address of the target device.
  ///
  /// This method calls the 'connect' method on the native Android implementation
  /// via a method channel, and returns a [Stream] that emits [ConnectionState]
  /// enum values representing the status of the connection.
  @override
  Stream<BleConnectionState> connect(String deviceAddress) {
    /// A [StreamController] emitting values from the [ConnectionState] enum, which represent the connection state
    /// between the host mobile device and a Bluetooth peripheral.
    final StreamController<BleConnectionState> connectionStateStreamController =
        StreamController<BleConnectionState>.broadcast();

    // Listen to the platform side for connection state updates.
    _channel.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'bleConnectionState') {
        final String connectionStateString = call.arguments as String;
        final BleConnectionState state =
            BleConnectionState.values.firstWhere((value) => value.identifier == connectionStateString.toLowerCase());
        connectionStateStreamController.add(state);
      }
    });

    _channel.invokeMethod('connect', {'address': deviceAddress});
    return connectionStateStreamController.stream;
  }

  /// Terminates the connection between the host mobile device and a BLE peripheral.
  @override
  Future<void> disconnect(String deviceAddress) async {
    _channel.invokeMethod('disconnect');
  }

  /// Fetches the current connection state of a Bluetooth Low Energy (BLE) device.
  ///
  /// The [deviceAddress] parameter specifies the MAC address of the target device.
  ///
  /// This method calls the 'getCurrentConnectionState' method on the native Android implementation
  /// via a method channel. It then returns a [Future] that resolves to the [ConnectionState] enum,
  /// which represents the current connection state of the device.
  ///
  /// Returns a [Future] containing the [ConnectionState] representing the current connection state
  /// of the BLE device with the specified address.
  @override
  Future<BleConnectionState> getCurrentConnectionState(String deviceAddress) async {
    // Invoke the method channel to fetch the current connection state for the BLE device.
    final String connectionStateString = await _channel.invokeMethod('getCurrentConnectionState', {
      'address': deviceAddress,
    });

    // Convert the string received from Kotlin to the Dart enum value.
    return BleConnectionState.values.firstWhere((e) => e.identifier == connectionStateString);
  }
}
