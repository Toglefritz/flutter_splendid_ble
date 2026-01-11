import 'dart:async';

import 'package:flutter_splendid_ble/flutter_splendid_ble.dart';
import 'package:flutter_splendid_ble/shared/models/manufacturer_data.dart';

import '../config/esp32_test_constants.dart';

/// Service for performing BLE scanning tests.
///
/// This service encapsulates all scanning-related test logic, including unfiltered scans, service UUID filtering,
/// device name filtering, and negative test cases.
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
  /// 5. Manufacturer data verification test
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
      await _testManufacturerData(),
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

  /// Test 5: Manufacturer data verification - should detect and validate manufacturer data.
  Future<bool> _testManufacturerData() async {
    _addOutputLine('TEST 5: Manufacturer data verification');
    _addOutputLine('Scanning for test device and verifying manufacturer data...');

    bool testDeviceFound = false;
    bool manufacturerDataValid = false;
    int deviceCount = 0;
    final Set<String> discoveredDevices = <String>{};

    try {
      final Stream<BleDevice> scanStream = await _ble.startScan();

      _scanSubscription = scanStream.listen(
        (BleDevice device) {
          deviceCount++;

          if (device.name == kTestDeviceName) {
            // Only process the test device once
            if (!discoveredDevices.contains(device.address)) {
              discoveredDevices.add(device.address);
              testDeviceFound = true;
              _addOutputLine('  Found test device: ${device.name} (${device.address})');

              // Check manufacturer data
              final ManufacturerData? manufacturerData = device.manufacturerData;
              if (manufacturerData != null) {
                _addOutputLine('  Manufacturer data found:');

                // Convert manufacturer ID from bytes to integer (little-endian)
                final int companyId = manufacturerData.manufacturerId.length >= 2
                    ? manufacturerData.manufacturerId[0] | (manufacturerData.manufacturerId[1] << 8)
                    : 0;

                _addOutputLine('    Company ID: 0x${companyId.toRadixString(16).toUpperCase().padLeft(4, '0')}');
                _addOutputLine(
                    '    Payload: ${manufacturerData.payload.map((int byte) => '0x${byte.toRadixString(16).toUpperCase().padLeft(2, '0')}').join(' ')}',);

                // Verify expected manufacturer data
                if (companyId == kTestManufacturerId) {
                  if (_listsEqual(manufacturerData.payload, kExpectedAdvertisementData)) {
                    _addOutputLine('    ✓ Advertisement data matches expected pattern');
                    manufacturerDataValid = true;
                  } else if (_listsEqual(manufacturerData.payload, kExpectedScanResponseData)) {
                    _addOutputLine('    ✓ Scan response data matches expected pattern');
                    manufacturerDataValid = true;
                  } else {
                    _addOutputLine('    ✗ Payload does not match expected patterns');
                    _addOutputLine(
                        '    Expected (adv): ${kExpectedAdvertisementData.map((int byte) => '0x${byte.toRadixString(16).toUpperCase().padLeft(2, '0')}').join(' ')}',);
                    _addOutputLine(
                        '    Expected (scan): ${kExpectedScanResponseData.map((int byte) => '0x${byte.toRadixString(16).toUpperCase().padLeft(2, '0')}').join(' ')}',);
                  }
                } else {
                  _addOutputLine(
                      '    ✗ Unexpected company ID (expected 0x${kTestManufacturerId.toRadixString(16).toUpperCase().padLeft(4, '0')})',);
                }
              } else {
                _addOutputLine('  ✗ No manufacturer data found');
              }
            }
          } else {
            // Track other devices but don't report them repeatedly
            discoveredDevices.add(device.address);
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

    _addOutputLine('  Scan completed: $deviceCount total detections, ${discoveredDevices.length} unique devices');

    final bool testPassed = testDeviceFound && manufacturerDataValid;
    if (testPassed) {
      _addOutputLine('✓ PASS: Test device found with valid manufacturer data');
    } else if (testDeviceFound && !manufacturerDataValid) {
      _addOutputLine('✗ FAIL: Test device found but manufacturer data invalid');
    } else {
      _addOutputLine('✗ FAIL: Test device not found');
    }
    _addOutputLine('');

    return testPassed;
  }

  /// Compares two lists for equality.
  bool _listsEqual(List<int> list1, List<int> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  /// Performs a BLE scan with optional filters and returns whether test device was found.
  Future<bool> _performScan({
    required String testName,
    required bool expectTestDevice,
    List<ScanFilter>? filters,
  }) async {
    bool testDeviceFound = false;
    int deviceCount = 0;
    final Set<String> discoveredDevices = <String>{};
    final Completer<bool> scanCompleter = Completer<bool>();

    try {
      final Stream<BleDevice> scanStream = await _ble.startScan(filters: filters);

      _scanSubscription = scanStream.listen(
        (BleDevice device) {
          deviceCount++;

          // Only report each unique device once
          if (!discoveredDevices.contains(device.address)) {
            discoveredDevices.add(device.address);
            _addOutputLine(
                '  Found: ${device.name?.isNotEmpty ?? false ? device.name : 'Unknown'} (${device.address})',);

            if (device.name == kTestDeviceName) {
              testDeviceFound = true;
              _addOutputLine('  → This is the test device!');

              // Complete immediately when test device is found
              if (!scanCompleter.isCompleted) {
                scanCompleter.complete(true);
              }
            }
          }
        },
        onError: (Object error) {
          _addOutputLine('  Scan error: $error');
          if (!scanCompleter.isCompleted) {
            scanCompleter.complete(false);
          }
        },
      );

      // Wait for test device to be found or timeout after 10 seconds
      try {
        testDeviceFound = await scanCompleter.future.timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            _addOutputLine('  Scan timeout reached');
            return testDeviceFound;
          },
        );
      } on TimeoutException {
        // Timeout handled above
      }
    } finally {
      _ble.stopScan();
      await _scanSubscription?.cancel();
      _scanSubscription = null;
    }

    _addOutputLine('  Scan completed: $deviceCount total detections, ${discoveredDevices.length} unique devices');
    
    return testDeviceFound;
  }

  /// Cancels any ongoing scan operations.
  Future<void> dispose() async {
    await _scanSubscription?.cancel();
    _scanSubscription = null;
  }
}
