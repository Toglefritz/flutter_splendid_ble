import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_splendid_ble/central/splendid_ble_central.dart';
import 'package:flutter_splendid_ble/shared/models/bluetooth_permission_status.dart';
import 'package:flutter_splendid_ble/shared/models/bluetooth_status.dart';
import 'package:permission_handler/permission_handler.dart';

import '../central/scan/scan_route.dart';
import '../central/scan_configuration/scan_configuration_route.dart';
import 'home_route.dart';
import 'home_view.dart';

/// A controller for the [HomeRoute] that manages the state and owns all business logic.
class HomeController extends State<HomeRoute> {
  /// A [SplendidBleCentral] instance used for Bluetooth operations conducted by this route.
  final SplendidBleCentral _ble = SplendidBleCentral();

  /// Determines if Bluetooth permissions have been granted.
  ///
  /// A null value indicates that permissions have neither been granted nor denied. It is simply a mystery.
  bool? _permissionsGranted;

  /// Determines if Bluetooth permissions have been granted.
  bool? get permissionsGranted => _permissionsGranted;

  /// A [Stream] used to listen for changes in the status of the Bluetooth adapter on the host device and set the
  /// value of [_bluetoothStatus].
  StreamSubscription<BluetoothStatus>? _bluetoothStatusStream;

  /// A [Stream] used to listen for changes in the status of the Bluetooth permissions required for the app to operate
  /// and set the value of [_permissionsGranted].
  StreamSubscription<BluetoothPermissionStatus>? _bluetoothPermissionsStream;

  /// The status of the Bluetooth adapter on the host device.
  BluetoothStatus? _bluetoothStatus;

  /// The status of the Bluetooth adapter on the host device.
  BluetoothStatus? get bluetoothStatus => _bluetoothStatus;

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
    final PermissionStatus bluetoothScanPermissionStatus =
        await Permission.bluetoothScan.request();
    final PermissionStatus bluetoothConnectPermissionStatus =
        await Permission.bluetoothConnect.request();
    final PermissionStatus locationPermissionStatus =
        await Permission.location.request();

    // Check if permission has been granted or not
    if (bluetoothScanPermissionStatus.isDenied ||
        bluetoothConnectPermissionStatus.isDenied) {
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
      await _checkAdapterStatus();
    }
  }

  /// Requests Bluetooth permissions.
  ///
  /// The user will be prompted to allow the app to use various Bluetooth features of their mobile device. These
  /// permissions must be granted for the app to function since its whole deal is doing Bluetooth stuff.
  Future<void> _requestApplePermissions() async {
    // Request the Bluetooth Scan permission
    _bluetoothPermissionsStream =
        _ble.emitCurrentPermissionStatus().listen((event) {
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
  /// of the host device's Bluetooth adapter, which is represented by the enum, [BluetoothStatus].
  Future<void> _checkAdapterStatus() async {
    try {
      _bluetoothStatusStream =
          _ble.emitCurrentBluetoothStatus().listen((status) {
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

  /// Handles taps on the "start scan" button.
  ///
  /// If Bluetooth scanning permissions have been granted or if the app is running on an iOS device (in which case
  /// the boolean indicating if permissions have been granted is true by default), navigate to the [ScanRoute].
  /// Otherwise, show a [SnackBar] to indicate that permissions have not been granted yet.
  void onStartScanTap() {
    if ((_permissionsGranted ?? false) &&
        _bluetoothStatus == BluetoothStatus.enabled) {
      Navigator.pushReplacement<void, void>(
        context,
        MaterialPageRoute<void>(
          builder: (BuildContext context) => const ScanRoute(),
        ),
      );
    } else if (_permissionsGranted == false) {
      _showPermissionsErrorSnackBar();
    }
  }

  /// Handles long presses on the "start scan" button.
  ///
  /// Long-pressing on the start scan button navigates directly to the [ScanConfigurationRoute], allowing the scan
  /// to be configured before it starts
  void onStartScanLongPress() {
    if ((_permissionsGranted ?? false) &&
        _bluetoothStatus == BluetoothStatus.enabled) {
      Navigator.pushReplacement<void, void>(
        context,
        MaterialPageRoute<void>(
          builder: (BuildContext context) => const ScanConfigurationRoute(),
        ),
      );
    } else if (_permissionsGranted == false) {
      _showPermissionsErrorSnackBar();
    }
  }

  /// Shows a [SnackBar] explaining that Bluetooth permissions have not been granted.
  void _showPermissionsErrorSnackBar() {
    if (!mounted) return;
    final SnackBar snackBar = SnackBar(
      content: Text(AppLocalizations.of(context)!.permissionsError),
      duration: const Duration(seconds: 8),
      behavior: SnackBarBehavior.floating,
    );

    // Find the ScaffoldMessenger in the widget tree
    // and use it to show a SnackBar.
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) => HomeView(this);

  @override
  void dispose() {
    // It is important to close the streams when they are no longer needed
    _bluetoothStatusStream?.cancel();
    _bluetoothPermissionsStream?.cancel();

    super.dispose();
  }
}
