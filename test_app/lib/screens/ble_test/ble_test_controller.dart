import 'package:flutter/material.dart';

import 'ble_test_route.dart';
import 'ble_test_view.dart';

/// Controller for the BLE testing screen.
///
/// This controller manages the state and logic for running BLE tests against
/// the ESP32 test device. It handles test execution, result collection, and
/// UI updates for the terminal-style test interface.
class BleTestController extends State<BleTestRoute> {
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
    _addOutputLine('Flutter Splendid BLE Test Console');
    _addOutputLine('Ready to run BLE tests...');
    _addOutputLine('');
  }

  /// Adds a new line to the test output.
  void _addOutputLine(String line) {
    setState(() {
      _outputLines.add(line);
    });
  }

  /// Starts the BLE test suite.
  void startTests() {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
      _outputLines.clear();
    });

    _addOutputLine('Starting BLE test suite...');
    _addOutputLine('');

    // Placeholder for actual test implementation
    _addOutputLine('[PLACEHOLDER] Tests will be implemented here');
  }

  @override
  Widget build(BuildContext context) => BleTestView(this);
}
