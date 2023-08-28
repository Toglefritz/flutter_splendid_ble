import 'package:flutter/material.dart';
import 'package:flutter_ble/flutter_ble.dart';
import 'package:flutter_ble/models/ble_connection_state.dart';
import 'package:flutter_ble_example/screens/start_scan/start_scan_route.dart';

import 'device_details_route.dart';
import 'device_details_view.dart';

/// A controller for the [DeviceDetailsRoute] that manages the state and owns all business logic.
class DeviceDetailsController extends State<DeviceDetailsRoute> {
  /// A [FlutterBle] instance used for Bluetooth operations conducted by this route.
  final FlutterBle _ble = FlutterBle();

  /// The current connection state between the host mobile device and the [BleDevice] provided to this route.
  BleConnectionState _currentConnectionState = BleConnectionState.unknown;

  BleConnectionState get currentConnectionState => _currentConnectionState;

  /// A utility for checking if the device is connected.
  bool get isConnected => currentConnectionState == BleConnectionState.connected;

  /// Determine if a connection attempt is currently in progress.
  bool connecting = false;

  @override
  void initState() {
    _getCurrentConnectionState();

    super.initState();
  }

  /// Checks the current connection state of the [BleDevice] provided to this route.
  Future<void> _getCurrentConnectionState() async {
    BleConnectionState? state;
    try {
      state = await _ble.getCurrentConnectionState(widget.device.address);
    } catch (e) {
      debugPrint('Unable to get current connection state with exception, $e');
    }

    setState(() {
      _currentConnectionState = state ?? BleConnectionState.unknown;
    });
  }

  /// Handles taps on the [AppBar] close button.
  Future<void> onClose() async {
    await _ble.disconnect(widget.device.address);

    if (!mounted) return;
    Navigator.pushReplacement<void, void>(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const StartScanRoute(),
      ),
    );
  }

  /// Handles taps on the "Connect" button, which starts the process of establishing a connection with the
  /// provided [BleDevice].
  void onConnectTap() {
    setState(() {
      connecting = true;
    });

    try {
      _ble.connect(widget.device.address).listen((state) => onConnectionStateUpdate(state));
    } catch (e) {
      debugPrint('Failed to connect to device, ${widget.device.address}, with exception, $e');
    }
  }

  /// Callback for changes in the connection state between the host mobile device and the [BleDevice].
  void onConnectionStateUpdate(BleConnectionState state) {
    debugPrint('Received connection state update, ${state.name}');

    setState(() {
      _currentConnectionState = state;

      // Once the device is connected, it is no longer connecting, you know?
      setState(() {
        connecting = false;
      });

      // TODO when connected do something else in the UI right about here
    });
  }

  @override
  Widget build(BuildContext context) => DeviceDetailsView(this);
}
