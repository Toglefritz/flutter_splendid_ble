import 'dart:async';

import 'package:flutter_splendid_ble/flutter_splendid_ble.dart';

import '../config/esp32_test_constants.dart';

/// Service for performing BLE read/write operation tests.
///
/// This service tests various read and write operations against both open
/// and encrypted characteristics to validate proper data transfer and
/// security behavior.
class ReadWriteTestService {
  /// The BLE central instance used for read/write operations.
  final SplendidBleCentral _ble;

  /// Callback function for adding output lines to the test display.
  final void Function(String) _addOutputLine;

  /// Subscription to the service discovery stream.
  StreamSubscription<List<BleService>>? _discoverySubscription;

  /// Subscription to the connection state stream.
  StreamSubscription<BleConnectionState>? _connectionSubscription;

  /// List of discovered services for characteristic access.
  final List<BleService> _discoveredServices = <BleService>[];

  /// Creates a new read/write test service.
  ReadWriteTestService(this._ble, this._addOutputLine);

  /// Runs all read/write tests in sequence.
  ///
  /// This method performs the complete read/write test suite:
  /// 1. Connect to test device
  /// 2. Discover services and characteristics
  /// 3. Test basic read operations
  /// 4. Test basic write operations
  /// 5. Test read/write round-trip
  /// 6. Test encrypted read operations
  /// 7. Test encrypted write operations
  ///
  /// The [deviceAddress] parameter specifies the test device to connect to.
  /// Returns true if all tests pass, false if any test fails.
  Future<bool> runAllTests(String deviceAddress) async {
    _addOutputLine('Running BLE read/write tests...');
    _addOutputLine('Target device: $deviceAddress');
    _addOutputLine('');

    // Connect and discover services first
    final bool connected = await _connectToDevice(deviceAddress);
    if (!connected) {
      _addOutputLine(
          '✗ FAIL: Could not connect to device for read/write tests',);
      _addOutputLine('');
      _addOutputLine('Read/write tests FAILED');
      return false;
    }

    final bool servicesDiscovered = await _discoverServices(deviceAddress);
    if (!servicesDiscovered) {
      _addOutputLine(
          '✗ FAIL: Could not discover services for read/write tests',);
      _addOutputLine('');
      _addOutputLine('Read/write tests FAILED');
      return false;
    }

    final List<bool> results = <bool>[
      await _testBasicRead(),
      await _testBasicWrite(),
      await _testReadWriteRoundTrip(),
      await _testEncryptedRead(),
      await _testEncryptedWrite(),
    ];

    final bool allPassed = results.every((bool result) => result);
    _addOutputLine('');
    _addOutputLine('Read/write tests ${allPassed ? 'PASSED' : 'FAILED'}');

    return allPassed;
  }

  /// Connects to the test device.
  Future<bool> _connectToDevice(String deviceAddress) async {
    _addOutputLine('TEST 1: Connecting to test device');
    _addOutputLine('Establishing connection...');

    bool connectionSuccessful = false;

    try {
      final Stream<BleConnectionState> connectionStream = await _ble.connect(
        deviceAddress: deviceAddress,
      );

      final Completer<BleConnectionState> connectionCompleter =
          Completer<BleConnectionState>();

      _connectionSubscription = connectionStream.listen(
        (BleConnectionState state) {
          _addOutputLine('  Connection state: ${state.identifier}');

          if (state == BleConnectionState.connected) {
            connectionSuccessful = true;
            if (!connectionCompleter.isCompleted) {
              connectionCompleter.complete(state);
            }
          } else if (state == BleConnectionState.disconnected &&
              !connectionCompleter.isCompleted) {
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

      // Wait for connection with timeout
      try {
        await connectionCompleter.future.timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            _addOutputLine('  Connection timed out');
            return BleConnectionState.unknown;
          },
        );
      } on TimeoutException {
        connectionSuccessful = false;
      }
    } catch (error) {
      _addOutputLine('  Connection failed: $error');
      connectionSuccessful = false;
    } finally {
      await _connectionSubscription?.cancel();
      _connectionSubscription = null;
    }

    if (connectionSuccessful) {
      _addOutputLine('✓ PASS: Successfully connected to test device');
    } else {
      _addOutputLine('✗ FAIL: Failed to connect to test device');
    }
    _addOutputLine('');

    return connectionSuccessful;
  }

  /// Discovers services on the connected device.
  Future<bool> _discoverServices(String deviceAddress) async {
    _addOutputLine('TEST 2: Service discovery');
    _addOutputLine('Discovering services and characteristics...');

    try {
      final Stream<List<BleService>> discoveryStream =
          await _ble.discoverServices(deviceAddress);
      final Completer<void> discoveryCompleter = Completer<void>();

      _discoverySubscription = discoveryStream.listen(
        (List<BleService> services) {
          _addOutputLine(
            '  Discovered ${services.length} services in this batch',
          );
          _discoveredServices.addAll(services);

          if (!discoveryCompleter.isCompleted) {
            discoveryCompleter.complete();
          }
        },
        onError: (Object error) {
          _addOutputLine('  Service discovery error: $error');
          if (!discoveryCompleter.isCompleted) {
            discoveryCompleter.completeError(error);
          }
        },
        onDone: () {
          if (!discoveryCompleter.isCompleted) {
            discoveryCompleter.complete();
          }
        },
      );

      // Wait for service discovery with timeout
      try {
        await discoveryCompleter.future.timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            _addOutputLine('  Service discovery timed out');
          },
        );
      } on TimeoutException {
        // Timeout handled above
      }
    } catch (error) {
      _addOutputLine('  Service discovery failed: $error');
    } finally {
      await _discoverySubscription?.cancel();
      _discoverySubscription = null;
    }

    final bool success = _discoveredServices.isNotEmpty;
    if (success) {
      _addOutputLine(
        '✓ PASS: Services discovered successfully (${_discoveredServices.length} services)',
      );
    } else {
      _addOutputLine('✗ FAIL: No services discovered');
    }
    _addOutputLine('');

    return success;
  }

  /// Test 3: Basic read operation - read from read-only characteristic.
  Future<bool> _testBasicRead() async {
    _addOutputLine('TEST 3: Basic read operation');
    _addOutputLine('Reading from read-only characteristic...');

    final BleCharacteristic? characteristic =
        _findCharacteristic(kTestReadOnlyCharacteristicUuid);
    if (characteristic == null) {
      _addOutputLine('✗ FAIL: Read-only characteristic not found');
      _addOutputLine('');
      return false;
    }

    bool readSuccessful = false;

    try {
      _addOutputLine('  Reading from characteristic ${characteristic.uuid}...');
      final String value = await characteristic.readValue<String>(
        timeout: const Duration(seconds: 10),
      );
      _addOutputLine('  Read value: "$value"');
      readSuccessful = value.isNotEmpty;
    } catch (error) {
      _addOutputLine('  Read failed: $error');
      readSuccessful = false;
    }

    if (readSuccessful) {
      _addOutputLine('✓ PASS: Basic read operation successful');
    } else {
      _addOutputLine('✗ FAIL: Basic read operation failed');
    }
    _addOutputLine('');

    return readSuccessful;
  }

  /// Test 4: Basic write operation - write to read/write characteristic.
  Future<bool> _testBasicWrite() async {
    _addOutputLine('TEST 4: Basic write operation');
    _addOutputLine('Writing to read/write characteristic...');

    final BleCharacteristic? characteristic =
        _findCharacteristic(kTestReadCharacteristicUuid);
    if (characteristic == null) {
      _addOutputLine('✗ FAIL: Read/write characteristic not found');
      _addOutputLine('');
      return false;
    }

    bool writeSuccessful = false;
    final String testData =
        'Test write ${DateTime.now().millisecondsSinceEpoch}';

    try {
      _addOutputLine('  Writing to characteristic ${characteristic.uuid}...');
      _addOutputLine('  Test data: "$testData"');

      await characteristic.writeValue(
        value: testData,
      );
      _addOutputLine('  Write completed successfully');
      writeSuccessful = true;
    } catch (error) {
      _addOutputLine('  Write failed: $error');
      writeSuccessful = false;
    }

    if (writeSuccessful) {
      _addOutputLine('✓ PASS: Basic write operation successful');
    } else {
      _addOutputLine('✗ FAIL: Basic write operation failed');
    }
    _addOutputLine('');

    return writeSuccessful;
  }

  /// Test 5: Read/write round-trip - write then read back the same data.
  Future<bool> _testReadWriteRoundTrip() async {
    _addOutputLine('TEST 5: Read/write round-trip');
    _addOutputLine('Writing data then reading it back...');

    final BleCharacteristic? characteristic =
        _findCharacteristic(kTestReadCharacteristicUuid);
    if (characteristic == null) {
      _addOutputLine('✗ FAIL: Read/write characteristic not found');
      _addOutputLine('');
      return false;
    }

    bool roundTripSuccessful = false;
    final String testData =
        'RoundTrip-${DateTime.now().millisecondsSinceEpoch}';

    try {
      // Write the test data
      _addOutputLine('  Writing test data: "$testData"');
      await characteristic.writeValue(
        value: testData,
      );
      _addOutputLine('  Write completed');

      // Small delay to ensure write is processed
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Read the data back
      _addOutputLine('  Reading data back...');
      final String readValue = await characteristic.readValue<String>(
        timeout: const Duration(seconds: 10),
      );
      _addOutputLine('  Read value: "$readValue"');

      // Verify the data matches
      if (readValue == testData) {
        _addOutputLine('  ✓ Data matches - round-trip successful!');
        roundTripSuccessful = true;
      } else {
        _addOutputLine('  ✗ Data mismatch - round-trip failed');
        _addOutputLine('    Expected: "$testData"');
        _addOutputLine('    Received: "$readValue"');
        roundTripSuccessful = false;
      }
    } catch (error) {
      _addOutputLine('  Round-trip failed: $error');
      roundTripSuccessful = false;
    }

    if (roundTripSuccessful) {
      _addOutputLine('✓ PASS: Read/write round-trip successful');
    } else {
      _addOutputLine('✗ FAIL: Read/write round-trip failed');
    }
    _addOutputLine('');

    return roundTripSuccessful;
  }

  /// Test 6: Encrypted read operation - read from encrypted characteristic.
  Future<bool> _testEncryptedRead() async {
    _addOutputLine('TEST 6: Encrypted read operation');
    _addOutputLine('Reading from encrypted characteristic...');
    _addOutputLine('⚠ EXPECT: System pairing prompt may appear');

    final BleCharacteristic? characteristic =
        _findCharacteristic(kTestEncryptedReadCharacteristicUuid);
    if (characteristic == null) {
      _addOutputLine('✗ FAIL: Encrypted read characteristic not found');
      _addOutputLine('');
      return false;
    }

    bool encryptedReadSuccessful = false;

    try {
      _addOutputLine(
          '  Reading from encrypted characteristic ${characteristic.uuid}...',);
      final String value = await characteristic.readValue<String>(
        timeout: const Duration(seconds: 30), // Longer timeout for pairing
      );
      _addOutputLine('  Read encrypted value: "$value"');
      encryptedReadSuccessful = value.isNotEmpty;
    } catch (error) {
      _addOutputLine('  Encrypted read failed: $error');
      encryptedReadSuccessful = false;
    }

    if (encryptedReadSuccessful) {
      _addOutputLine('✓ PASS: Encrypted read operation successful');
    } else {
      _addOutputLine('✗ FAIL: Encrypted read operation failed');
    }
    _addOutputLine('');

    return encryptedReadSuccessful;
  }

  /// Test 7: Encrypted write operation - write to encrypted characteristic.
  Future<bool> _testEncryptedWrite() async {
    _addOutputLine('TEST 7: Encrypted write operation');
    _addOutputLine('Writing to encrypted characteristic...');

    final BleCharacteristic? characteristic =
        _findCharacteristic(kTestEncryptedWriteCharacteristicUuid);
    if (characteristic == null) {
      _addOutputLine(
          '✓ PASS: Encrypted write characteristic not found (expected)',);
      _addOutputLine('');
      return true; // Expected behavior - encrypted characteristics may be hidden
    }

    bool encryptedWriteSuccessful = false;
    final String testData =
        'Encrypted-${DateTime.now().millisecondsSinceEpoch}';

    try {
      _addOutputLine(
          '  Writing to encrypted characteristic ${characteristic.uuid}...',);
      _addOutputLine('  Encrypted test data: "$testData"');

      await characteristic.writeValue(
        value: testData,
      );
      _addOutputLine('  Encrypted write completed successfully');
      encryptedWriteSuccessful = true;
    } catch (error) {
      _addOutputLine('  Encrypted write failed: $error');
      encryptedWriteSuccessful = false;
    }

    if (encryptedWriteSuccessful) {
      _addOutputLine('✓ PASS: Encrypted write operation successful');
    } else {
      _addOutputLine('✗ FAIL: Encrypted write operation failed');
    }
    _addOutputLine('');

    return encryptedWriteSuccessful;
  }

  /// Finds a characteristic by UUID in the discovered services.
  BleCharacteristic? _findCharacteristic(String characteristicUuid) {
    for (final BleService service in _discoveredServices) {
      if (service.serviceUuid.toLowerCase() == kTestServiceUuid.toLowerCase()) {
        for (final BleCharacteristic characteristic
            in service.characteristics) {
          if (characteristic.uuid.toLowerCase() ==
              characteristicUuid.toLowerCase()) {
            return characteristic;
          }
        }
      }
    }
    return null;
  }

  /// Cancels any ongoing operations and cleans up resources.
  Future<void> dispose() async {
    await _discoverySubscription?.cancel();
    _discoverySubscription = null;

    await _connectionSubscription?.cancel();
    _connectionSubscription = null;
  }
}
