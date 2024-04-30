import 'package:flutter/services.dart';
import 'package:flutter_splendid_ble/peripheral/peripheral_platform_interface.dart';

import '../shared/ble_common_utilities.dart';
import '../shared/models/bluetooth_permission_status.dart';
import '../shared/models/bluetooth_status.dart';
import 'models/ble_server.dart';
import 'models/ble_server_configuration.dart';

/// An implementation of [PeripheralPlatformInterface] that uses method channels.
class PeripheralMethodChannel extends PeripheralPlatformInterface {
  /// The method channel used to interact with the native platform.
  static final MethodChannel channel = const MethodChannel('flutter_splendid_ble_peripheral');

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
    return BleCommonUtilities.checkBluetoothAdapterStatus(channel);
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
    return BleCommonUtilities.emitCurrentBluetoothStatus(channel);
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
    return BleCommonUtilities.requestBluetoothPermissions(channel);
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
    return BleCommonUtilities.emitCurrentPermissionStatus(channel);
  }

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
  Future<BleServer> createPeripheralServer(BleServerConfiguration configuration) async {
    try {
      await channel.invokeMethod('createPeripheralServer', configuration.toMap());

      return BleServer(
        configuration: configuration,
      );
    } catch (e) {
      // Handle or rethrow the error as appropriate
      throw Exception('Failed to set up peripheral server: $e');
    }
  }
}
