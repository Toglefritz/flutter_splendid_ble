import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_splendid_ble/peripheral/peripheral_method_channel.dart';

import '../../shared/models/ble_device.dart';
import 'ble_server_configuration.dart';

/// Represents a Bluetooth Low Energy (BLE) server for a Flutter application.
///
/// This class encapsulates the functionality needed for a Flutter app to act as a BLE peripheral device. It allows
/// the app to advertise BLE services, handle connections, and manage data exchanges with connected devices.
///
/// **Usage**:
/// - Construct a `BleServer` with the desired configuration.
/// - Use `startAdvertising()` to begin advertising the BLE services.
/// - Listen for incoming connections and disconnections via `onDeviceConnected` and `onDeviceDisconnected` streams.
/// - Implement `onReadRequest` and `onWriteRequest` to handle read and write requests from connected devices.
/// - Use `notifyConnectedDevices` to send data to connected devices.
///
/// This class acts as a high-level interface for the underlying platform-specific BLE peripheral capabilities. It
/// abstracts the complexities involved in managing BLE operations, providing a streamlined way for Flutter apps to
/// interact with BLE technology.
class BleServer {
  /// The method channel used for communicating with the platform side.
  MethodChannel _channel = PeripheralMethodChannel.channel;

  /// The server's configuration details which contains information such as the name of the BLE peripheral device,
  /// information about services offered by the peripheral, and BLE characteristic information.
  final BleServerConfiguration configuration;

  BleServer({
    required this.configuration,
  });

  /// Starts advertising this device as a BLE peripheral.
  ///
  /// This method configures the device to advertise itself as a BLE peripheral with the specified configuration.
  /// The configuration includes the local name of the device, the UUIDs of the services it offers, and whether to
  /// enforce the maximum advertisement data size.
  ///
  /// If [enforceMaxAdvertisementDataSize] is provided, it will be used to determine whether to enforce the maximum
  /// advertisement data size. If it is not provided, the default value of 'false' will be used.
  ///
  /// Throws an exception if the advertising process cannot be started.
  ///
  /// [enforceMaxAdvertisementDataSize]: A boolean value indicating whether to enforce the maximum advertisement data
  /// size.
  Future<void> startAdvertising() async {
    // Construct a map providing advertisement configuration details to the platform side
    final Map<String, dynamic> configMap = {
      'localName': this.configuration.localName,
      'serviceUuids': this.configuration.serviceUuids ?? [],
    };

    // Invoke a method channel to start advertising with the given configuration.
    try {
      await _channel.invokeMethod('startAdvertising', configMap);
    } catch (e) {
      rethrow;
    }
  }

  /// Stops advertising this device as a BLE peripheral.
  ///
  /// If the device is currently advertising as a BLE peripheral, this function will stop the advertising process. If
  /// the device is not currently advertising, or if the BLE server has not finished initializing, this function will
  /// do nothing.
  Future<void> stopAdvertising() async {
    // Invoke a method channel to start advertising with the given configuration.
    try {
      await _channel.invokeMethod('stopAdvertising');
    } catch (e) {
      rethrow;
    }
  }

  /// Creates a stream that emits information about client devices connecting to the BLE server.
  ///
  /// This method sets up a [StreamController] to listen for client connection events from the platform side
  /// and emit [BleDevice] objects on the stream when a new client device connects.
  /// It uses a method channel to receive notifications from the platform side about new connections.
  /// When a connection is detected, it converts the received information into a [BleDevice] object and adds it to the
  /// stream.
  ///
  /// The stream is broadcast, allowing multiple listeners to receive connection events.
  Stream<BleDevice> emitClientConnections() {
    final StreamController<BleDevice> streamController = StreamController<BleDevice>.broadcast();

    // Listen to the platform side for client connection updates.
    _channel.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'clientConnected') {
        // Extract the connected device information from the method call arguments.
        final Map<String, dynamic> deviceMap = Map<String, dynamic>.from(call.arguments as Map);
        final BleDevice device = BleDevice.fromMap(deviceMap);

        // Add the connected device to the stream.
        streamController.add(device);
      }
    });

    return streamController.stream;
  }

  // Stream to listen for disconnections
  //Stream<BleDevice> get onDeviceDisconnected => /* Stream from method channel for disconnections */;

  // Handling read requests from connected devices
  Future<void> onReadRequest(/* parameters */) async {
    // Logic to handle read requests
  }

  // Handling write requests from connected devices
  Future<void> onWriteRequest(/* parameters */) async {
    // Logic to handle write requests
  }

  // Method to send data to connected devices
  Future<void> notifyConnectedDevices(/* parameters */) async {
    // Logic to notify or send data to connected devices
  }
}
