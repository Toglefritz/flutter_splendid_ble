import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_splendid_ble/central/models/ble_characteristic.dart';
import 'package:flutter_splendid_ble/central/models/ble_connection_state.dart';
import 'package:flutter_splendid_ble/central/models/ble_service.dart';
import 'package:flutter_splendid_ble/central/models/exceptions/bluetooth_connection_exception.dart';
import 'package:flutter_splendid_ble/central/splendid_ble_central.dart';
import 'package:flutter_splendid_ble/shared/models/ble_device.dart';

import '../../home/home_route.dart';
import '../characteristic_interaction/characteristic_interaction_route.dart';
import 'device_details_route.dart';
import 'device_details_view.dart';

/// A controller for the [DeviceDetailsRoute] that manages the state and owns all business logic.
class DeviceDetailsController extends State<DeviceDetailsRoute> {
  /// A [SplendidBleCentral] instance used for Bluetooth operations conducted by this route.
  late SplendidBleCentral _ble;

  /// A [StreamSubscription] for the connection state between the Flutter app and the Bluetooth peripheral.
  StreamSubscription<BleConnectionState>? _connectionStateStream;

  /// The current connection state between the host mobile device and the [BleDevice] provided to this route.
  BleConnectionState _currentConnectionState = BleConnectionState.unknown;

  /// The current connection state between the host mobile device and the [BleDevice] provided to this route.
  BleConnectionState get currentConnectionState => _currentConnectionState;

  /// A utility for checking if the device is connected.
  bool get isConnected => currentConnectionState == BleConnectionState.connected;

  /// Determines if a connection attempt is currently in progress.
  bool _connecting = false;

  /// Determines if a connection attempt is currently in progress.
  bool get connecting => _connecting;

  /// Determines if the service and characteristic discovery process is currently in progress.
  bool _discoveringServices = false;

  /// Determines if the service and characteristic discovery process is currently in progress.
  bool get discoveringServices => _discoveringServices;

  /// A [StreamController] used to listen for updates during the BLE service discovery process.
  StreamSubscription<List<BleService>>? _servicesDiscoveredStream;

  /// A list of Bluetooth service information that includes a list of characteristics under each service.
  final List<BleService> _discoveredServices = [];

  /// A list of Bluetooth service information that includes a list of characteristics under each service.
  List<BleService> get discoveredServices => _discoveredServices;

  @override
  void initState() {
    // Access the injected instance from the widget
    _ble = widget.ble;

    // Get the current connection state of the device provided to this route.
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

  /// Handles taps on the [AppBar] back button.
  ///
  /// This button navigates back to the home page but it does not disconnect the Bluetooth device. Normally doing this
  /// would not make a ton of sense, but for the purposes of this example app, it is a useful feature.
  Future<void> onBack() async {
    await Navigator.pushReplacement<void, void>(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const HomeRoute(),
      ),
    );
  }

  /// Handles taps on the [AppBar] close button.
  Future<void> onClose() async {
    await _ble.disconnect(widget.device.address);

    if (!mounted) return;
    await Navigator.pushReplacement<void, void>(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const HomeRoute(),
      ),
    );
  }

  /// Handles taps on the "Connect" button, which starts the process of establishing a connection with the
  /// provided [BleDevice].
  Future<void> onConnectTap() async {
    setState(() {
      _connecting = true;
    });

    try {
      final Stream<BleConnectionState> connectionStateStream = await _ble.connect(deviceAddress: widget.device.address);
      // ignore: inference_failure_on_untyped_parameter

      _connectionStateStream = connectionStateStream.listen(
        onConnectionStateUpdate,
        // ignore: inference_failure_on_untyped_parameter
        onError: (error) {
          // Handle the error here
          _handleConnectionError(error as BluetoothConnectionException);
        },
      );
    } catch (e) {
      debugPrint(
        'Failed to connect to device, ${widget.device.address}, with exception, $e',
      );
    }
  }

  /// Handles errors resulting from an attempt to connect to a peripheral.
  void _handleConnectionError(BluetoothConnectionException error) {
    // Create the SnackBar with the error message
    final SnackBar snackBar = SnackBar(
      content: Text('Error connecting to Bluetooth device: $error'),
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

  /// Handles taps on the "Discover Services" button, which starts the BLE service and characteristic discovery
  /// process.
  Future<void> onDiscoverServicesTap() async {
    setState(() {
      _discoveringServices = true;
    });

    final Stream<List<BleService>> servicesDiscoveredStream = await _ble.discoverServices(widget.device.address);

    _servicesDiscoveredStream = servicesDiscoveredStream.listen(
      _onServiceDiscovered,
    );
  }

  /// A callback used each time a new service is discovered and emitted to the [Stream].
  void _onServiceDiscovered(List<BleService> services) {
    setState(() {
      _discoveredServices.addAll(services);
    });
  }

  /// Callback for changes in the connection state between the host mobile device and the [BleDevice].
  void onConnectionStateUpdate(BleConnectionState state) {
    debugPrint('Received connection state update, ${state.name}');

    setState(() {
      _currentConnectionState = state;

      // Once the device is connected, it is no longer connecting, you know?
      setState(() {
        _connecting = false;
      });

      // TODO(Toglefritz): when connected do something else in the UI right about here
    });
  }

  /// Handles taps on a Bluetooth characteristic by navigating to the [CharacteristicInteractionRoute], allowing
  /// for values to be written to or read from the selected Bluetooth characteristic, depending upon the
  /// properties of that characteristic.
  Future<void> characteristicOnTap(BleCharacteristic characteristic) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) => CharacteristicInteractionRoute(
          device: widget.device,
          characteristic: characteristic,
        ),
      ),
    );

    setState(() {
      // No-op
    });
  }

  @override
  Widget build(BuildContext context) => DeviceDetailsView(this);

  @override
  void dispose() {
    _connectionStateStream?.cancel();
    _servicesDiscoveredStream?.cancel();

    super.dispose();
  }
}
