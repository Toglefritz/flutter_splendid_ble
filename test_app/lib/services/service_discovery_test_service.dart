import 'dart:async';

import 'package:flutter_splendid_ble/flutter_splendid_ble.dart';

import '../config/esp32_test_constants.dart';

/// Service for performing BLE service discovery tests.
///
/// This service tests service and characteristic discovery functionality.
/// It first establishes a connection to the test device, then performs
/// service discovery and validation tests.
class ServiceDiscoveryTestService {
  /// The BLE central instance used for service discovery operations.
  final SplendidBleCentral _ble;

  /// Callback function for adding output lines to the test display.
  final void Function(String) _addOutputLine;

  /// Subscription to the service discovery stream.
  StreamSubscription<List<BleService>>? _discoverySubscription;

  /// Subscription to the connection state stream.
  StreamSubscription<BleConnectionState>? _connectionSubscription;

  /// Creates a new service discovery test service.
  ServiceDiscoveryTestService(this._ble, this._addOutputLine);

  /// Runs all service discovery tests in sequence.
  ///
  /// This method performs the complete service discovery test suite:
  /// 1. Re-establish connection to test device
  /// 2. Discover services
  /// 3. Validate test service exists
  /// 4. Validate characteristics exist
  ///
  /// The [deviceAddress] parameter specifies the test device to connect to.
  /// Returns true if all tests pass, false if any test fails.
  Future<bool> runAllTests(String deviceAddress) async {
    _addOutputLine('Running BLE service discovery tests...');
    _addOutputLine('Target device: $deviceAddress');
    _addOutputLine('');

    // First, re-establish connection since connection tests disconnect
    final bool connected = await _reconnectToDevice(deviceAddress);
    if (!connected) {
      _addOutputLine('✗ FAIL: Could not connect to device for service discovery');
      _addOutputLine('');
      _addOutputLine('Service discovery tests FAILED');
      return false;
    }

    // Discover services once and use the results for all tests
    final List<BleService> discoveredServices = await _discoverAllServices(deviceAddress);

    if (discoveredServices.isEmpty) {
      _addOutputLine('✗ FAIL: No services discovered');
      _addOutputLine('');
      _addOutputLine('Service discovery tests FAILED');
      return false;
    }

    final List<bool> results = <bool>[
      _testServiceValidation(discoveredServices),
      _testCharacteristicDiscovery(discoveredServices),
    ];

    final bool allPassed = results.every((bool result) => result);
    _addOutputLine('');
    _addOutputLine('Service discovery tests ${allPassed ? 'PASSED' : 'FAILED'}');

    return allPassed;
  }

  /// Re-establishes connection to the test device.
  Future<bool> _reconnectToDevice(String deviceAddress) async {
    _addOutputLine('TEST 1: Re-establishing connection');
    _addOutputLine('Connecting to test device...');

    bool connectionSuccessful = false;

    try {
      final Stream<BleConnectionState> connectionStream = await _ble.connect(
        deviceAddress: deviceAddress,
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
      _addOutputLine('✓ PASS: Successfully reconnected to test device');
    } else {
      _addOutputLine('✗ FAIL: Failed to reconnect to test device');
    }
    _addOutputLine('');

    return connectionSuccessful;
  }

  /// Discovers all services on the connected device.
  Future<List<BleService>> _discoverAllServices(String deviceAddress) async {
    _addOutputLine('TEST 2: Service discovery');
    _addOutputLine('Discovering services on connected device...');

    final List<BleService> allServices = <BleService>[];

    try {
      final Stream<List<BleService>> discoveryStream = await _ble.discoverServices(deviceAddress);
      final Completer<void> discoveryCompleter = Completer<void>();

      _discoverySubscription = discoveryStream.listen(
        (List<BleService> services) {
          _addOutputLine('  Discovered ${services.length} services in this batch');
          for (final BleService service in services) {
            _addOutputLine('    Service: ${service.serviceUuid}');
          }

          allServices.addAll(services);

          // Complete discovery after receiving services
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

    _addOutputLine('  Total services discovered: ${allServices.length}');
    if (allServices.isNotEmpty) {
      _addOutputLine('✓ PASS: Services discovered successfully');
    } else {
      _addOutputLine('✗ FAIL: No services discovered');
    }
    _addOutputLine('');

    return allServices;
  }

  /// Test 3: Test service validation - should find the expected test service.
  bool _testServiceValidation(List<BleService> discoveredServices) {
    _addOutputLine('TEST 3: Test service validation');
    _addOutputLine('Looking for expected test service...');

    bool testServiceFound = false;

    for (final BleService service in discoveredServices) {
      if (service.serviceUuid.toLowerCase() == kTestServiceUuid.toLowerCase()) {
        testServiceFound = true;
        _addOutputLine('  ✓ Found test service: ${service.serviceUuid}');
        break;
      }
    }

    if (!testServiceFound) {
      _addOutputLine('  ✗ Test service not found in discovered services');
    }

    if (testServiceFound) {
      _addOutputLine('✓ PASS: Test service found and validated');
    } else {
      _addOutputLine('✗ FAIL: Test service not found');
    }
    _addOutputLine('');

    return testServiceFound;
  }

  /// Test 4: Characteristic discovery - should find expected characteristics.
  bool _testCharacteristicDiscovery(List<BleService> discoveredServices) {
    _addOutputLine('TEST 4: Characteristic discovery');
    _addOutputLine('Discovering characteristics in test service...');

    bool characteristicsFound = false;
    int characteristicCount = 0;

    for (final BleService service in discoveredServices) {
      if (service.serviceUuid.toLowerCase() == kTestServiceUuid.toLowerCase()) {
        characteristicCount = service.characteristics.length;
        _addOutputLine('  Found test service with $characteristicCount characteristics');

        for (final BleCharacteristic characteristic in service.characteristics) {
          _addOutputLine('    Characteristic: ${characteristic.uuid}');
          _addOutputLine(
              '      Properties: ${characteristic.properties.map((BleCharacteristicProperty prop) => prop.name).join(', ')}');

          final String permissionsText =
              characteristic.permissions?.map((BleCharacteristicPermission perm) => perm.name).join(', ') ?? 'none';
          _addOutputLine('      Permissions: $permissionsText');
        }

        characteristicsFound = service.characteristics.isNotEmpty;
        break;
      }
    }

    if (characteristicsFound) {
      _addOutputLine('✓ PASS: Characteristics discovered successfully ($characteristicCount characteristics)');
    } else {
      _addOutputLine('✗ FAIL: No characteristics found in test service');
    }
    _addOutputLine('');

    return characteristicsFound;
  }

  /// Cancels any ongoing discovery operations and cleans up resources.
  Future<void> dispose() async {
    await _discoverySubscription?.cancel();
    _discoverySubscription = null;

    await _connectionSubscription?.cancel();
    _connectionSubscription = null;
  }
}
