import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_splendid_ble/flutter_splendid_ble.dart';

import '../../services/connection_test_service.dart';
import '../../services/pairing_test_service.dart';
import '../../services/read_write_test_service.dart';
import '../../services/scanning_test_service.dart';
import '../../services/service_discovery_test_service.dart';
import 'ble_test_route.dart';
import 'ble_test_view.dart';

/// Controller for the BLE testing screen.
///
/// This controller manages the state and logic for running BLE tests against the ESP32 test device. It coordinates
/// different test services and handles UI updates for the terminal-style test interface.
class BleTestController extends State<BleTestRoute> {
  /// The BLE central instance used for all Bluetooth operations.
  late final SplendidBleCentral _ble;

  /// Service for performing scanning tests.
  late final ScanningTestService _scanningTestService;

  /// Service for performing connection tests.
  late final ConnectionTestService _connectionTestService;

  /// Service for performing service discovery tests.
  late final ServiceDiscoveryTestService _serviceDiscoveryTestService;

  /// Service for performing read/write tests.
  late final ReadWriteTestService _readWriteTestService;

  /// Service for performing pairing tests.
  late final PairingTestService _pairingTestService;

  /// List of test output lines displayed in the terminal interface.
  final List<String> _outputLines = <String>[];

  /// Gets the current test output lines.
  List<String> get outputLines => List<String>.unmodifiable(_outputLines);

  /// Determines if tests are currently running.
  bool _isRunning = false;

  /// Gets whether tests are currently running.
  bool get isRunning => _isRunning;

  /// Scroll controller for the output list.
  ///
  /// The primary purpose of this scroll controller is to automatically scroll the view as new output lines are added
  /// by the test services.
  final ScrollController _scrollController = ScrollController();

  /// Gets the scroll controller for the output list.
  ScrollController get scrollController => _scrollController;

  @override
  void initState() {
    super.initState();

    // Initialize the Splendid BLE plugin
    _ble = SplendidBleCentral();

    // Initialize each of the test services
    _scanningTestService = ScanningTestService(_ble, _addOutputLine);
    _connectionTestService = ConnectionTestService(_ble, _addOutputLine);
    _serviceDiscoveryTestService =
        ServiceDiscoveryTestService(_ble, _addOutputLine);
    _readWriteTestService = ReadWriteTestService(_ble, _addOutputLine);
    _pairingTestService = PairingTestService(_ble, _addOutputLine);

    // Add some initial output lines for the start of the test
    _addOutputLine('Flutter Splendid BLE Test Console');
    _addOutputLine('Ready to run BLE tests...');
    _addOutputLine('');
  }

  /// Adds a new line to the test output.
  ///
  /// This method is used to add new output lines that will appear in the view. When new lines are added, the view
  /// is scrolled to the bottom.
  void _addOutputLine(String line) {
    // Add the new output line
    setState(() {
      _outputLines.add(line);
    });

    // Scroll the view
    _scrollToBottom();
  }

  /// Scrolls to the bottom of the output list.
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        Future<void>.delayed(const Duration(milliseconds: 50), () {
          if (_scrollController.hasClients) {
            unawaited(
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
              ),
            );
          }
        });
      }
    });
  }

  /// Starts the BLE test suite.
  Future<void> startTests() async {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
      _outputLines.clear();
    });

    _addOutputLine('Starting BLE test suite...');
    _addOutputLine('');

    await _runTests();
  }

  /// Runs all BLE tests in sequence.
  Future<void> _runTests() async {
    try {
      // Check Bluetooth status first
      await _checkBluetoothStatus();

      // Track test results so a summary can be provided at the end
      final List<String> testResults = <String>[];

      // Run scanning tests
      final bool scanningPassed = await _scanningTestService.runAllTests();
      testResults.add('Scanning: ${scanningPassed ? 'PASSED' : 'FAILED'}');

      // Run connection tests
      final bool connectionPassed = await _connectionTestService.runAllTests();
      testResults.add('Connection: ${connectionPassed ? 'PASSED' : 'FAILED'}');

      // Run service discovery tests if we have a connected device
      final String? deviceAddress = _connectionTestService.testDeviceAddress;
      if (deviceAddress != null) {
        final bool discoveryPassed =
            await _serviceDiscoveryTestService.runAllTests(deviceAddress);
        testResults
            .add('Service Discovery: ${discoveryPassed ? 'PASSED' : 'FAILED'}');

        // Run pairing tests
        final bool pairingPassed =
            await _pairingTestService.runAllTests(deviceAddress);
        testResults.add('Pairing: ${pairingPassed ? 'PASSED' : 'FAILED'}');

        // Run read/write tests
        final bool readWritePassed =
            await _readWriteTestService.runAllTests(deviceAddress);
        testResults.add('Read/Write: ${readWritePassed ? 'PASSED' : 'FAILED'}');

        // Run final disconnect test
        final bool finalDisconnectPassed =
            await _testFinalDisconnect(deviceAddress);
        testResults.add(
            'Final Disconnect: ${finalDisconnectPassed ? 'PASSED' : 'FAILED'}');
      }
      // No device was connected
      else {
        _addOutputLine('');
        _addOutputLine(
          '⚠ SKIP: Service discovery tests skipped - no device address available',
        );
        _addOutputLine(
          '⚠ SKIP: Pairing tests skipped - no device address available',
        );
        _addOutputLine(
          '⚠ SKIP: Read/write tests skipped - no device address available',
        );
        testResults
          ..add('Service Discovery: SKIPPED')
          ..add('Pairing: SKIPPED')
          ..add('Read/Write: SKIPPED')
          ..add('Final Disconnect: SKIPPED');
      }

      // Display a summary of all test sections
      _addOutputLine('');
      _addOutputLine('═══════════════════════════════════════');
      _addOutputLine('TEST SUITE SUMMARY');
      _addOutputLine('═══════════════════════════════════════');

      final int passedCount = testResults
          .where((String result) => result.contains('PASSED'))
          .length;
      final int failedCount = testResults
          .where((String result) => result.contains('FAILED'))
          .length;
      final int skippedCount = testResults
          .where((String result) => result.contains('SKIPPED'))
          .length;

      for (final String result in testResults) {
        if (result.contains('PASSED')) {
          _addOutputLine('✓ $result');
        } else if (result.contains('FAILED')) {
          _addOutputLine('✗ $result');
        } else {
          _addOutputLine('⚠ $result');
        }
      }

      _addOutputLine('');
      _addOutputLine(
          'Results: $passedCount passed, $failedCount failed, $skippedCount skipped');

      final bool overallSuccess = failedCount == 0;
      if (overallSuccess) {
        _addOutputLine('✓ OVERALL: TEST SUITE PASSED');
      } else {
        _addOutputLine('✗ OVERALL: TEST SUITE FAILED');
      }
      _addOutputLine('═══════════════════════════════════════');
    } catch (e) {
      _addOutputLine('ERROR: Test suite failed - $e');
      _addOutputLine('');
      _addOutputLine('═══════════════════════════════════════');
      _addOutputLine('✗ OVERALL: TEST SUITE FAILED (Exception)');
      _addOutputLine('═══════════════════════════════════════');
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  /// Checks Bluetooth permissions and adapter status.
  Future<void> _checkBluetoothStatus() async {
    _addOutputLine('Checking Bluetooth permissions...');

    // Use EXACTLY the same pattern as HomeController
    final Stream<BluetoothPermissionStatus> bluetoothPermissionsStream =
        await _ble.emitCurrentPermissionStatus();

    // Set up the listener exactly like HomeController does
    late StreamSubscription<BluetoothPermissionStatus> permissionSubscription;
    final Completer<void> permissionCompleter = Completer<void>();

    permissionSubscription =
        bluetoothPermissionsStream.listen((BluetoothPermissionStatus status) {
      _addOutputLine('Permission status update: ${status.name}');

      // Handle exactly like HomeController does
      if (status != BluetoothPermissionStatus.granted) {
        _addOutputLine('Bluetooth permissions denied or are unknown.');
        if (!permissionCompleter.isCompleted) {
          permissionCompleter.completeError(Exception(
              'Bluetooth permissions must be granted (got: ${status.name})'));
        }
      } else {
        _addOutputLine('✓ Bluetooth permissions granted.');
        if (!permissionCompleter.isCompleted) {
          permissionCompleter.complete();
        }
      }
    });

    // Request permissions exactly like HomeController does
    await _ble.requestBluetoothPermissions();

    // Wait for permissions to be granted (or fail)
    try {
      await permissionCompleter.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Permission request timed out'),
      );
    } finally {
      await permissionSubscription.cancel();
    }

    _addOutputLine('Checking Bluetooth adapter status...');

    // Use EXACTLY the same adapter status pattern as HomeController
    final Stream<BluetoothStatus> bluetoothStatusStream =
        await _ble.emitCurrentBluetoothStatus();

    late StreamSubscription<BluetoothStatus> statusSubscription;
    final Completer<BluetoothStatus> statusCompleter =
        Completer<BluetoothStatus>();

    statusSubscription = bluetoothStatusStream.listen((BluetoothStatus status) {
      _addOutputLine('Adapter status update: ${status.name}');
      if (!statusCompleter.isCompleted) {
        statusCompleter.complete(status);
      }
    });

    // Wait for the first adapter status
    final BluetoothStatus status = await statusCompleter.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () => BluetoothStatus.notAvailable,
    );

    await statusSubscription.cancel();

    if (status != BluetoothStatus.enabled) {
      throw Exception(
          'Bluetooth must be enabled to run tests (got: ${status.name})');
    }

    _addOutputLine('✓ Bluetooth ready');
    _addOutputLine('');
  }

  /// Final test: Disconnect from test device and confirm disconnection.
  Future<bool> _testFinalDisconnect(String deviceAddress) async {
    _addOutputLine('');
    _addOutputLine('FINAL TEST: Disconnect from test device');
    _addOutputLine('Disconnecting from device at $deviceAddress...');

    bool disconnectionSuccessful = false;

    try {
      // Monitor connection state changes
      final Stream<BleConnectionState> connectionStream = await _ble.connect(
        deviceAddress: deviceAddress,
      );

      final Completer<BleConnectionState> disconnectionCompleter =
          Completer<BleConnectionState>();
      late StreamSubscription<BleConnectionState> connectionSubscription;

      connectionSubscription = connectionStream.listen(
        (BleConnectionState state) {
          _addOutputLine('  Connection state: ${state.identifier}');

          if (state == BleConnectionState.disconnected &&
              !disconnectionCompleter.isCompleted) {
            disconnectionSuccessful = true;
            disconnectionCompleter.complete(state);
          }
        },
        onError: (Object error) {
          _addOutputLine('  Connection monitoring error: $error');
          if (!disconnectionCompleter.isCompleted) {
            disconnectionCompleter.completeError(error);
          }
        },
      );

      // Initiate disconnection
      await _ble.disconnect(deviceAddress);
      _addOutputLine('  Disconnect command sent');

      // Wait for disconnection confirmation
      try {
        await disconnectionCompleter.future.timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            _addOutputLine('  Disconnection timed out');
            return BleConnectionState.unknown;
          },
        );
      } finally {
        await connectionSubscription.cancel();
      }
    } catch (error) {
      _addOutputLine('  Disconnection failed with error: $error');
    }

    if (disconnectionSuccessful) {
      _addOutputLine('✓ PASS: Successfully disconnected from test device');
    } else {
      _addOutputLine('✗ FAIL: Failed to disconnect from test device');
    }
    _addOutputLine('');

    return disconnectionSuccessful;
  }

  @override
  Widget build(BuildContext context) => BleTestView(this);

  @override
  void dispose() {
    _scrollController.dispose();
    unawaited(_scanningTestService.dispose());
    unawaited(_connectionTestService.dispose());
    unawaited(_serviceDiscoveryTestService.dispose());
    unawaited(_readWriteTestService.dispose());
    unawaited(_pairingTestService.dispose());

    super.dispose();
  }
}
