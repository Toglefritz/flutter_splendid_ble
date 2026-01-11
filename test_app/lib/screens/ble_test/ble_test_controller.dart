import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_splendid_ble/flutter_splendid_ble.dart';

import '../../services/scanning_test_service.dart';
import 'ble_test_route.dart';
import 'ble_test_view.dart';

/// Controller for the BLE testing screen.
///
/// This controller manages the state and logic for running BLE tests against
/// the ESP32 test device. It coordinates different test services and handles
/// UI updates for the terminal-style test interface.
class BleTestController extends State<BleTestRoute> {
  /// The BLE central instance used for all Bluetooth operations.
  late final SplendidBleCentral _ble;

  /// Service for performing scanning tests.
  late final ScanningTestService _scanningTestService;

  /// List of test output lines displayed in the terminal interface.
  final List<String> _outputLines = <String>[];

  /// Whether tests are currently running.
  bool _isRunning = false;

  /// Gets the current test output lines.
  List<String> get outputLines => List<String>.unmodifiable(_outputLines);

  /// Gets whether tests are currently running.
  bool get isRunning => _isRunning;

  @override
  void initState() {
    super.initState();
    _ble = SplendidBleCentral();
    _scanningTestService = ScanningTestService(_ble, _addOutputLine);
    _addOutputLine('Flutter Splendid BLE Test Console');
    _addOutputLine('Ready to run BLE scanning tests...');
    _addOutputLine('');
  }

  /// Adds a new line to the test output.
  void _addOutputLine(String line) {
    setState(() {
      _outputLines.add(line);
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

      // Run scanning tests
      await _scanningTestService.runAllTests();

      _addOutputLine('');
      _addOutputLine('All tests completed!');
    } catch (e) {
      _addOutputLine('ERROR: Test suite failed - $e');
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  /// Checks Bluetooth adapter status and permissions.
  Future<void> _checkBluetoothStatus() async {
    _addOutputLine('Checking Bluetooth status...');

    final BluetoothStatus status = await _ble.checkBluetoothAdapterStatus();
    _addOutputLine('Bluetooth status: ${status.name}');

    if (status != BluetoothStatus.enabled) {
      throw Exception('Bluetooth must be enabled to run tests');
    }

    final BluetoothPermissionStatus permissions = await _ble.requestBluetoothPermissions();
    _addOutputLine('Permissions: ${permissions.name}');

    if (permissions != BluetoothPermissionStatus.granted) {
      throw Exception('Bluetooth permissions must be granted');
    }

    _addOutputLine('✓ Bluetooth ready');
    _addOutputLine('');
  }

  @override
  Widget build(BuildContext context) => BleTestView(this);

  @override
  void dispose() {
    unawaited(_scanningTestService.dispose());
    super.dispose();
  }
}
