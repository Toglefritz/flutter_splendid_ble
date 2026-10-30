import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../shared/ble_common_utilities.dart';
import '../shared/ble_method_channel_router.dart';
import '../shared/models/ble_device.dart';
import '../shared/models/bluetooth_permission_status.dart';
import '../shared/models/bluetooth_status.dart';
import 'central_platform_interface.dart';
import 'extensions/scan_filter_list_extensions.dart';
import 'models/ble_bond_event.dart';
import 'models/ble_bond_failure.dart';
import 'models/ble_bond_state.dart';
import 'models/ble_characteristic.dart';
import 'models/ble_characteristic_value.dart';
import 'models/ble_connection_event.dart';
import 'models/ble_connection_parameters.dart';
import 'models/ble_connection_priority.dart';
import 'models/ble_connection_state.dart';
import 'models/ble_phy.dart';
import 'models/ble_service.dart';
import 'models/connected_ble_device.dart';
import 'models/exceptions/bluetooth_connection_exception.dart';
import 'models/exceptions/bluetooth_permission_exception.dart';
import 'models/exceptions/bluetooth_read_exception.dart';
import 'models/exceptions/bluetooth_scan_exception.dart';
import 'models/exceptions/bluetooth_subscription_exception.dart';
import 'models/exceptions/bluetooth_write_exception.dart';
import 'models/exceptions/gatt_cache_exception.dart';
import 'models/exceptions/service_discovery_exception.dart';
import 'models/scan_filter.dart';
import 'models/scan_settings.dart';

/// An implementation of [CentralPlatformInterface] that uses method channels.
// Event streams returned by this class are derived from the shared BleMethodChannelRouter. Callers should cancel their
// subscriptions when they are no longer needed so the router stops delivering events to them.
class CentralMethodChannel extends CentralPlatformInterface {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final MethodChannel channel =
      const MethodChannel('flutter_splendid_ble_central');

  /// Checks the status of the Bluetooth adapter on the device.
  ///
  /// This method communicates with the native Android code to obtain the current status of the Bluetooth adapter, and
  /// returns one of the values from the [BluetoothStatus] enumeration.
  ///
  /// * `BluetoothStatus.ENABLED`: Bluetooth is enabled and ready for connections.
  /// * `BluetoothStatus.DISABLED`: Bluetooth is disabled and not available for use.
  /// * `BluetoothStatus.NOT_AVAILABLE`: Bluetooth is not available on the device.
  ///
  /// Returns a Future containing the [BluetoothStatus] representing the current status of the Bluetooth adapter on the
  /// device.
  ///
  /// It can be useful to check on the status of the Bluetooth adapter prior to attempting Bluetooth operations as a way
  /// of improving the user experience. Checking on the state of the Bluetooth adapter allows the user to be notified
  /// and prompted for action if they attempt to use an applications for which Bluetooth plays a critical role while the
  /// Bluetooth capabilities of the host device are disabled.
  @override
  Future<BluetoothStatus> checkBluetoothAdapterStatus() async {
    return BleCommonUtilities.checkBluetoothAdapterStatus(channel);
  }

  /// Emits the current Bluetooth adapter status to the Dart side.
  ///
  /// This method communicates with the native Android code to obtain the current status of the Bluetooth adapter and
  /// emits it to any listeners on the Dart side.
  ///
  /// Listeners on the Dart side will receive one of the following enum values from [BluetoothStatus]:
  ///
  /// * `BluetoothStatus.enabled`: Indicates that Bluetooth is enabled and ready for connections.
  /// * `BluetoothStatus.disabled`: Indicates that Bluetooth is disabled and not available for use.
  /// * `BluetoothStatus.notAvailable`: Indicates that Bluetooth is not available on the device.
  ///
  /// Returns a [Future] containing a [Stream] of [BluetoothStatus] values representing the current status of the
  /// Bluetooth adapter on the device.
  @override
  Future<Stream<BluetoothStatus>> emitCurrentBluetoothStatus() async {
    final Stream<BluetoothStatus> bluetoothStatusStream =
        await BleCommonUtilities.emitCurrentBluetoothStatus(channel);

    return bluetoothStatusStream;
  }

  /// Requests Bluetooth permissions from the user.
  ///
  /// This method communicates with the native platform code to request Bluetooth permissions. It returns one of the
  /// values from the [BluetoothPermissionStatus] enumeration.
  ///
  /// * `BluetoothPermissionStatus.GRANTED`: Permission is granted.
  /// * `BluetoothPermissionStatus.DENIED`: Permission is denied.
  ///
  /// Returns a [Future] containing the [BluetoothPermissionStatus] representing whether permission was granted or not.
  @override
  Future<BluetoothPermissionStatus> requestBluetoothPermissions() async {
    return BleCommonUtilities.requestBluetoothPermissions(channel);
  }

  /// Emits the current Bluetooth permission status to the Dart side.
  ///
  /// This method communicates with the native platform code to obtain the current Bluetooth permission status and emits
  /// it to any listeners on the Dart side.
  ///
  /// Listeners on the Dart side will receive one of the following enum values from [BluetoothPermissionStatus]:
  ///
  /// * `BluetoothPermissionStatus.GRANTED`: Indicates that Bluetooth permission is granted.
  /// * `BluetoothPermissionStatus.DENIED`: Indicates that Bluetooth permission is denied.
  ///
  /// Returns a [Stream] of [BluetoothPermissionStatus] values representing the current Bluetooth permission status on
  /// the device.
  @override
  Future<Stream<BluetoothPermissionStatus>>
      emitCurrentPermissionStatus() async {
    final Stream<BluetoothPermissionStatus> permissionStatusStream =
        await BleCommonUtilities.emitCurrentPermissionStatus(channel);

    return permissionStatusStream;
  }

  /// Gets a list of identifiers for all connected devices.
  ///
  /// This method communicates with the native platform code to obtain a list of all connected devices. It returns a
  /// list of device identifiers as strings.
  ///
  /// On iOS, the identifiers returned by this method are the UUIDs of the connected peripherals. This means that the
  /// identifiers are specific to the iOS device on which this method is called. The same Bluetooth device will be
  /// associated with different identifiers on different iOS devices. Therefore, it may be necessary for the Flutter
  /// side to maintain a mapping between the device identifiers and the device addresses, or other identifiers, if
  /// cross-device consistency is required.
  ///
  /// On Android, the process is simpler because this method will return a list of BDA (Bluetooth Device Address)
  /// strings, which are unique identifiers for each connected device. These identifiers are consistent across devices.
  ///
  /// Returns a [Future] containing a list of [ConnectedBleDevice] objects representing Bluetooth devices.
  @override
  Future<List<ConnectedBleDevice>> getConnectedDevices(
    List<String> serviceUUIDs,
  ) async {
    try {
      // Prepare the arguments with the list of UUIDs
      final Map<String, dynamic> arguments = {
        'serviceUUIDs': serviceUUIDs,
      };

      // Call the platform-specific code via Method Channel
      final List<dynamic> connectedDevices = await channel.invokeMethod(
        'getConnectedDevices',
        arguments,
      ) as List<dynamic>;

      // Convert the dynamic list to a strongly-typed list of maps
      final List<ConnectedBleDevice> devices =
          connectedDevices.map((dynamic device) {
        final Map<dynamic, dynamic> deviceMap = device as Map<dynamic, dynamic>;
        return ConnectedBleDevice.fromMap(deviceMap);
      }).toList();

      return devices;
    } on PlatformException catch (e) {
      throw Exception('Failed to get connected devices: ${e.message}');
    }
  }

  /// Starts a scan for nearby Bluetooth Low Energy (BLE) devices and returns a stream of discovered devices.
  ///
  /// Scanning for BLE devices is a crucial step in establishing a BLE connection. It allows the mobile app to discover
  /// nearby BLE devices and gather essential information like device name, MAC address, and more. This method starts
  /// the scanning operation on the platform side and listens for discovered devices.
  ///
  /// The function takes optional `filters` and `settings` parameters that allow for more targeted device scanning. For
  /// example, you could specify a filter to only discover devices that are advertising a specific service. Similarly,
  /// `settings` allows you to adjust aspects like scan mode, report delay, and more.
  ///
  /// The method returns a broadcast stream derived from the shared [BleMethodChannelRouter]. Every time a device is
  /// discovered by the native platform, the 'bleDeviceScanned' method is invoked, and the device information is parsed
  /// and added to the stream. Starting another BLE operation does not stop this stream from receiving results.
  @override
  Future<Stream<BleDevice>> startScan({
    List<ScanFilter>? filters,
    ScanSettings? settings,
  }) async {
    // Listen to the platform side for scanned devices. The router delivers scan results to every scan stream, so a
    // concurrent connect, discovery, or status call does not silence this one.
    final Stream<BleDevice> scanStream = BleMethodChannelRouter.forChannel(
      channel,
    ).operationCalls('bleDeviceScanned').transform(
      StreamTransformer<MethodCall, BleDevice>.fromHandlers(
        handleData: (MethodCall call, EventSink<BleDevice> sink) {
          switch (call.method) {
            case 'bleDeviceScanned':
              try {
                BleDevice device;
                // Different operating systems will send the arguments in different formats. So, normalize the
                // arguments as a Map<dynamic, dynamic> for use in the BleDevice.fromMap factory constructor.
                if (call.arguments is String) {
                  final Map<dynamic, dynamic> argumentsParsed =
                      json.decode(call.arguments as String)
                          as Map<dynamic, dynamic>;
                  device = BleDevice.fromMap(argumentsParsed);
                } else {
                  device = BleDevice.fromMap(
                    call.arguments as Map<dynamic, dynamic>,
                  );
                }

                // Apply additional filtering on Dart side. Filtering is also done on the native side, but this allows
                // for more complex filtering logic that may not be feasible on the native side. If the device matches
                // the provided filters, add it to the stream.
                if (filters.deviceMatchesFilters(device)) {
                  sink.add(device);
                }
              } catch (e) {
                sink.addError(
                  FormatException('Failed to parse discovered device info: $e'),
                );
              }
            case BleMethodChannelRouter.errorMethod:
              sink.addError(Exception(call.arguments));
          }
        },
      ),
    );

    // Convert filters and settings into map representations if provided.
    final List<Map<String, dynamic>>? filtersMap =
        filters?.map((filter) => filter.toMap()).toList();
    final Map<String, dynamic>? settingsMap = settings?.toMap();

    // Begin the scan on the platform side, including the filters and settings in the method call if provided.
    await channel.invokeMethod('startScan', {
      'filters': filtersMap,
      'settings': settingsMap,
    });

    return scanStream;
  }

  /// Stops an ongoing Bluetooth scan and handles any potential errors.
  @override
  Future<void> stopScan() async {
    try {
      // Stop the scan and wait for the method to complete.
      await channel.invokeMethod('stopScan');
    } on PlatformException catch (e) {
      // Handle different error types accordingly.
      if (e.message?.contains('permissions') ?? false) {
        throw BluetoothPermissionException('Permission error: ${e.message}');
      } else {
        throw BluetoothScanException(
          'Failed to stop Bluetooth scan: ${e.message}',
        );
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
  /// connection status updates for each peripheral by appending the peripherals' Bluetooth addresses to the method
  /// channel names. For example, the connection states for a particular module with address, *10:91:A8:32:8C:BA* would
  /// be communicated with the method channel name, "bleConnectionState_10:91:A8:32:8C:BA". In this way, a different
  /// [Stream] of [BleConnectionState] values is established for each Bluetooth peripheral.
  @override
  Future<Stream<BleConnectionEvent>> connect({
    required String deviceAddress,
  }) async {
    // Listen to the platform side for connection state updates before asking the platform to connect.
    final Stream<BleConnectionEvent> connectionEvents =
        _connectionEvents(deviceAddress);

    await channel.invokeMethod('connect', {'address': deviceAddress});

    return connectionEvents;
  }

  /// Returns a broadcast stream of connection events for the device with [deviceAddress].
  ///
  /// The platform side differentiates connection state updates for different Bluetooth peripherals by appending the
  /// device address to the method name (e.g., "bleConnectionState_<address>"). Every stream returned for an address
  /// receives every update for it, so connecting to or observing another device, or starting any other BLE operation,
  /// does not silence earlier streams. Untargeted native `error` callbacks are emitted as
  /// [BluetoothConnectionException] errors while this is the most recently started operation; see
  /// [BleMethodChannelRouter.operationCalls].
  Stream<BleConnectionEvent> _connectionEvents(String deviceAddress) {
    return BleMethodChannelRouter.forChannel(channel)
        .operationCalls('bleConnectionState_$deviceAddress')
        .map((MethodCall call) {
      if (call.method == BleMethodChannelRouter.errorMethod) {
        throw BluetoothConnectionException(call.arguments as String);
      }

      return _parseConnectionEvent(call.arguments);
    });
  }

  /// Parses the raw method channel arguments for a `bleConnectionState_<address>` call into a [BleConnectionEvent].
  ///
  /// The native layer sends a map describing the state and any failure detail. This helper is defensive: a `null` or
  /// unexpectedly-typed payload still yields a well-formed event with [BleConnectionState.unknown], so a malformed
  /// message can never throw inside the method channel handler. (This replaces the previous `firstWhere`-without-
  /// `orElse` logic, which threw a [StateError] when the native layer emitted a status — such as `"FAILED"` — that had
  /// no matching enum case.)
  ///
  /// - Parameter [arguments]: The raw `call.arguments` received from the platform.
  /// - Returns: The decoded [BleConnectionEvent].
  BleConnectionEvent _parseConnectionEvent(Object? arguments) {
    if (arguments is Map) {
      return BleConnectionEvent.fromMap(arguments.cast<Object?, Object?>());
    }

    // Defensive fallback for an unexpected payload shape. The native layer is expected to always send a map.
    return const BleConnectionEvent(state: BleConnectionState.unknown);
  }

  /// Initiates the service discovery process for a connected Bluetooth Low Energy (BLE) device and returns a [Stream]
  /// of discovered services and their characteristics.
  ///
  /// The service discovery process is a crucial step after establishing a BLE connection. It involves querying the
  /// connected peripheral to enumerate the services it offers along with their associated characteristics and
  /// descriptors. These services can represent various functionalities provided by the device, such as heart rate
  /// monitoring, temperature sensing, etc.
  ///
  /// The method uses a [StreamController] to handle the asynchronous nature of service discovery. The native platform
  /// code Android sends updates when new services and characteristics are discovered, which are then parsed and added
  /// to the stream.
  ///
  /// ## How Service Discovery Works
  ///
  /// 1. After connecting to a BLE device, you invoke the `discoverServices()` method, passing in the device address.
  /// 2. The native code kicks off the service discovery process.
  /// 3. As services and their characteristics are discovered, they are sent back to the Flutter app.
  /// 4. These updates are received in the `_handleBleServicesDiscovered` method (not shown here), which then
  /// notifies all listeners to the stream.
  @override
  Future<Stream<List<BleService>>> discoverServices(
    String deviceAddress,
  ) async {
    // Listen to the platform side for discovered services and their characteristics. The platform side differentiates
    // services discovered for different Bluetooth peripherals by appending the device address to the method name.
    final Stream<List<BleService>> servicesDiscovered =
        _servicesDiscovered(deviceAddress);

    await channel.invokeMethod('discoverServices', {'address': deviceAddress});

    return servicesDiscovered;
  }

  /// Returns a broadcast stream of the BLE services and characteristics discovered for a specific peripheral device.
  ///
  /// Service and characteristic discovery is a fundamental step in BLE communication. Once a connection with a BLE
  /// peripheral is established, the central device (in this case, our Flutter app) must discover the services offered
  /// by the peripheral to understand how to communicate with it effectively. Each service can have multiple
  /// characteristics, which are like "channels" of communication. By understanding these services and characteristics,
  /// our Flutter app can read from or write to these channels to facilitate meaningful exchanges of data.
  ///
  /// The purpose of this method is to convert the raw service and characteristic data received from the method channel
  /// into a structured format (a list of [BleService] objects) for Dart. Malformed payloads are emitted as stream
  /// errors. Untargeted native `error` callbacks are emitted as [ServiceDiscoveryException] errors while this is the
  /// most recently started operation; see [BleMethodChannelRouter.operationCalls].
  ///
  /// [deviceAddress] is the MAC address of the target BLE device.
  Stream<List<BleService>> _servicesDiscovered(String deviceAddress) {
    return BleMethodChannelRouter.forChannel(channel)
        .operationCalls('bleServicesDiscovered_$deviceAddress')
        .map((MethodCall call) {
      if (call.method == BleMethodChannelRouter.errorMethod) {
        throw ServiceDiscoveryException(call.arguments as String);
      }

      final Map<dynamic, dynamic> rawServicesMap = call.arguments as Map;

      // Construct a list of BleService objects from the raw data.
      final List<BleService> services = rawServicesMap.entries
          .map((entry) {
            if (entry.key is String && entry.value is List) {
              final List<Map<dynamic, dynamic>> rawCharacteristics =
                  List<Map<dynamic, dynamic>>.from(
                entry.value as List<dynamic>,
              );

              try {
                // Convert the raw characteristic maps to BleCharacteristic objects.
                final List<BleCharacteristic> characteristics =
                    rawCharacteristics.map((charMap) {
                  // Manually convert the map to the desired type
                  final Map<String, dynamic> typedMap =
                      Map<dynamic, dynamic>.from(charMap).map(
                    (key, value) => MapEntry(key as String, value),
                  );
                  return BleCharacteristic.fromMap(typedMap);
                }).toList();

                return BleService(
                  serviceUuid: entry.key as String,
                  characteristics: characteristics,
                );
              } catch (e) {
                throw FormatException(
                  'Failed to get BleCharacteristic instance with exception, $e',
                );
              }
            } else {
              // Return a null BleService to be filtered out later.
              return null;
            }
          })
          .where((service) => service != null)
          .cast<BleService>()
          .toList();

      return services;
    });
  }

  /// Asynchronously terminates the connection between the host mobile device and a Bluetooth Low Energy (BLE)
  /// peripheral.
  ///
  /// Disconnecting from a BLE device is an important part of BLE best practices. Proper disconnection ensures that
  /// resources like memory and battery are optimized on both the mobile device and the peripheral.
  ///
  /// ## Importance of Disconnecting
  ///
  /// 1. **Resource Management**: Disconnecting releases the system resources occupied by a BLE connection.
  /// 2. **Battery Optimization**: Disconnecting reduces power consumption on both connected devices.
  /// 3. **Security**: Maintaining an open connection can expose the devices to potential security risks.
  /// 4. **Connection Limits**: Disconnecting frees a peripheral connection slot for another device.
  @override
  Future<void> disconnect(String deviceAddress) async {
    await channel.invokeMethod('disconnect', {'address': deviceAddress});
  }

  /// Fetches the current connection state of a Bluetooth Low Energy (BLE) device.
  ///
  /// The [deviceAddress] parameter specifies the MAC address of the target device.
  ///
  /// This method calls the 'getCurrentConnectionState' method on the native Android implementation via a method
  /// channel. It then returns a [Future] that resolves to the [ConnectionState] enum, which represents the current
  /// connection state of the device.
  ///
  /// Returns a [Future] containing the [ConnectionState] representing the current connection state of the BLE device
  /// with the specified address.
  @override
  Future<BleConnectionState> getCurrentConnectionState(
    String deviceAddress,
  ) async {
    try {
      // Invoke the method channel to fetch the current connection state for the BLE device.
      final String connectionStateString =
          await channel.invokeMethod('getCurrentConnectionState', {
        'address': deviceAddress,
      }) as String;

      // Convert the string received from the native platform to the Dart enum value. Unrecognized values resolve to
      // BleConnectionState.unknown rather than throwing a StateError.
      return BleConnectionState.fromIdentifier(connectionStateString);
    } on PlatformException catch (e) {
      // Handle different error types accordingly.
      if (e.message?.contains('permissions') ?? false) {
        throw BluetoothPermissionException('Permission error: ${e.message}');
      } else {
        throw BluetoothConnectionException(
          'Failed to get current connection state: ${e.message}',
        );
      }
    }
  }

  /// Observes connection state changes for a BLE device without initiating a connection.
  ///
  /// This method sets up a stream to monitor connection state changes for a device that has been previously discovered
  /// or connected. Unlike [connect], this method does not initiate a connection attempt - it only observes state
  /// changes.
  ///
  /// The device must have been discovered through scanning or previously connected before this method can monitor its
  /// state. The platform side automatically emits connection state updates for all known devices (devices in the
  /// peripheralsMap), so this method simply sets up a listener for those updates.
  ///
  /// This is useful for:
  /// - Monitoring devices that may reconnect automatically
  /// - Observing connection changes initiated by other apps or the system
  /// - Tracking connection state without actively managing the connection
  ///
  /// The [deviceAddress] parameter specifies the device to monitor.
  ///
  /// Returns a [Stream] of [BleConnectionState] that emits whenever the connection state changes for the specified
  /// device. The stream will emit:
  /// - "CONNECTED" when the device connects
  /// - "DISCONNECTED" when the device disconnects
  /// - "CONNECTING" during connection establishment (platform-dependent)
  /// - "DISCONNECTING" during disconnection (platform-dependent)
  ///
  /// Throws a [BluetoothConnectionException] if an error occurs while setting up monitoring.
  @override
  Future<Stream<BleConnectionEvent>> observeConnectionState({
    required String deviceAddress,
  }) async {
    // Note: Unlike connect(), we do NOT call the platform's connect method here. We're only setting up the listener for
    // state changes. The platform will emit connection state updates for any known device (discovered or previously
    // connected) when its state changes, regardless of whether we initiated the connection.
    return _connectionEvents(deviceAddress);
  }

  /// Observes the operating-system-managed bonding (pairing) process for the device with the given [deviceAddress].
  ///
  /// ## The operating system owns bonding
  ///
  /// Bonding is performed by the OS, not by this plugin. This method does not *trigger* a bond; it asks the native
  /// layer to begin reporting the bond-state transitions the OS surfaces, delivered on the
  /// `bleBondState_<deviceAddress>` method channel call and decoded into [BleBondEvent]s.
  ///
  /// ## Platform behavior
  ///
  /// * **Android:** Subscribes to the `ACTION_BOND_STATE_CHANGED` broadcast and emits rich updates, including a
  ///   normalized failure category and raw unbond reason code on failure. The device's current bond state is emitted
  ///   immediately upon subscription.
  /// * **iOS / macOS:** Bonding visibility is best-effort and limited by the platform (CoreBluetooth exposes no bonding
  ///   API). Updates are derived from the lifecycle of operations on encrypted characteristics: `bonding` when such an
  ///   operation begins, `bonded` on success, and `failed` on an authentication/encryption error. An initial `unknown`
  ///   is emitted because the actual bond state cannot be read. See [BleBondFailure] for the documented limitation.
  ///
  /// Returns a [Stream] of [BleBondEvent] for the specified device.
  @override
  Future<Stream<BleBondEvent>> observeBondState({
    required String deviceAddress,
  }) async {
    // Listen for bond state updates from the platform. The platform side differentiates bond state updates for
    // different devices by appending the device address to the method name (e.g., "bleBondState_<address>"). Every
    // stream for this address receives every update, so later BLE operations do not silence it.
    final Stream<BleBondEvent> bondEvents =
        BleMethodChannelRouter.forChannel(channel)
            .operationCalls('bleBondState_$deviceAddress')
            .map((MethodCall call) {
      if (call.method == BleMethodChannelRouter.errorMethod) {
        throw BluetoothConnectionException(call.arguments as String);
      }

      return _parseBondEvent(call.arguments);
    });

    // Ask the native layer to begin observing this device's bond state. On Android this registers the
    // ACTION_BOND_STATE_CHANGED receiver (if needed) and emits the current bond state; on iOS/macOS this records the
    // device for best-effort reporting from the encrypted-operation path.
    await channel.invokeMethod('observeBondState', {'address': deviceAddress});

    return bondEvents;
  }

  /// Parses the raw method channel arguments for a `bleBondState_<address>` call into a [BleBondEvent].
  ///
  /// This helper is defensive: a `null` or unexpectedly-typed payload still yields a well-formed event with
  /// [BleBondState.unknown], so a malformed message can never throw inside the method channel handler.
  ///
  /// - Parameter [arguments]: The raw `call.arguments` received from the platform.
  /// - Returns: The decoded [BleBondEvent].
  BleBondEvent _parseBondEvent(Object? arguments) {
    if (arguments is Map) {
      return BleBondEvent.fromMap(arguments.cast<Object?, Object?>());
    }

    // Defensive fallback for an unexpected payload shape. The native layer is expected to always send a map.
    return const BleBondEvent(state: BleBondState.unknown);
  }

  /// Asynchronously writes data to a specified Bluetooth Low Energy (BLE) characteristic.
  ///
  /// ## BLE Communication Overview
  ///
  /// In the BLE protocol, devices communicate by reading and writing to 'characteristics' exposed by each other's
  /// services. Characteristics are essentially data variables that a peripheral device exposes to other devices. When
  /// writing data to a characteristic, the information is generally treated as a list of hexadecimal numbers, mapping
  /// to bytes at a relatively low level in the Bluetooth communication stack.
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
  /// address and the UUID of the characteristic.
  /// - [value]: The data to be written to the characteristic, generally a string that will be converted into
  /// bytes/hexadecimals.
  /// - [writeType]: Optional parameter to specify the type of write operation. Defaults to
  /// `BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT`. Different write types have different transmission and
  /// confirmation behaviors.
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
      if (e.message?.contains('permissions') ?? false) {
        throw BluetoothPermissionException('Permission error: ${e.message}');
      } else {
        throw BluetoothWriteException(
          'Failed to write BLE characteristic: ${e.message}',
        );
      }
    }
  }

  /// Reads the value of a specified Bluetooth characteristic.
  ///
  /// This method asynchronously fetches the value of a specified Bluetooth characteristic from a connected device and
  /// returns it as a [BleCharacteristicValue] instance.
  ///
  /// The method will throw a [TimeoutException] if it does not receive a response within the specified [timeout]. This
  /// safeguards against situations where the asynchronous operation hangs indefinitely.
  ///
  /// Note: A [TimeoutException] does not necessarily indicate a failure in reading the characteristic, but rather that
  /// a response was not received in the given timeframe. Ensure that the timeout value is appropriate for the expected
  /// device response times and consider retrying the operation if necessary.
  ///
  /// - `address`: The MAC address of the Bluetooth device. This uniquely identifies
  /// the device and is used to fetch the associated BluetoothGatt instance.
  /// - `characteristicUuid`: The UUID of the characteristic whose value is to be read.
  /// This UUID should match one of the characteristics available on the connected Bluetooth device.
  /// - `timeout`: The maximum amount of time this function will wait for a response from
  /// the platform side. If this duration is exceeded without receiving a response, a [TimeoutException] will be thrown.
  /// Ensure that this duration accounts for potential delays in device communication.
  ///
  /// Returns a `Future<BleCharacteristicValue>` that completes with the characteristic value once it has been read.
  ///
  /// Example usage:
  /// ```dart
  /// try {
  /// BleCharacteristicValue characteristicValue = await readCharacteristic(
  /// address: '00:1A:7D:DA:71:13',
  /// characteristicUuid: '00002a00-0000-1000-8000-00805f9b34fb',
  /// timeout: Duration(seconds: 10),
  /// );
  /// print(characteristicValue.value);
  /// } catch (e) {
  /// print('Failed to read characteristic: $e');
  /// }
  /// ```
  @override
  Future<BleCharacteristicValue> readCharacteristic({
    required BleCharacteristic characteristic,
    required Duration timeout,
  }) async {
    final Completer<BleCharacteristicValue> completer =
        Completer<BleCharacteristicValue>();

    // Listen for the read response before requesting it. Every read receives every native read response, so only the
    // response for this characteristic's address and UUID completes this read. Concurrent reads and other BLE
    // operations are unaffected.
    final StreamSubscription<BleCharacteristicValue> subscription =
        BleMethodChannelRouter.forChannel(channel)
            .callsNamed('onCharacteristicRead')
            .where(
              (MethodCall call) => _matchesCharacteristic(call, characteristic),
            )
            .map(
              (MethodCall call) => BleCharacteristicValue.fromMap(
                call.arguments as Map<Object?, Object?>,
              ),
            )
            .listen(
      (BleCharacteristicValue value) {
        if (!completer.isCompleted) completer.complete(value);
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!completer.isCompleted) completer.completeError(error, stackTrace);
      },
    );

    try {
      // Read the value of the characteristic.
      try {
        await channel.invokeMethod('readCharacteristic', {
          'address': characteristic.address,
          'characteristicUuid': characteristic.uuid,
        });
      } on PlatformException catch (e) {
        // Handle different error types accordingly.
        if (e.message?.contains('permissions') ?? false) {
          throw BluetoothPermissionException('Permission error: ${e.message}');
        } else {
          throw BluetoothReadException(
            'Failed to read BLE characteristic: ${e.message}',
          );
        }
      }

      // Implement the timeout logic.
      return await completer.future.timeout(
        timeout,
        onTimeout: () {
          throw TimeoutException(
            'Failed to read characteristic within the given timeout',
            timeout,
          );
        },
      );
    } finally {
      // Release this read's listener whether it succeeded, failed, or timed out.
      await subscription.cancel();
    }
  }

  /// Whether a characteristic callback [call] identifies the same device and UUID as [characteristic], ignoring case.
  ///
  /// Both native platforms send `deviceAddress` and `characteristicUuid` in characteristic read and notification
  /// payloads. Throws a [FormatException] if the payload is not a map or does not carry both identifiers, so that
  /// malformed native messages surface as stream errors rather than being silently dropped.
  bool _matchesCharacteristic(
    MethodCall call,
    BleCharacteristic characteristic,
  ) {
    final Object? arguments = call.arguments;
    if (arguments is! Map<Object?, Object?>) {
      throw const FormatException(
        'Characteristic callback must contain a map.',
      );
    }
    final Object? eventAddress = arguments['deviceAddress'];
    final Object? eventUuid = arguments['characteristicUuid'];
    if (eventAddress is! String || eventUuid is! String) {
      throw const FormatException(
        'Characteristic callback must identify its device and UUID.',
      );
    }

    return eventAddress.toUpperCase() == characteristic.address.toUpperCase() &&
        eventUuid.toUpperCase() == characteristic.uuid.toUpperCase();
  }

  /// Subscribes to a Bluetooth characteristic to listen for updates.
  ///
  /// A caller to this function will receive a [Stream] of [BleCharacteristicValue] objects. A caller should listen to
  /// this stream and establish a callback function invoked each time a new value is emitted to the stream. Once
  /// subscribed, any updates to the characteristic value will be sent as a stream of [BleCharacteristicValue] objects.
  ///
  /// The broadcast stream contains only updates matching both the address and UUID of [characteristic], ignoring case.
  /// Subscribing to another characteristic or starting another BLE operation does not replace its notification
  /// receiver. Cancelling a listener does not disable native notifications; use [unsubscribeFromCharacteristic] to
  /// disable them.
  @override
  Future<Stream<BleCharacteristicValue>> subscribeToCharacteristic(
    BleCharacteristic characteristic,
  ) async {
    final Stream<BleCharacteristicValue> stream =
        BleMethodChannelRouter.forChannel(channel)
            .callsNamed('onCharacteristicChanged')
            .where(
              (MethodCall call) => _matchesCharacteristic(call, characteristic),
            )
            .map(
              (MethodCall call) => BleCharacteristicValue.fromMap(
                call.arguments as Map<Object?, Object?>,
              ),
            );

    // Trigger the subscription to the characteristic on the platform side.
    try {
      await channel.invokeMethod('subscribeToCharacteristic', {
        'address': characteristic.address,
        'characteristicUuid': characteristic.uuid,
      });
    } on PlatformException catch (e) {
      // Handle different error types accordingly.
      if (e.message?.contains('permissions') ?? false) {
        throw BluetoothPermissionException('Permission error: ${e.message}');
      } else {
        throw BluetoothSubscriptionException(
          'Failed to subscribe to BLE characteristic: ${e.message}',
        );
      }
    }

    return stream;
  }

  /// Unsubscribes from a Bluetooth characteristic.
  ///
  /// This method stops listening for updates for a given characteristic on a specified device.
  @override
  Future<void> unsubscribeFromCharacteristic(
    BleCharacteristic characteristic,
  ) async {
    try {
      await channel.invokeMethod('unsubscribeFromCharacteristic', {
        'address': characteristic.address,
        'characteristicUuid': characteristic.uuid,
      });
    } on PlatformException catch (e) {
      // Handle different error types accordingly.
      if (e.message?.contains('permissions') ?? false) {
        throw BluetoothPermissionException('Permission error: ${e.message}');
      } else {
        throw BluetoothSubscriptionException(
          'Failed to unsubscribe from BLE characteristic: ${e.message}',
        );
      }
    }
  }

  /// Requests a preferred PHY for the connection to the specified device.
  ///
  /// On Android, this calls `BluetoothGatt.setPreferredPhy` (API 26+). The actual PHY applied depends on what the
  /// remote device supports. On iOS, the call succeeds silently because PHY negotiation is handled by the OS.
  @override
  Future<void> requestPreferredPhy({
    required String deviceAddress,
    required BlePhy txPhy,
    required BlePhy rxPhy,
  }) async {
    try {
      await channel.invokeMethod('requestPreferredPhy', {
        'address': deviceAddress,
        'txPhy': txPhy.identifier,
        'rxPhy': rxPhy.identifier,
      });
    } on PlatformException catch (e) {
      throw BluetoothConnectionException(
        'Failed to request preferred PHY: ${e.message}',
      );
    }
  }

  /// Requests a specific connection priority for a connected device.
  ///
  /// On Android, this calls `BluetoothGatt.requestConnectionPriority`. Use [BleConnectionPriority.high] before a large
  /// data transfer to reduce the connection interval and improve throughput. On iOS, the call succeeds silently because
  /// connection interval management is handled by the OS.
  @override
  Future<void> requestConnectionPriority({
    required String deviceAddress,
    required BleConnectionPriority priority,
  }) async {
    try {
      await channel.invokeMethod('requestConnectionPriority', {
        'address': deviceAddress,
        'priority': priority.identifier,
      });
    } on PlatformException catch (e) {
      throw BluetoothConnectionException(
        'Failed to request connection priority: ${e.message}',
      );
    }
  }

  /// Returns a snapshot of the active BLE link parameters for the connected device.
  ///
  /// The native layer caches PHY values from `onPhyRead` and connection interval values from `onConnectionUpdated`,
  /// both of which fire automatically during connection setup. This call reads from the native cache rather than
  /// triggering a BLE operation.
  ///
  /// Returns null on iOS and on Android API < 26, where the underlying callbacks are not available.
  @override
  Future<BleConnectionParameters?> readConnectionParameters({
    required String deviceAddress,
  }) async {
    try {
      final Map<dynamic, dynamic>? result =
          await channel.invokeMethod<Map<dynamic, dynamic>>(
        'readConnectionParameters',
        {'address': deviceAddress},
      );
      if (result == null) return null;
      return BleConnectionParameters.fromMap(result);
    } on PlatformException catch (e) {
      throw BluetoothConnectionException(
        'Failed to read connection parameters: ${e.message}',
      );
    }
  }

  /// Clears the Android GATT cache for the connected device by invoking the hidden `BluetoothGatt.refresh()` method via
  /// reflection on the native side.
  ///
  /// On iOS, this call returns immediately without performing any platform action because Core Bluetooth does not
  /// expose a GATT cache.
  ///
  /// Throws a [GattCacheException] if the native reflective call fails.
  @override
  Future<void> refreshGattCache({required String deviceAddress}) async {
    try {
      await channel.invokeMethod<void>(
        'refreshGattCache',
        {'address': deviceAddress},
      );
    } on PlatformException catch (e) {
      throw GattCacheException(
        'Failed to refresh GATT cache for $deviceAddress: ${e.message}',
      );
    }
  }
}
