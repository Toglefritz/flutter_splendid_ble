import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_splendid_ble/peripheral/peripheral_platform_interface.dart';

import 'models/ble_server.dart';
import 'models/ble_server_configuration.dart';

/// An implementation of [PeripheralPlatformInterface] that uses method channels.
class PeripheralMethodChannel extends PeripheralPlatformInterface {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final MethodChannel channel = const MethodChannel('flutter_splendid_ble_peripheral');

  /// Sets up a BLE peripheral server with the specified configuration.
  ///
  /// This function initiates the creation of a BLE server on the native platform using the configuration provided.
  /// It communicates with the native side through the [channel] method channel and sends the configuration map as
  /// parameters.
  ///
  /// Upon successful execution of the native method call, this function instantiates and returns a [BleServer] object.
  /// This object represents the BLE server in the Dart context, allowing further management like starting/stopping
  /// advertising and managing connected devices.
  ///
  /// The [configuration] parameter accepts a [BleServerConfiguration] instance which should include all necessary
  /// settings required to initialize the BLE server and configure it correctly for the needs of the Flutter
  /// application. This might include service UUIDs, characteristic definitions, advertising parameters, etc.
  ///
  /// If an error occurs while setting up the BLE server on the platform side, an exception is thrown.
  Future<BleServer> setupPeripheralServer(BleServerConfiguration configuration) async {
    try {
      await channel.invokeMethod('setupPeripheral', configuration.toMap());

      return BleServer(
        configuration: configuration,
      );
    } catch (e) {
      // Handle or rethrow the error as appropriate
      throw Exception('Failed to set up peripheral server: $e');
    }
  }
}
