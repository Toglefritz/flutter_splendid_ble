import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'central_platform_interface.dart';
import '../central/models/ble_characteristic.dart';
import '../central/models/ble_characteristic_value.dart';
import '../central/models/ble_connection_state.dart';
import '../central/models/ble_device.dart';
import '../central/models/ble_service.dart';
import '../central/models/bluetooth_permission_status.dart';
import '../central/models/bluetooth_status.dart';
import '../central/models/exceptions/bluetooth_connection_exception.dart';
import '../central/models/exceptions/bluetooth_permission_exception.dart';
import '../central/models/exceptions/bluetooth_read_exception.dart';
import '../central/models/exceptions/bluetooth_scan_exception.dart';
import '../central/models/exceptions/bluetooth_subscription_exception.dart';
import '../central/models/exceptions/bluetooth_write_exception.dart';
import '../central/models/exceptions/service_discovery_exception.dart';
import '../central/models/scan_filter.dart';
import '../central/models/scan_settings.dart';

/// An implementation of [CentralPlatformInterface] that uses method channels.
// Several methods in this class use SteamControllers. Callers to these functions should ensure that they are
// closing these StreamControllers when they are no longer needed to avoid memory leaks
// ignore_for_file: close_sinks
class CentralMethodChannel extends CentralPlatformInterface {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final MethodChannel channel = const MethodChannel('flutter_splendid_ble_central');

  /// Checks the status of the Bluetooth adapter on the device.
  ///
  /// This method communicates with the native Android code to obtain the current status of the Bluetooth adapter,
  /// and returns one of the values from the [BluetoothStatus] enumeration.
  ///
  /// * [BluetoothStatus.ENABLED]: Bluetooth is enabled and ready for connections.
  /// * [BluetoothStatus.DISABLED]: Bluetooth is disabled and not available for use.
  /// * [BluetoothStatus.NOT_AVAILABLE]: Bluetooth is not available on the device.
  ///
  /// Returns a Future containing the [BluetoothStatus] representing the current status of the Bluetooth adapter on
  /// the device.
  ///
  /// It can be useful to check on the status of the Bluetooth adapter prior to attempting Bluetooth operations as
  /// a way of improving the user experience. Checking on the state of the Bluetooth adapter allows the user to be
  /// notified and prompted for action if they attempt to use an applications for which Bluetooth plays a critical
  /// role while the Bluetooth capabilities of the host device are disabled.
  @override
  Future<BluetoothStatus> checkBluetoothAdapterStatus() async {
    final String statusString = await channel.invokeMethod('checkBluetoothAdapterStatus');
    return BluetoothStatus.values.firstWhere((e) => e.identifier == statusString);
  }

  /// Emits the current Bluetooth adapter status to the Dart side.
  ///
  /// This method communicates with the native Android code to obtain the current status of the Bluetooth adapter
  /// and emits it to any listeners on the Dart side.
  ///
  /// Listeners on the Dart side will receive one of the following enum values from [BluetoothStatus]:
  ///
  /// * `BluetoothStatus.enabled`: Indicates that Bluetooth is enabled and ready for connections.
  /// * `BluetoothStatus.disabled`: Indicates that Bluetooth is disabled and not available for use.
  /// * `BluetoothStatus.notAvailable`: Indicates that Bluetooth is not available on the device.
  ///
  /// Returns a [Future] containing a [Stream] of [BluetoothStatus] values representing the current status
  /// of the Bluetooth adapter on the device.
  @override
  Stream<BluetoothStatus> emitCurrentBluetoothStatus() {
    final StreamController<BluetoothStatus> streamController = StreamController<BluetoothStatus>.broadcast();

    // Listen to the platform side for Bluetooth adapter status updates.
    channel.setMethodCallHandler((MethodCall call) async {
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
    channel.invokeMethod('emitCurrentBluetoothStatus');

    return streamController.stream;
  }

  /// Starts a scan for nearby Bluetooth Low Energy (BLE) devices and returns a stream of discovered devices.
  ///
  /// Scanning for BLE devices is a crucial step in establishing a BLE connection. It allows the mobile app to
  /// discover nearby BLE devices and gather essential information like device name, MAC address, and more. This
  /// method starts the scanning operation on the platform side and listens for discovered devices.
  ///
  /// The function takes optional `filters` and `settings` parameters that allow for more targeted device scanning.
  /// For example, you could specify a filter to only discover devices that are advertising a specific service.
  /// Similarly, `settings` allows you to adjust aspects like scan mode, report delay, and more.
  ///
  /// The method uses a [StreamController] to handle the asynchronous nature of BLE scanning. Every time a device is
  /// discovered by the native platform, the 'bleDeviceScanned' method is invoked, and the device information is
  /// parsed and added to the stream.
  @override
  Stream<BleDevice> startScan({List<ScanFilter>? filters, ScanSettings? settings}) {
    StreamController<BleDevice> streamController = StreamController<BleDevice>.broadcast();

    // Listen to the platform side for scanned devices.
    channel.setMethodCallHandler((MethodCall call) async {
      switch (call.method) {
        case 'bleDeviceScanned':
          try {
            BleDevice device;
            // Different operating systems will send the arguments in different formats. So, normalize the arguments
            // as a Map<dynamic, dynamic> for use in the BleDevice.fromMap factory constructor.
            if (call.arguments is String) {
              Map<dynamic, dynamic> argumentsParsed = json.decode(call.arguments);
              device = BleDevice.fromMap(argumentsParsed);
            } else {
              device = BleDevice.fromMap(call.arguments);
            }
            streamController.add(device);
          } catch (e) {
            streamController.addError(FormatException('Failed to parse discovered device info: $e'));
          }
        case 'error':
          streamController.addError(Exception(call.arguments));
          break;
      }
    });

    // Convert filters and settings into map representations if provided.
    final List<Map<String, dynamic>>? filtersMap = filters?.map((filter) => filter.toMap()).toList();
    final Map<String, dynamic>? settingsMap = settings?.toMap();

    // Begin the scan on the platform side, including the filters and settings in the method call if provided.
    channel.invokeMethod('startScan', {
      'filters': filtersMap,
      'settings': settingsMap,
    });

    return streamController.stream;
  }

  /// Stops an ongoing Bluetooth scan and handles any potential errors.
  @override
  Future<void> stopScan() async {
    try {
      // Stop the scan and wait for the method to complete.
      await channel.invokeMethod('stopScan');
    } on PlatformException catch (e) {
      // Handle different error types accordingly.
      if (e.message?.contains('permissions') == true) {
        throw BluetoothPermissionException('Permission error: ${e.message}');
      } else {
        throw BluetoothScanException('Failed to stop Bluetooth scan: ${e.message}');
      }
    }
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
    channel.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'bleConnectionState_$deviceAddress') {
        final String connectionStateString = call.arguments as String;
        final BleConnectionState state =
            BleConnectionState.values.firstWhere((value) => value.identifier == connectionStateString.toLowerCase());
        connectionStateStreamController.add(state);
      } else if (call.method == 'error') {
        connectionStateStreamController.addError(BluetoothConnectionException(call.arguments));
      }
    });

    channel.invokeMethod('connect', {'address': deviceAddress});
    return connectionStateStreamController.stream;
  }

  /// Initiates the service discovery process for a connected Bluetooth Low Energy (BLE) device and returns a
  /// [Stream] of discovered services and their characteristics.
  ///
  /// The service discovery process is a crucial step after establishing a BLE connection. It involves querying the
  /// connected peripheral to enumerate the services it offers along with their associated characteristics and
  /// descriptors. These services can represent various functionalities provided by the device, such as heart rate
  /// monitoring, temperature sensing, etc.
  ///
  /// The method uses a [StreamController] to handle the asynchronous nature of service discovery. The native
  /// platform code Android sends updates when new services and characteristics are discovered, which are then parsed
  /// and added to the stream.
  ///
  /// ## How Service Discovery Works
  ///
  /// 1. After connecting to a BLE device, you invoke the `discoverServices()` method, passing in the device address.
  /// 2. The native code kicks off the service discovery process.
  /// 3. As services and their characteristics are discovered, they are sent back to the Flutter app.
  /// 4. These updates are received in the `_handleBleServicesDiscovered` method (not shown here), which then
  ///    notifies all listeners to the stream.
  @override
  Stream<List<BleService>> discoverServices(String deviceAddress) {
    final StreamController<List<BleService>> servicesDiscoveredController =
        StreamController<List<BleService>>.broadcast();

    // Listen to the platform side for discovered services and their characteristics. The platform side differentiates
    // services discovered for different Bluetooth peripherals by appending the device address to the method name.
    _handleBleServicesDiscovered(deviceAddress, servicesDiscoveredController);

    channel.invokeMethod('discoverServices', {'address': deviceAddress});
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
    channel.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'bleServicesDiscovered_$deviceAddress') {
        final Map rawServicesMap = call.arguments as Map;

        // Construct a list of BleService objects from the raw data.
        final List<BleService> services = rawServicesMap.entries
            .map((entry) {
              if (entry.key is String && entry.value is List) {
                List<Map> rawCharacteristics = List<Map>.from(entry.value);

                try {
                  // Convert the raw characteristic maps to BleCharacteristic objects.
                  List<BleCharacteristic> characteristics = rawCharacteristics.map((charMap) {
                    // Manually convert the map to the desired type
                    Map<String, dynamic> typedMap =
                        Map.from(charMap).map((key, value) => MapEntry(key as String, value));
                    return BleCharacteristic.fromMap(typedMap);
                  }).toList();

                  return BleService(
                    serviceUuid: entry.key as String,
                    characteristics: characteristics,
                  );
                } catch (e) {
                  throw FormatException('Failed to get BleCharacteristic instance with exception, $e');
                }
              } else {
                // Return a null BleService to be filtered out later.
                return null;
              }
            })
            .where((service) => service != null)
            .cast<BleService>()
            .toList();

        servicesDiscoveredController.add(services);
      } else if (call.method == 'error') {
        servicesDiscoveredController.addError(ServiceDiscoveryException(call.arguments));
      }
    });
  }

  /// Asynchronously terminates the connection between the host mobile device and a Bluetooth Low Energy (BLE) peripheral.
  ///
  /// Disconnecting from a BLE device is an important part of BLE best practices. Proper disconnection ensures
  /// that resources like memory and battery are optimized on both the mobile device and the peripheral.
  ///
  /// ## Importance of Disconnecting
  ///
  /// 1. **Resource Management**: BLE connections occupy system resources. Failing to disconnect can lead to resource leakage.
  /// 2. **Battery Optimization**: BLE connections consume battery power on both connecting and connected devices. Timely disconnection helps in prolonging battery life.
  /// 3. **Security**: Maintaining an open connection can expose the devices to potential security risks.
  /// 4. **Connection Limits**: BLE peripherals often have a limit on the number of concurrent connections. Disconnecting when done ensures that other devices can connect.
  @override
  Future<void> disconnect(String deviceAddress) async {
    channel.invokeMethod('disconnect', {'address': deviceAddress});
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
    try {
      // Invoke the method channel to fetch the current connection state for the BLE device.
      final String connectionStateString = await channel.invokeMethod('getCurrentConnectionState', {
        'address': deviceAddress,
      });

      // Convert the string received from Kotlin to the Dart enum value.
      return BleConnectionState.values.firstWhere((e) => e.identifier == connectionStateString);
    } on PlatformException catch (e) {
      // Handle different error types accordingly.
      if (e.message?.contains('permissions') == true) {
        throw BluetoothPermissionException('Permission error: ${e.message}');
      } else {
        throw BluetoothConnectionException('Failed to get current connection state: ${e.message}');
      }
    }
  }

  /// Asynchronously writes data to a specified Bluetooth Low Energy (BLE) characteristic.
  ///
  /// ## BLE Communication Overview
  ///
  /// In the BLE protocol, devices communicate by reading and writing to 'characteristics' exposed by each other's
  /// services. Characteristics are essentially data variables that a peripheral device exposes to other devices.
  /// When writing data to a characteristic, the information is generally treated as a list of hexadecimal numbers,
  /// mapping to bytes at a relatively low level in the Bluetooth communication stack.
  ///
  /// ## Encrypted Write Operations
  ///
  /// If the target characteristic has encrypted write permissions, the Android operating system should automatically
  /// prompt the user to complete a pairing request with the BLE device. Pairing is a prerequisite to encrypted
  /// communication and enhances the security of the data exchange.
  ///
  /// ## Parameters
  ///
  /// - [characteristic]: The BLE characteristic to which the data will be written. This should include both the device
  ///   address and the UUID of the characteristic.
  /// - [value]: The data to be written to the characteristic, generally a string that will be converted into
  ///   bytes/hexadecimals.
  /// - [writeType]: Optional parameter to specify the type of write operation. Defaults to
  ///   `BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT`. Different write types have different transmission and
  ///   confirmation behaviors.
  @override
  Future<void> writeCharacteristic({
    required BleCharacteristic characteristic,
    required String value,
    int? writeType,
  }) async {
    try {
      await channel.invokeMethod('writeCharacteristic', {
        'address': characteristic.address,
        'characteristicUuid': characteristic.uuid,
        'value': value,
        if (writeType != null) 'writeType': writeType,
      });
    } on PlatformException catch (e) {
      // Handle different error types accordingly.
      if (e.message?.contains('permissions') == true) {
        throw BluetoothPermissionException('Permission error: ${e.message}');
      } else {
        throw BluetoothWriteException('Failed to write BLE characteristic: ${e.message}');
      }
    }
  }

  /// Reads the value of a specified Bluetooth characteristic.
  ///
  /// This method asynchronously fetches the value of a specified Bluetooth characteristic from a connected device
  /// and returns it as a [BleCharacteristicValue] instance.
  ///
  /// The method will throw a [TimeoutException] if it does not receive a response within the specified [timeout].
  /// This safeguards against situations where the asynchronous operation hangs indefinitely.
  ///
  /// Note: A [TimeoutException] does not necessarily indicate a failure in reading the characteristic, but rather
  /// that a response was not received in the given timeframe. Ensure that the timeout value is appropriate for the
  /// expected device response times and consider retrying the operation if necessary.
  ///
  /// - `address`: The MAC address of the Bluetooth device. This uniquely identifies
  ///   the device and is used to fetch the associated BluetoothGatt instance.
  /// - `characteristicUuid`: The UUID of the characteristic whose value is to be read.
  ///   This UUID should match one of the characteristics available on the connected
  ///   Bluetooth device.
  /// - `timeout`: The maximum amount of time this function will wait for a response from
  ///   the platform side. If this duration is exceeded without receiving a response,
  ///   a [TimeoutException] will be thrown. Ensure that this duration accounts for
  ///   potential delays in device communication.
  ///
  /// Returns a `Future<BleCharacteristicValue>` that completes with the characteristic value once it has been read.
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
    required BleCharacteristic characteristic,
    required Duration timeout,
  }) async {
    final completer = Completer<BleCharacteristicValue>();

    channel.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'onCharacteristicRead') {
        final BleCharacteristicValue response;
        try {
          response = BleCharacteristicValue.fromMap(call.arguments);
        } catch (e) {
          rethrow;
        }
        completer.complete(response);
        channel.setMethodCallHandler(null); // Reset the handler to avoid future calls.
      }
    });

    // Read the value of the characteristic.
    try {
      channel.invokeMethod('readCharacteristic', {
        'address': characteristic.address,
        'characteristicUuid': characteristic.uuid,
      });
    } on PlatformException catch (e) {
      // Handle different error types accordingly.
      if (e.message?.contains('permissions') == true) {
        throw BluetoothPermissionException('Permission error: ${e.message}');
      } else {
        throw BluetoothReadException('Failed to read BLE characteristic: ${e.message}');
      }
    }

    // Implement the timeout logic.
    return completer.future.timeout(
      timeout,
      onTimeout: () {
        // If the timeout occurs, reset the method call handler and throw an error.
        channel.setMethodCallHandler(null);
        throw TimeoutException('Failed to read characteristic within the given timeout', timeout);
      },
    );
  }

  /// Subscribes to a Bluetooth characteristic to listen for updates.
  ///
  /// A caller to this function will receive a [Stream] of [BleCharacteristicValue] objects. A caller should listen
  /// to this stream and establish a callback function invoked each time a new value is emitted to the stream. Once
  /// subscribed, any updates to the characteristic value will be sent as a stream of [BleCharacteristicValue] objects.
  @override
  Stream<BleCharacteristicValue> subscribeToCharacteristic(BleCharacteristic characteristic) {
    StreamController<BleCharacteristicValue> streamController = StreamController<BleCharacteristicValue>.broadcast();

    // Listen for characteristic updates from the platform side.
    channel.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'onCharacteristicChanged') {
        final BleCharacteristicValue value;
        try {
          value = BleCharacteristicValue.fromMap(call.arguments);
        } catch (e) {
          streamController.addError(Exception('Failed to parse characteristic value: $e'));
          return;
        }
        streamController.add(value);
      }
    });

    // Trigger the subscription to the characteristic on the platform side.
    try {
      channel.invokeMethod('subscribeToCharacteristic', {
        'address': characteristic.address,
        'characteristicUuid': characteristic.uuid,
      });
    } on PlatformException catch (e) {
      // Handle different error types accordingly.
      if (e.message?.contains('permissions') == true) {
        streamController.addError(BluetoothPermissionException('Permission error: ${e.message}'));
        throw BluetoothPermissionException('Permission error: ${e.message}');
      } else {
        streamController
            .addError(BluetoothSubscriptionException('Failed to subscribe to BLE characteristic: ${e.message}'));
        throw BluetoothSubscriptionException('Failed to subscribe to BLE characteristic: ${e.message}');
      }
    }

    return streamController.stream;
  }

  /// Unsubscribes from a Bluetooth characteristic.
  ///
  /// This method stops listening for updates for a given characteristic on a specified device.
  @override
  void unsubscribeFromCharacteristic(BleCharacteristic characteristic) {
    try {
      channel.invokeMethod('unsubscribeFromCharacteristic', {
        'address': characteristic.address,
        'characteristicUuid': characteristic.uuid,
      });
    } on PlatformException catch (e) {
      // Handle different error types accordingly.
      if (e.message?.contains('permissions') == true) {
        throw BluetoothPermissionException('Permission error: ${e.message}');
      } else {
        throw BluetoothSubscriptionException('Failed to unsubscribe from BLE characteristic: ${e.message}');
      }
    }
  }

  /// Requests Bluetooth permissions from the user.
  ///
  /// This method communicates with the native platform code to request Bluetooth permissions.
  /// It returns one of the values from the [BluetoothPermissionStatus] enumeration.
  ///
  /// * `BluetoothPermissionStatus.GRANTED`: Permission is granted.
  /// * `BluetoothPermissionStatus.DENIED`: Permission is denied.
  ///
  /// Returns a [Future] containing the [BluetoothPermissionStatus] representing whether permission was granted or not.
  @override
  Future<BluetoothPermissionStatus> requestBluetoothPermissions() async {
    final String permissionStatusString = await channel.invokeMethod('requestBluetoothPermissions');
    return BluetoothPermissionStatus.values.firstWhere((status) => status.identifier == permissionStatusString);
  }

  /// Emits the current Bluetooth permission status to the Dart side.
  ///
  /// This method communicates with the native platform code to obtain the current Bluetooth permission status and emits it to any listeners on the Dart side.
  ///
  /// Listeners on the Dart side will receive one of the following enum values from [BluetoothPermissionStatus]:
  ///
  /// * `BluetoothPermissionStatus.GRANTED`: Indicates that Bluetooth permission is granted.
  /// * `BluetoothPermissionStatus.DENIED`: Indicates that Bluetooth permission is denied.
  ///
  /// Returns a [Stream] of [BluetoothPermissionStatus] values representing the current Bluetooth permission status on the device.
  @override
  Stream<BluetoothPermissionStatus> emitCurrentPermissionStatus() {
    final StreamController<BluetoothPermissionStatus> streamController =
        StreamController<BluetoothPermissionStatus>.broadcast();

    channel.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'permissionStatusUpdated') {
        final String permissionStatusString = call.arguments as String;

        // Convert the string status to its corresponding enum value
        final BluetoothPermissionStatus status = BluetoothPermissionStatus.values.firstWhere(
          (status) => status.identifier == permissionStatusString,
        );

        streamController.add(status);
      }
    });

    // Begin emitting Bluetooth permission status updates from the platform side.
    channel.invokeMethod('emitCurrentPermissionStatus');

    return streamController.stream;
  }
}
