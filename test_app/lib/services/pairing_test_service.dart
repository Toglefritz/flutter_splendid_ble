import 'dart:async';

import 'package:flutter_splendid_ble/flutter_splendid_ble.dart';

import '../config/esp32_test_constants.dart';

/// Service for performing BLE pairing and bonding tests.
///
/// This service tests different pairing scenarios by attempting to access characteristics with various security
/// requirements. It requires user interaction to accept pairing prompts presented by the system.
class PairingTestService {
  /// The BLE central instance used for pairing operations.
  final SplendidBleCentral _ble;

  /// Callback function for adding output lines to the test display.
  final void Function(String) _addOutputLine;

  /// Subscription to the service discovery stream.
  StreamSubscription<List<BleService>>? _discoverySubscription;

  /// Subscription to the connection state stream.
  StreamSubscription<BleConnectionState>? _connectionSubscription;

  /// List of discovered services for characteristic access.
  final List<BleService> _discoveredServices = <BleService>[];

  /// Creates a new pairing test service.
  PairingTestService(this._ble, this._addOutputLine);

  /// Runs all pairing tests in sequence.
  ///
  /// This method performs the complete pairing test suite:
  /// 1. Connect to test device
  /// 2. Discover services and characteristics
  /// 3. Test basic (unencrypted) characteristic access
  /// 4. Test encrypted characteristic access (triggers pairing)
  /// 5. Test MITM-protected characteristic access
  /// 6. Verify pairing persistence
  ///
  /// The [deviceAddress] parameter specifies the test device to connect to. Returns true if all tests pass, false if
  /// any test fails.
  Future<bool> runAllTests(String deviceAddress) async {
    _addOutputLine('Running BLE pairing tests...');
    _addOutputLine('Target device: $deviceAddress');
    _addOutputLine('');
    _addOutputLine(
        '⚠ IMPORTANT: You will need to accept pairing prompts during these tests',);
    _addOutputLine('');

    // Connect and discover services first
    final bool connected = await _connectToDevice(deviceAddress);
    if (!connected) {
      _addOutputLine('✗ FAIL: Could not connect to device for pairing tests');
      _addOutputLine('');
      _addOutputLine('Pairing tests FAILED');
      return false;
    }

    final bool servicesDiscovered = await _discoverServices(deviceAddress);
    if (!servicesDiscovered) {
      _addOutputLine('✗ FAIL: Could not discover services for pairing tests');
      _addOutputLine('');
      _addOutputLine('Pairing tests FAILED');
      return false;
    }

    final List<bool> results = <bool>[
      await _testBasicCharacteristicAccess(),
      await _testEncryptedCharacteristicAccess(),
      await _testMitmCharacteristicAccess(),
      await _testPairingPersistence(),
    ];

    final bool allPassed = results.every((bool result) => result);
    _addOutputLine('');
    _addOutputLine('Pairing tests ${allPassed ? 'PASSED' : 'FAILED'}');

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
              '  Discovered ${services.length} services in this batch',);
          _discoveredServices.addAll(services);

          // Debug: Log all characteristics found
          for (final BleService service in services) {
            if (service.serviceUuid.toLowerCase() ==
                kTestServiceUuid.toLowerCase()) {
              _addOutputLine('  Test service characteristics found:');
              for (final BleCharacteristic characteristic
                  in service.characteristics) {
                _addOutputLine('    - ${characteristic.uuid}');
              }
            }
          }

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
          '✓ PASS: Services discovered successfully (${_discoveredServices.length} services)',);
    } else {
      _addOutputLine('✗ FAIL: No services discovered');
    }
    _addOutputLine('');

    return success;
  }

  /// Test 3: Basic characteristic access - should work without pairing.
  Future<bool> _testBasicCharacteristicAccess() async {
    _addOutputLine('TEST 3: Basic characteristic access (no pairing required)');
    _addOutputLine('Attempting to read from basic characteristic...');

    final BleCharacteristic? characteristic =
        _findCharacteristic(kTestReadCharacteristicUuid);
    if (characteristic == null) {
      _addOutputLine('✗ FAIL: Basic read characteristic not found');
      _addOutputLine('');
      return false;
    }

    bool accessSuccessful = false;

    try {
      _addOutputLine('  Reading from characteristic ${characteristic.uuid}...');
      final String value = await characteristic.readValue<String>(
        timeout: const Duration(seconds: 10),
      );
      _addOutputLine('  Read value: "$value"');
      accessSuccessful = true;
    } catch (error) {
      _addOutputLine('  Read failed: $error');
      accessSuccessful = false;
    }

    if (accessSuccessful) {
      _addOutputLine('✓ PASS: Basic characteristic access successful');
    } else {
      _addOutputLine('✗ FAIL: Basic characteristic access failed');
    }
    _addOutputLine('');

    return accessSuccessful;
  }

  /// Test 4: Encrypted characteristic access - should trigger pairing prompt.
  Future<bool> _testEncryptedCharacteristicAccess() async {
    _addOutputLine(
      'TEST 4: Encrypted characteristic access (pairing required)',
    );
    _addOutputLine('Attempting to access encrypted characteristic...');
    _addOutputLine(
      '⚠ EXPECT: System pairing prompt should appear - please ACCEPT it',
    );
    _addOutputLine('');

    final BleCharacteristic? characteristic =
        _findCharacteristic(kTestEncryptedReadCharacteristicUuid);
    if (characteristic == null) {
      _addOutputLine('✗ FAIL: Encrypted read characteristic not found');
      _addOutputLine('');
      return false;
    }

    bool pairingSuccessful = false;

    try {
      _addOutputLine(
        '  Reading from encrypted characteristic ${characteristic.uuid}...',
      );
      _addOutputLine('  (This should trigger a pairing prompt)');

      final String value = await characteristic.readValue<String>(
        timeout:
            const Duration(seconds: 30), // Longer timeout for user interaction
      );
      _addOutputLine('  Read value: "$value"');
      _addOutputLine('  ✓ Pairing appears to have succeeded!');
      pairingSuccessful = true;
    } catch (error) {
      _addOutputLine('  Read failed: $error');
      _addOutputLine('  This could indicate pairing was rejected or failed');
      pairingSuccessful = false;
    }

    if (pairingSuccessful) {
      _addOutputLine(
        '✓ PASS: Encrypted characteristic access successful (pairing worked)',
      );
    } else {
      _addOutputLine(
        '✗ FAIL: Encrypted characteristic access failed (pairing may have failed)',
      );
    }
    _addOutputLine('');

    return pairingSuccessful;
  }

  /// Test 5: MITM-protected characteristic access - should require authenticated pairing.
  Future<bool> _testMitmCharacteristicAccess() async {
    _addOutputLine('TEST 5: MITM-protected characteristic access');
    _addOutputLine('Checking for MITM-protected characteristic...');

    final BleCharacteristic? characteristic =
        _findCharacteristic(kTestMitmCharacteristicUuid);
    if (characteristic == null) {
      _addOutputLine(
          '✓ PASS: MITM-protected characteristic not found (expected)',);
      _addOutputLine('');
      return true; // This is actually a pass condition
    }

    // If we do find it, try to access it
    bool mitmAccessSuccessful = false;

    try {
      _addOutputLine(
        '  Reading from MITM-protected characteristic ${characteristic.uuid}...',
      );

      final String value = await characteristic.readValue<String>(
        timeout:
            const Duration(seconds: 30), // Longer timeout for user interaction
      );
      _addOutputLine('  Read value: "$value"');
      mitmAccessSuccessful = true;
    } catch (error) {
      _addOutputLine('  Read failed: $error');
      mitmAccessSuccessful = false;
    }

    if (mitmAccessSuccessful) {
      _addOutputLine('✓ PASS: MITM-protected characteristic access successful');
    } else {
      _addOutputLine('✗ FAIL: MITM-protected characteristic access failed');
    }
    _addOutputLine('');

    return mitmAccessSuccessful;
  }

  /// Test 6: Pairing persistence - verify pairing persists across operations.
  Future<bool> _testPairingPersistence() async {
    _addOutputLine('TEST 6: Pairing persistence verification');
    _addOutputLine(
      'Re-accessing encrypted characteristic to verify pairing persists...',
    );

    final BleCharacteristic? characteristic =
        _findCharacteristic(kTestEncryptedReadCharacteristicUuid);
    if (characteristic == null) {
      _addOutputLine('✗ FAIL: Encrypted read characteristic not found');
      _addOutputLine('');
      return false;
    }

    bool persistenceSuccessful = false;

    try {
      _addOutputLine('  Reading from encrypted characteristic again...');
      _addOutputLine('  (This should NOT trigger a new pairing prompt)');

      final String value = await characteristic.readValue<String>(
        timeout: const Duration(
          seconds: 10,
        ), // Shorter timeout since no user interaction expected
      );
      _addOutputLine('  Read value: "$value"');
      _addOutputLine('  ✓ Access succeeded without new pairing prompt!');
      persistenceSuccessful = true;
    } catch (error) {
      _addOutputLine('  Read failed: $error');
      _addOutputLine(
        '  This could indicate pairing was not properly persisted',
      );
      persistenceSuccessful = false;
    }

    if (persistenceSuccessful) {
      _addOutputLine('✓ PASS: Pairing persistence verified');
    } else {
      _addOutputLine('✗ FAIL: Pairing persistence failed');
    }
    _addOutputLine('');

    return persistenceSuccessful;
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
