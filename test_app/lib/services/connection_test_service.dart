import 'dart:async';

import 'package:flutter_splendid_ble/flutter_splendid_ble.dart';

import '../config/esp32_test_constants.dart';

/// Service for performing BLE connection tests.
///
/// This service encapsulates all connection-related test logic, including
/// basic connection establishment, connection state monitoring, disconnection,
/// and connection timeout handling. It does not include pairing or bonding tests.
class ConnectionTestService {
  /// The BLE central instance used for connection operations.
  final SplendidBleCentral _ble;

  /// Callback function for adding output lines to the test display.
  final void Function(String) _addOutputLine;

  /// Subscription to the current BLE scan stream.
  StreamSubscription<BleDevice>? _scanSubscription;

  /// Subscription to the connection state stream.
  StreamSubscription<BleConnectionState>? _connectionSubscription;

  /// The address of the test device found during scanning.
  String? _testDeviceAddress;

  /// Creates a new connection test service.
  ConnectionTestService(this._ble, this._addOutputLine);

  /// Gets the address of the test device found during scanning.
  ///
  /// Returns null if no test device has been found yet.
  String? get testDeviceAddress => _testDeviceAddress;

  /// Runs all connection tests in sequence.
  ///
  /// This method performs the complete connection test suite:
  /// 1. Find test device via scanning
  /// 2. Basic connection establishment
  /// 3. Connection state monitoring
  /// 4. Graceful disconnection
  /// 5. Connection timeout test
  ///
  /// Returns true if all tests pass, false if any test fails.
  Future<bool> runAllTests() async {
    _addOutputLine('Running BLE connection tests...');
    _addOutputLine('');

    final List<bool> results = <bool>[
      await _testFindTestDevice(),
      await _testBasicConnection(),
      await _testConnectionStateMonitoring(),
      await _testGracefulDisconnection(),
      await _testConnectionTimeout(),
    ];

    final bool allPassed = results.every((bool result) => result);
    _addOutputLine('');
    _addOutputLine('Connection tests ${allPassed ? 'PASSED' : 'FAILED'}');

    return allPassed;
  }

  /// Test 1: Find test device - locate the test device for connection tests.
  Future<bool> _testFindTestDevice() async {
    _addOutputLine('TEST 1: Find test device');
    _addOutputLine('Scanning for test device...');

    bool testDeviceFound = false;
    int deviceCount = 0;

    try {
      final Stream<BleDevice> scanStream = await _ble.startScan(
        filters: <ScanFilter>[
          ScanFilter(deviceName: kTestDeviceName),
        ],
      );

      _scanSubscription = scanStream.listen(
        (BleDevice device) {
          deviceCount++;
          _addOutputLine('  Found: ${device.name ?? 'Unknown'} (${device.address})');

          if (device.name == kTestDeviceName) {
            testDeviceFound = true;
            _testDeviceAddress = device.address;
            _addOutputLine('  → Test device located! Address: ${device.address}');
          }
        },
        onError: (Object error) {
          _addOutputLine('  Scan error: $error');
        },
      );

      // Scan for 10 seconds or until test device is found
      int secondsElapsed = 0;
      while (secondsElapsed < 10 && !testDeviceFound) {
        await Future<void>.delayed(const Duration(seconds: 1));
        secondsElapsed++;
      }
    } finally {
      _ble.stopScan();
      await _scanSubscription?.cancel();
      _scanSubscription = null;
    }

    _addOutputLine('  Scan completed: $deviceCount devices found');

    if (testDeviceFound && _testDeviceAddress != null) {
      _addOutputLine('✓ PASS: Test device found and address recorded');
    } else {
      _addOutputLine('✗ FAIL: Test device not found');
    }
    _addOutputLine('');

    return testDeviceFound && _testDeviceAddress != null;
  }

  /// Test 2: Basic connection - establish connection to test device.
  Future<bool> _testBasicConnection() async {
    _addOutputLine('TEST 2: Basic connection');

    if (_testDeviceAddress == null) {
      _addOutputLine('✗ FAIL: No test device address available');
      _addOutputLine('');
      return false;
    }

    _addOutputLine('Connecting to test device at $_testDeviceAddress...');

    bool connectionSuccessful = false;
    BleConnectionState? finalState;

    try {
      final Stream<BleConnectionState> connectionStream = await _ble.connect(
        deviceAddress: _testDeviceAddress!,
      );

      final Completer<BleConnectionState> connectionCompleter = Completer<BleConnectionState>();

      _connectionSubscription = connectionStream.listen(
        (BleConnectionState state) {
          _addOutputLine('  Connection state: ${state.identifier}');

          if (state == BleConnectionState.connected) {
            connectionSuccessful = true;
            if (!connectionCompleter.isCompleted) {
              connectionCompleter.complete(state);
            }
          } else if (state == BleConnectionState.disconnected && !connectionCompleter.isCompleted) {
            connectionCompleter.complete(state);
          }
        },
        onError: (Object error) {
          _addOutputLine('  Connection error: $error');
          if (!connectionCompleter.isCompleted) {
            connectionCompleter.completeError(error);
          }
        },
      );

      // Wait for connection result with timeout
      try {
        finalState = await connectionCompleter.future.timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            _addOutputLine('  Connection attempt timed out');
            return BleConnectionState.unknown;
          },
        );
      } on TimeoutException {
        finalState = BleConnectionState.unknown;
      }
    } catch (error) {
      _addOutputLine('  Connection failed with error: $error');
      finalState = BleConnectionState.unknown;
    } finally {
      await _connectionSubscription?.cancel();
      _connectionSubscription = null;
    }

    if (connectionSuccessful && finalState == BleConnectionState.connected) {
      _addOutputLine('✓ PASS: Successfully connected to test device');
    } else {
      _addOutputLine('✗ FAIL: Failed to connect to test device (final state: ${finalState.identifier})');
    }
    _addOutputLine('');

    return connectionSuccessful;
  }

  /// Test 3: Connection state monitoring - verify connection state reporting.
  Future<bool> _testConnectionStateMonitoring() async {
    _addOutputLine('TEST 3: Connection state monitoring');

    if (_testDeviceAddress == null) {
      _addOutputLine('✗ FAIL: No test device address available');
      _addOutputLine('');
      return false;
    }

    _addOutputLine('Checking current connection state...');

    bool stateCheckSuccessful = false;

    try {
      final BleConnectionState currentState = await _ble.getCurrentConnectionState(_testDeviceAddress!);
      _addOutputLine('  Current connection state: ${currentState.identifier}');

      if (currentState == BleConnectionState.connected) {
        stateCheckSuccessful = true;
        _addOutputLine('  ✓ Device is properly connected');
      } else {
        _addOutputLine('  ✗ Device is not in connected state');
      }
    } catch (error) {
      _addOutputLine('  Error checking connection state: $error');
    }

    if (stateCheckSuccessful) {
      _addOutputLine('✓ PASS: Connection state monitoring working correctly');
    } else {
      _addOutputLine('✗ FAIL: Connection state monitoring failed');
    }
    _addOutputLine('');

    return stateCheckSuccessful;
  }

  /// Test 4: Graceful disconnection - properly disconnect from test device.
  Future<bool> _testGracefulDisconnection() async {
    _addOutputLine('TEST 4: Graceful disconnection');

    if (_testDeviceAddress == null) {
      _addOutputLine('✗ FAIL: No test device address available');
      _addOutputLine('');
      return false;
    }

    _addOutputLine('Disconnecting from test device...');

    bool disconnectionSuccessful = false;

    try {
      // Start monitoring connection state changes
      final Stream<BleConnectionState> connectionStream = await _ble.connect(
        deviceAddress: _testDeviceAddress!,
      );

      final Completer<BleConnectionState> disconnectionCompleter = Completer<BleConnectionState>();

      _connectionSubscription = connectionStream.listen(
        (BleConnectionState state) {
          _addOutputLine('  Connection state: ${state.identifier}');

          if (state == BleConnectionState.disconnected && !disconnectionCompleter.isCompleted) {
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
      await _ble.disconnect(_testDeviceAddress!);
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
      } on TimeoutException {
        // Timeout is handled above
      }
    } catch (error) {
      _addOutputLine('  Disconnection failed with error: $error');
    } finally {
      await _connectionSubscription?.cancel();
      _connectionSubscription = null;
    }

    if (disconnectionSuccessful) {
      _addOutputLine('✓ PASS: Successfully disconnected from test device');
    } else {
      _addOutputLine('✗ FAIL: Failed to disconnect gracefully');
    }
    _addOutputLine('');

    return disconnectionSuccessful;
  }

  /// Test 5: Connection timeout - test connection timeout handling.
  Future<bool> _testConnectionTimeout() async {
    _addOutputLine('TEST 5: Connection timeout handling');
    _addOutputLine('Testing connection to non-existent device...');

    // Use a fake MAC address that should not exist
    const String fakeAddress = '00:00:00:00:00:00';
    bool timeoutHandledCorrectly = false;

    try {
      final Stream<BleConnectionState> connectionStream = await _ble.connect(
        deviceAddress: fakeAddress,
      );

      final Completer<bool> timeoutCompleter = Completer<bool>();

      _connectionSubscription = connectionStream.listen(
        (BleConnectionState state) {
          _addOutputLine('  Connection state to fake device: ${state.identifier}');

          // If we somehow connect to the fake address, that's unexpected
          if (state == BleConnectionState.connected) {
            _addOutputLine('  ✗ Unexpected connection to fake address');
            if (!timeoutCompleter.isCompleted) {
              timeoutCompleter.complete(false);
            }
          }
        },
        onError: (Object error) {
          _addOutputLine('  Expected connection error: $error');
          timeoutHandledCorrectly = true;
          if (!timeoutCompleter.isCompleted) {
            timeoutCompleter.complete(true);
          }
        },
      );

      // Wait for timeout or error
      try {
        timeoutHandledCorrectly = await timeoutCompleter.future.timeout(
          const Duration(seconds: 8),
          onTimeout: () {
            _addOutputLine('  Connection attempt timed out as expected');
            return true;
          },
        );
      } on TimeoutException {
        timeoutHandledCorrectly = true;
      }
    } catch (error) {
      _addOutputLine('  Connection to fake device failed as expected: $error');
      timeoutHandledCorrectly = true;
    } finally {
      await _connectionSubscription?.cancel();
      _connectionSubscription = null;

      // Clean up any connection attempt
      try {
        await _ble.disconnect(fakeAddress);
      } catch (error) {
        // Ignore cleanup errors
      }
    }

    if (timeoutHandledCorrectly) {
      _addOutputLine('✓ PASS: Connection timeout handled correctly');
    } else {
      _addOutputLine('✗ FAIL: Connection timeout not handled properly');
    }
    _addOutputLine('');

    return timeoutHandledCorrectly;
  }

  /// Cancels any ongoing operations and cleans up resources.
  Future<void> dispose() async {
    await _scanSubscription?.cancel();
    _scanSubscription = null;

    await _connectionSubscription?.cancel();
    _connectionSubscription = null;

    // Disconnect from test device if still connected
    if (_testDeviceAddress != null) {
      try {
        await _ble.disconnect(_testDeviceAddress!);
      } catch (error) {
        // Ignore cleanup errors
      }
    }
  }
}
