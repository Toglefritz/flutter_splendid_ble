import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_splendid_ble/flutter_splendid_ble.dart';
import 'package:flutter_splendid_ble/models/ble_device.dart';
import 'package:flutter_splendid_ble/models/bluetooth_permission_status.dart';
import 'package:flutter_splendid_ble/models/bluetooth_status.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

import 'home_route.dart';
import 'home_view.dart';

/// Controller for the [HomeRoute]
class HomeController extends State<HomeRoute> {
  /// A [FlutterBle] instance used for Bluetooth operations conducted by this route.
  final FlutterSplendidBle _ble = FlutterSplendidBle();

  /// Determines if Bluetooth permissions have been granted.
  ///
  /// A null value indicates that permissions have neither been granted nor denied. It is simply a mystery.
  bool? _permissionsGranted;

  bool? get permissionsGranted => _permissionsGranted;

  /// A [Stream] used to listen for changes in the status of the Bluetooth adapter on the host device and set the
  /// value of [_bluetoothStatus].
  StreamSubscription<BluetoothStatus>? _bluetoothStatusStream;

  /// A [Stream] used to listen for changes in the status of the Bluetooth permissions required for the app to operate
  /// and set the value of [_permissionsGranted].
  StreamSubscription<BluetoothPermissionStatus>? _bluetoothPermissionsStream;

  /// The status of the Bluetooth adapter on the host device.
  BluetoothStatus? _bluetoothStatus;

  BluetoothStatus? get bluetoothStatus => _bluetoothStatus;

  /// Determines if a scan is currently in progress.
  bool _scanInProgress = false;

  bool get scanInProgress => _scanInProgress;

  /// A list of [BleDevice]s discovered by the Bluetooth scan.
  List<BleDevice> discoveredDevices = [];

  /// A [StreamSubscription] for the Bluetooth scanning process.
  StreamSubscription<BleDevice>? _scanStream;

  @override
  void initState() {
    if (Platform.isAndroid) {
      _requestAndroidPermissions();
    } else if (Platform.isMacOS || Platform.isIOS) {
      _requestApplePermissions();
    }

    super.initState();
  }

  /// Requests Bluetooth and location permissions.
  ///
  /// The user will be prompted to allow the app to use various Bluetooth features of their mobile device. These
  /// permissions must be granted for the app to function since its whole deal is doing Bluetooth stuff. The app
  /// will also request location permissions, which are necessary for performing a Bluetooth scan.
  Future<void> _requestAndroidPermissions() async {
    // Request the Bluetooth Scan permission
    PermissionStatus bluetoothScanPermissionStatus = await Permission.bluetoothScan.request();
    PermissionStatus bluetoothConnectPermissionStatus = await Permission.bluetoothConnect.request();
    PermissionStatus locationPermissionStatus = await Permission.location.request();

    // Check if permission has been granted or not
    if (bluetoothScanPermissionStatus.isDenied || bluetoothConnectPermissionStatus.isDenied) {
      // If permission is denied, show a SnackBar with a relevant message
      debugPrint('Bluetooth permissions denied.');

      setState(() {
        _permissionsGranted = false;
      });
    }
    // If permission is denied, show a SnackBar with a relevant message
    else if (locationPermissionStatus.isDenied) {
      debugPrint('Location permissions denied.');

      setState(() {
        _permissionsGranted = false;
      });
    }
    // If permissions were granted, we go on our merry way
    else {
      debugPrint('Bluetooth and location permissions granted.');

      setState(() {
        _permissionsGranted = true;
      });

      // Check the adapter status
      _checkAdapterStatus();
    }
  }

  /// Requests Bluetooth permissions.
  ///
  /// The user will be prompted to allow the app to use various Bluetooth features of their mobile device. These
  /// permissions must be granted for the app to function since its whole deal is doing Bluetooth stuff.
  Future<void> _requestApplePermissions() async {
    // Request the Bluetooth Scan permission
    _bluetoothPermissionsStream = _ble.emitCurrentPermissionStatus().listen((event) {
      // Check if permission has been granted or not
      if (event != BluetoothPermissionStatus.granted) {
        // If permission is denied, show a SnackBar with a relevant message
        debugPrint('Bluetooth permissions denied or are unknown.');

        setState(() {
          _permissionsGranted = false;
        });
      }
      // If permissions were granted, we go on our merry way
      else {
        debugPrint('Bluetooth and location permissions granted.');

        setState(() {
          _permissionsGranted = true;
        });

        // Check the adapter status
        _checkAdapterStatus();
      }
    });
  }

  /// Checks the status of the Bluetooth adapter on the host device (assuming one is present).
  ///
  /// Before the Bluetooth scan can be started or any other Bluetooth operations can be performed, the Bluetooth
  /// capabilities of the host device must be available. This method establishes a listener on the current state
  /// of the host device's Bluetooth adapter, which is represented by the enum, [BluetoothState].
  void _checkAdapterStatus() async {
    try {
      _bluetoothStatusStream = _ble.emitCurrentBluetoothStatus().listen((status) {
        setState(() {
          _bluetoothStatus = status;
        });
      });
    } catch (e) {
      debugPrint('Unable to get Bluetooth status with exception, $e');

      setState(() {
        _bluetoothStatus = BluetoothStatus.notAvailable;
      });
    }
  }

  /// Starts a Bluetooth scan with a time limit of four seconds, after which the scan is stopped to
  /// save on battery life.
  void startScan() {
    setState(() {
      discoveredDevices.clear();
      _scanInProgress = true;
    });

    _scanStream = _ble.startScan().listen(
      (device) => _onDeviceDetected(device),
      onError: (error) {
        // Handle the error here
        _handleScanError(error);
        return;
      },
    );

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        stopScan();
      }
    });
  }

  /// Handles newly discovered devices by adding them to the [discoveredDevices] list and triggering a rebuild
  /// of the [HomeView].
  void _onDeviceDetected(BleDevice device) {
    setState(() {
      if (discoveredDevices.where((existingDevice) => device.address == existingDevice.address).isEmpty) {
        discoveredDevices.add(device);
      }
    });
  }

  /// Handles errors emitted by the [_scanStream] from attempting to start a Bluetooth scan.
  void _handleScanError(error) {
    // Create the SnackBar with the error message
    final snackBar = SnackBar(
      content: Text('Error scanning for Bluetooth devices: $error'),
      action: SnackBarAction(
        label: 'Dismiss',
        onPressed: () {
          // If you need to do anything when the user dismisses the SnackBar
        },
      ),
    );

    // Show the SnackBar using the ScaffoldMessenger
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Assuming there is a scan ongoing, this function can be used to stop the scan. If this is called while a scan
  /// is not happening, nothing will happen.
  void stopScan() {
    _ble.stopScan();
    _scanStream?.cancel();

    setState(() {
      _scanInProgress = false;
    });
  }

  @override
  Widget build(BuildContext context) => HomeView(this);

  @override
  void dispose() {
    stopScan();
    _bluetoothStatusStream?.cancel();
    _bluetoothPermissionsStream?.cancel();

    super.dispose();
  }
}
