import 'dart:async';
import 'package:flutter/services.dart';

import '../../flutter_ble_platform_interface.dart';
import '../../models/ble_characteristic.dart';
import '../../models/ble_characteristic_value.dart';
import '../../models/ble_connection_state.dart';
import '../../models/ble_device.dart';
import '../../models/ble_service.dart';
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

  /// Initiates a connection to a BLE peripheral and returns a Stream representing the connection state.
  ///
  /// The [deviceAddress] parameter specifies the MAC address of the target device.
  ///
  /// This method calls the 'connect' method on the native Android implementation via a method channel, and returns a
  /// [Stream] that emits [ConnectionState] enum values representing the status of the connection. Because an app could
  /// attempt to establish a connection to multiple different peripherals at once, the platform side differentiates
  /// connection status updates for each peripheral by appending the peripherals' Bluetooth addresses to the
  /// method channel names. For example, the connection states for a particular module with address, *10:91:A8:32:8C:BA*
  /// would be communicated with the method channel name, "bleConnectionState_10:91:A8:32:8C:BA". In this way, a
  /// different [Stream] of [BleConnectionState] values is established for each Bluetooth peripheral.
  @override
  Stream<BleConnectionState> connect({required String deviceAddress}) {
    /// A [StreamController] emitting values from the [ConnectionState] enum, which represent the connection state
    /// between the host mobile device and a Bluetooth peripheral.
    final StreamController<BleConnectionState> connectionStateStreamController =
        StreamController<BleConnectionState>.broadcast();

    // Listen to the platform side for connection state updates. The platform side differentiates connection state
    // updates for different Bluetooth peripherals by appending the device address to the method name.
    _channel.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'bleConnectionState_$deviceAddress') {
        final String connectionStateString = call.arguments as String;
        final BleConnectionState state =
            BleConnectionState.values.firstWhere((value) => value.identifier == connectionStateString.toLowerCase());
        connectionStateStreamController.add(state);
      }
    });

    _channel.invokeMethod('connect', {'address': deviceAddress});
    return connectionStateStreamController.stream;
  }

  /// Triggers the service discovery process and returns a [Stream] of discovered services.
  ///
  /// Returns a [Stream] of [List<BleService>] where each individual element in this list, each individual [BleService]
  /// instance, is a service of the Bluetooth peripheral, that emits whenever services and characteristics
  /// are discovered on a connected Bluetooth peripheral.
  @override
  Stream<List<BleService>> discoverServices(String deviceAddress) {
    final StreamController<List<BleService>> servicesDiscoveredController =
        StreamController<List<BleService>>.broadcast();

    // Listen to the platform side for discovered services and their characteristics. The platform side differentiates
    // services discovered for different Bluetooth peripherals by appending the device address to the method name.
    _handleBleServicesDiscovered(deviceAddress, servicesDiscoveredController);

    _channel.invokeMethod('discoverServices', {'address': deviceAddress});
    return servicesDiscoveredController.stream;
  }

  /// Sets a handler for processing the discovered BLE services and characteristics for a specific peripheral device.
  ///
  /// Service and characteristic discovery is a fundamental step in BLE communication.
  /// Once a connection with a BLE peripheral is established, the central device (in this case, our Flutter app)
  /// must discover the services offered by the peripheral to understand how to communicate with it effectively.
  /// Each service can have multiple characteristics, which are like "channels" of communication.
  /// By understanding these services and characteristics, our Flutter app can read from or write to
  /// these channels to facilitate meaningful exchanges of data.
  ///
  /// The purpose of this method is to convert the raw service and characteristic data received from the method channel
  /// into a structured format (a list of [BleService] objects) for Dart, and then pass them through the provided stream controller.
  ///
  /// [deviceAddress] is the MAC address of the target BLE device.
  /// [servicesDiscoveredController] is the stream controller through which the discovered services will be emitted to listeners.
  void _handleBleServicesDiscovered(
    String deviceAddress,
    StreamController<List<BleService>> servicesDiscoveredController,
  ) {
    _channel.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'bleServicesDiscovered_$deviceAddress') {
        final Map rawServicesMap = call.arguments as Map;

        // Construct a list of BleService objects from the raw data.
        final List<BleService> services = rawServicesMap.entries
            .map((entry) {
              if (entry.key is String && entry.value is List) {
                List<Map> rawCharacteristics = List<Map>.from(entry.value);

                // Convert the raw characteristic maps to BleCharacteristic objects.
                List<BleCharacteristic> characteristics = rawCharacteristics.map((charMap) {
                  // Manually convert the map to the desired type
                  Map<String, dynamic> typedMap = Map.from(charMap).map((key, value) => MapEntry(key as String, value));
                  return BleCharacteristic.fromMap(typedMap);
                }).toList();

                return BleService(
                  serviceUuid: entry.key as String,
                  characteristics: characteristics,
                );
              } else {
                // Return a null BleService to be filtered out later.
                return null;
              }
            })
            .where((service) => service != null)
            .cast<BleService>()
            .toList();

        servicesDiscoveredController.add(services);
      }
    });
  }

  /// Terminates the connection between the host mobile device and a BLE peripheral.
  @override
  Future<void> disconnect(String deviceAddress) async {
    _channel.invokeMethod('disconnect', {'address': deviceAddress});
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

  /// Writes data to a specified characteristic.
  ///
  /// [address] - The address of the device to communicate with.
  /// [characteristicUuid] - The UUID of the characteristic to write to.
  /// [value] - The string value to be written.
  /// [writeType] - Optional write type, defaulting to `BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT`.
  @override
  Future<void> writeCharacteristic({
    required String address,
    required String characteristicUuid,
    required String value,
    int? writeType,
  }) async {
    try {
      await _channel.invokeMethod('writeCharacteristic', {
        'address': address,
        'characteristicUuid': characteristicUuid,
        'value': value,
        if (writeType != null) 'writeType': writeType,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Reads the value of a specified Bluetooth characteristic.
  ///
  /// This method asynchronously fetches the value of a specified
  /// Bluetooth characteristic from a connected device and returns it as a
  /// [BleCharacteristicValue] instance.
  ///
  /// The method will throw a [TimeoutException] if it does not receive a response
  /// within the specified [timeout]. This safeguards against situations where the
  /// asynchronous operation hangs indefinitely.
  ///
  /// Note: A [TimeoutException] does not necessarily indicate a failure in reading the
  /// characteristic, but rather that a response was not received in the given timeframe.
  /// Ensure that the timeout value is appropriate for the expected device response times
  /// and consider retrying the operation if necessary.
  ///
  /// - [address]: The MAC address of the Bluetooth device. This uniquely identifies
  ///   the device and is used to fetch the associated BluetoothGatt instance.
  ///
  /// - [characteristicUuid]: The UUID of the characteristic whose value is to be read.
  ///   This UUID should match one of the characteristics available on the connected
  ///   Bluetooth device.
  ///
  /// - [timeout]: The maximum amount of time this function will wait for a response from
  ///   the platform side. If this duration is exceeded without receiving a response,
  ///   a [TimeoutException] will be thrown. Ensure that this duration accounts for
  ///   potential delays in device communication.
  ///
  /// Returns a `Future<BleCharacteristicValue>` that completes with the characteristic value
  /// once it has been read.
  ///
  /// Example usage:
  /// ```dart
  /// try {
  ///   BleCharacteristicValue characteristicValue = await readCharacteristic(
  ///     address: '00:1A:7D:DA:71:13',
  ///     characteristicUuid: '00002a00-0000-1000-8000-00805f9b34fb',
  ///     timeout: Duration(seconds: 10),
  ///   );
  ///   print(characteristicValue.value);
  /// } catch (e) {
  ///   print('Failed to read characteristic: $e');
  /// }
  /// ```
  @override
  Future<BleCharacteristicValue> readCharacteristic({
    required String address,
    required String characteristicUuid,
    required Duration timeout,
  }) async {
    final completer = Completer<BleCharacteristicValue>();

    _channel.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'onCharacteristicRead') {
        final BleCharacteristicValue response = BleCharacteristicValue.fromMap(call.arguments);
        completer.complete(response);
        _channel.setMethodCallHandler(null); // Reset the handler to avoid future calls.
      }
    });

    // Read the value of the characteristic.
    _channel.invokeMethod('readCharacteristic', {
      'address': address,
      'characteristicUuid': characteristicUuid,
    });

    // Implement the timeout logic.
    return completer.future.timeout(
      timeout,
      onTimeout: () {
        // If the timeout occurs, reset the method call handler and throw an error.
        _channel.setMethodCallHandler(null);
        throw TimeoutException('Failed to read characteristic within the given timeout', timeout);
      },
    );
  }
}
