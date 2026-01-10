import 'dart:async';
import 'package:flutter/services.dart';

import 'models/bluetooth_permission_status.dart';
import 'models/bluetooth_status.dart';

/// This class provides utility methods for checking the status of the Bluetooth adapter and requesting Bluetooth
/// permissions.
class BleCommonUtilities {
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
  static Future<BluetoothStatus> checkBluetoothAdapterStatus(
    MethodChannel channel,
  ) async {
    final String statusString =
        await channel.invokeMethod('checkBluetoothAdapterStatus') as String;

    return BluetoothStatus.values.firstWhere(
      (e) => e.identifier == statusString,
      orElse: () => BluetoothStatus.notAvailable,
    );
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
  static Future<Stream<BluetoothStatus>> emitCurrentBluetoothStatus(
    MethodChannel channel,
  ) async {
    final StreamController<BluetoothStatus> streamController =
        StreamController<BluetoothStatus>.broadcast();

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

    // Use a microtask to ensure the stream is returned before the native method is invoked
    // This gives the caller a chance to set up their listener before the first value is emitted
    unawaited(
      Future.microtask(() async {
        await channel.invokeMethod('emitCurrentBluetoothStatus');
      }),
    );

    return streamController.stream;
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
  static Future<BluetoothPermissionStatus> requestBluetoothPermissions(
    MethodChannel channel,
  ) async {
    final String permissionStatusString =
        await channel.invokeMethod('requestBluetoothPermissions') as String;
    return BluetoothPermissionStatus.values.firstWhere(
      (status) => status.identifier == permissionStatusString,
      orElse: () => BluetoothPermissionStatus.unknown,
    );
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
  ///
  /// **Important**: The stream is a broadcast stream, but you should set up your listener immediately after calling
  /// this method to ensure you receive the initial status emission.
  static Future<Stream<BluetoothPermissionStatus>> emitCurrentPermissionStatus(
    MethodChannel channel,
  ) async {
    final StreamController<BluetoothPermissionStatus> streamController =
        StreamController<BluetoothPermissionStatus>.broadcast();

    channel.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'permissionStatusUpdated') {
        final String permissionStatusString = call.arguments as String;

        // Convert the string status to its corresponding enum value
        final BluetoothPermissionStatus status =
            BluetoothPermissionStatus.values.firstWhere(
          (status) => status.identifier == permissionStatusString,
        );

        streamController.add(status);
      }
    });

    // Use a microtask to ensure the stream is returned before the native method is invoked
    // This gives the caller a chance to set up their listener before the first value is emitted
    unawaited(
      Future.microtask(() async {
        await channel.invokeMethod('emitCurrentPermissionStatus');
      }),
    );

    return streamController.stream;
  }
}
