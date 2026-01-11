import 'dart:async';

import 'package:flutter_splendid_ble/flutter_splendid_ble.dart';

import '../config/esp32_test_constants.dart';

/// Service for performing BLE scanning tests.
///
/// This service encapsulates all scanning-related test logic, including
/// unfiltered scans, service UUID filtering, device name filtering,
/// and negative test cases.
class ScanningTestService {
  /// The BLE central instance used for scanning operations.
  final SplendidBleCentral _ble;

  /// Callback function for adding output lines to the test display.
  final void Function(String) _addOutputLine;

  /// Subscription to the current BLE scan stream.
  StreamSubscription<BleDevice>? _scanSubscription;

  /// Creates a new scanning test service.
  ScanningTestService(this._ble, this._addOutputLine);

  /// Runs all scanning tests in sequence.
  ///
  /// This method performs the complete scanning test suite:
  /// 1. Unfiltered scan
  /// 2. Service UUID filter test
  /// 3. Different UUID filter test (negative)
  /// 4. Device name filter test
  ///
  /// Returns true if all tests pass, false if any test fails.
  Future<bool> runAllTests() async {
    _addOutputLine('Running BLE scanning tests...');
    _addOutputLine('');

    final List<bool> results = <bool>[
      await _testUnfilteredScan(),
      await _testServiceUuidFilter(),
      await _testDifferentUuidFilter(),
      await _testDeviceNameFilter(),
    ];

    final bool allPassed = results.every((bool result) => result);
    _addOutputLine('');
    _addOutputLine('Scanning tests ${allPassed ? 'PASSED' : 'FAILED'}');

    return allPassed;
  }

  /// Test 1: Unfiltered scan - should detect test device.
  Future<bool> _testUnfilteredScan() async {
    _addOutputLine('TEST 1: Unfiltered scan');
    _addOutputLine('Scanning for all BLE devices...');

    final bool found = await _performScan(
      testName: 'unfiltered',
      expectTestDevice: true,
    );

    if (found) {
      _addOutputLine('✓ PASS: Test device detected in unfiltered scan');
    } else {
      _addOutputLine('✗ FAIL: Test device not found in unfiltered scan');
    }
    _addOutputLine('');

    return found;
  }

  /// Test 2: Service UUID filter - should detect test device.
  Future<bool> _testServiceUuidFilter() async {
    _addOutputLine('TEST 2: Service UUID filter');
    _addOutputLine('Scanning for devices with test service UUID...');

    final bool found = await _performScan(
      testName: 'service UUID filter',
      filters: <ScanFilter>[
        ScanFilter(serviceUuids: <String>[kTestServiceUuid]),
      ],
      expectTestDevice: true,
    );

    if (found) {
      _addOutputLine('✓ PASS: Test device detected with service UUID filter');
    } else {
      _addOutputLine('✗ FAIL: Test device not found with service UUID filter');
    }
    _addOutputLine('');

    return found;
  }

  /// Test 3: Different UUID filter - should NOT detect test device.
  Future<bool> _testDifferentUuidFilter() async {
    _addOutputLine('TEST 3: Different UUID filter (negative test)');
    _addOutputLine('Scanning for devices with different service UUID...');

    final bool found = await _performScan(
      testName: 'different UUID filter',
      filters: <ScanFilter>[
        ScanFilter(serviceUuids: <String>[kDifferentServiceUuid]),
      ],
      expectTestDevice: false,
    );

    if (!found) {
      _addOutputLine('✓ PASS: Test device correctly not detected');
    } else {
      _addOutputLine('✗ FAIL: Test device incorrectly detected');
    }
    _addOutputLine('');

    return !found; // Success is NOT finding the device
  }

  /// Test 4: Device name filter - should detect test device.
  Future<bool> _testDeviceNameFilter() async {
    _addOutputLine('TEST 4: Device name filter');
    _addOutputLine('Scanning for devices with test device name...');

    final bool found = await _performScan(
      testName: 'device name filter',
      filters: <ScanFilter>[
        ScanFilter(deviceName: kTestDeviceName),
      ],
      expectTestDevice: true,
    );

    if (found) {
      _addOutputLine('✓ PASS: Test device detected with name filter');
    } else {
      _addOutputLine('✗ FAIL: Test device not found with name filter');
    }
    _addOutputLine('');

    return found;
  }

  /// Performs a BLE scan with optional filters and returns whether test device was found.
  Future<bool> _performScan({
    required String testName,
    required bool expectTestDevice,
    List<ScanFilter>? filters,
  }) async {
    bool testDeviceFound = false;
    int deviceCount = 0;

    try {
      final Stream<BleDevice> scanStream = await _ble.startScan(filters: filters);

      _scanSubscription = scanStream.listen(
        (BleDevice device) {
          deviceCount++;
          _addOutputLine('  Found: ${device.name?.isNotEmpty ?? false ? device.name : 'Unknown'} (${device.address})');

          if (device.name == kTestDeviceName) {
            testDeviceFound = true;
            _addOutputLine('  → This is the test device!');
          }
        },
        onError: (Object error) {
          _addOutputLine('  Scan error: $error');
        },
      );

      // Scan for 10 seconds
      await Future<void>.delayed(const Duration(seconds: 10));
    } finally {
      _ble.stopScan();
      await _scanSubscription?.cancel();
      _scanSubscription = null;
    }

    _addOutputLine('  Scan completed: $deviceCount devices found');
    return testDeviceFound;
  }

  /// Cancels any ongoing scan operations.
  Future<void> dispose() async {
    await _scanSubscription?.cancel();
    _scanSubscription = null;
  }
}
