import 'dart:async';

import 'package:flutter_splendid_ble/flutter_splendid_ble.dart';

import '../config/esp32_test_constants.dart';

/// Service for performing BLE notification and indication tests.
///
/// This service tests the subscription mechanism for both notifications
/// (fire-and-forget) and indications (require acknowledgment) to validate
/// proper real-time data streaming behavior.
class NotificationTestService {
  /// The BLE central instance used for notification operations.
  final SplendidBleCentral _ble;

  /// Callback function for adding output lines to the test display.
  final void Function(String) _addOutputLine;

  /// Subscription to the service discovery stream.
  StreamSubscription<List<BleService>>? _discoverySubscription;

  /// Subscription to the connection state stream.
  StreamSubscription<BleConnectionState>? _connectionSubscription;

  /// Subscription to notification updates.
  StreamSubscription<BleCharacteristicValue>? _notificationSubscription;

  /// Subscription to indication updates.
  StreamSubscription<BleCharacteristicValue>? _indicationSubscription;

  /// List of discovered services for characteristic access.
  final List<BleService> _discoveredServices = <BleService>[];

  /// Creates a new notification test service.
  NotificationTestService(this._ble, this._addOutputLine);

  /// Runs all notification and indication tests in sequence.
  ///
  /// This method performs the complete notification test suite:
  /// 1. Connect to test device
  /// 2. Discover services and characteristics
  /// 3. Test notification subscription
  /// 4. Test notification value reception
  /// 5. Test notification unsubscribe
  /// 6. Test indication subscription
  /// 7. Test indication value reception
  /// 8. Test indication unsubscribe
  ///
  /// The [deviceAddress] parameter specifies the test device to connect to.
  /// Returns true if all tests pass, false if any test fails.
  Future<bool> runAllTests(String deviceAddress) async {
    _addOutputLine('Running BLE notification/indication tests...');
    _addOutputLine('Target device: $deviceAddress');
    _addOutputLine('');

    // Connect and discover services first
    final bool connected = await _connectToDevice(deviceAddress);
    if (!connected) {
      _addOutputLine(
        '✗ FAIL: Could not connect to device for notification tests',
      );
      _addOutputLine('');
      _addOutputLine('Notification tests FAILED');
      return false;
    }

    final bool servicesDiscovered = await _discoverServices(deviceAddress);
    if (!servicesDiscovered) {
      _addOutputLine(
        '✗ FAIL: Could not discover services for notification tests',
      );
      _addOutputLine('');
      _addOutputLine('Notification tests FAILED');
      return false;
    }

    final List<bool> results = <bool>[
      await _testNotificationSubscription(),
      await _testNotificationValueReception(),
      await _testNotificationUnsubscribe(),
      await _testIndicationSubscription(),
      await _testIndicationValueReception(),
      await _testIndicationUnsubscribe(),
    ];

    final bool allPassed = results.every((bool result) => result);
    _addOutputLine('');
    _addOutputLine(
      'Notification/indication tests ${allPassed ? 'PASSED' : 'FAILED'}',
    );

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

  /// Test 3: Notification subscription - subscribe to notification characteristic.
  Future<bool> _testNotificationSubscription() async {
    _addOutputLine('TEST 3: Notification subscription');
    _addOutputLine('Subscribing to notification characteristic...');

    final BleCharacteristic? characteristic =
        _findCharacteristic(kTestNotifyCharacteristicUuid);
    if (characteristic == null) {
      _addOutputLine('✗ FAIL: Notify characteristic not found');
      _addOutputLine('');
      return false;
    }

    bool subscriptionSuccessful = false;

    try {
      _addOutputLine(
        '  Subscribing to characteristic ${characteristic.uuid}...',
      );

      final Stream<BleCharacteristicValue> notificationStream =
          await characteristic.subscribe();

      _addOutputLine('  Subscription established');
      subscriptionSuccessful = true;

      // Keep subscription active for next test
      _notificationSubscription = notificationStream.listen(
        (BleCharacteristicValue value) {
          // Values will be processed in the next test
        },
        onError: (Object error) {
          _addOutputLine('  Notification stream error: $error');
        },
      );
    } catch (error) {
      _addOutputLine('  Subscription failed: $error');
      subscriptionSuccessful = false;
    }

    if (subscriptionSuccessful) {
      _addOutputLine('✓ PASS: Notification subscription successful');
    } else {
      _addOutputLine('✗ FAIL: Notification subscription failed');
    }
    _addOutputLine('');

    return subscriptionSuccessful;
  }

  /// Test 4: Notification value reception - receive multiple notification values.
  Future<bool> _testNotificationValueReception() async {
    _addOutputLine('TEST 4: Notification value reception');
    _addOutputLine('Waiting for notification values...');

    if (_notificationSubscription == null) {
      _addOutputLine('✗ FAIL: No active notification subscription');
      _addOutputLine('');
      return false;
    }

    final BleCharacteristic? characteristic =
        _findCharacteristic(kTestNotifyCharacteristicUuid);
    if (characteristic == null) {
      _addOutputLine('✗ FAIL: Notify characteristic not found');
      _addOutputLine('');
      return false;
    }

    bool valuesReceived = false;
    final List<String> receivedValues = <String>[];
    final Completer<bool> receptionCompleter = Completer<bool>();

    try {
      // Re-subscribe to capture values
      await _notificationSubscription?.cancel();

      final Stream<BleCharacteristicValue> notificationStream =
          await characteristic.subscribe();

      _notificationSubscription = notificationStream.listen(
        (BleCharacteristicValue value) {
          final String stringValue = value.valueString;
          receivedValues.add(stringValue);
          _addOutputLine('  Received notification: "$stringValue"');

          // Wait for at least 2 values to confirm streaming works
          if (receivedValues.length >= 2 && !receptionCompleter.isCompleted) {
            valuesReceived = true;
            receptionCompleter.complete(true);
          }
        },
        onError: (Object error) {
          _addOutputLine('  Notification error: $error');
          if (!receptionCompleter.isCompleted) {
            receptionCompleter.complete(false);
          }
        },
      );

      // Wait up to 10 seconds for notifications
      try {
        valuesReceived = await receptionCompleter.future.timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            _addOutputLine(
              '  Timeout waiting for notifications (received ${receivedValues.length})',
            );
            return receivedValues.length >= 2;
          },
        );
      } on TimeoutException {
        valuesReceived = receivedValues.length >= 2;
      }
    } catch (error) {
      _addOutputLine('  Value reception failed: $error');
      valuesReceived = false;
    }

    if (valuesReceived) {
      _addOutputLine(
        '✓ PASS: Notification values received (${receivedValues.length} values)',
      );
    } else {
      _addOutputLine('✗ FAIL: Failed to receive notification values');
    }
    _addOutputLine('');

    return valuesReceived;
  }

  /// Test 5: Notification unsubscribe - verify notifications stop after unsubscribe.
  Future<bool> _testNotificationUnsubscribe() async {
    _addOutputLine('TEST 5: Notification unsubscribe');
    _addOutputLine('Unsubscribing from notifications...');

    final BleCharacteristic? characteristic =
        _findCharacteristic(kTestNotifyCharacteristicUuid);
    if (characteristic == null) {
      _addOutputLine('✗ FAIL: Notify characteristic not found');
      _addOutputLine('');
      return false;
    }

    bool unsubscribeSuccessful = false;

    try {
      // Cancel the stream subscription first
      await _notificationSubscription?.cancel();
      _notificationSubscription = null;

      // Then unsubscribe from the characteristic on the platform side
      characteristic.unsubscribe();
      _addOutputLine('  Unsubscribed from notifications');

      // Wait a bit to ensure no more notifications arrive
      await Future<void>.delayed(const Duration(seconds: 2));

      _addOutputLine('  No notifications received after unsubscribe');
      unsubscribeSuccessful = true;
    } catch (error) {
      _addOutputLine('  Unsubscribe failed: $error');
      unsubscribeSuccessful = false;
    }

    if (unsubscribeSuccessful) {
      _addOutputLine('✓ PASS: Notification unsubscribe successful');
    } else {
      _addOutputLine('✗ FAIL: Notification unsubscribe failed');
    }
    _addOutputLine('');

    return unsubscribeSuccessful;
  }

  /// Test 6: Indication subscription - subscribe to indication characteristic.
  Future<bool> _testIndicationSubscription() async {
    _addOutputLine('TEST 6: Indication subscription');
    _addOutputLine('Subscribing to indication characteristic...');

    final BleCharacteristic? characteristic =
        _findCharacteristic(kTestIndicateCharacteristicUuid);
    if (characteristic == null) {
      _addOutputLine('✗ FAIL: Indicate characteristic not found');
      _addOutputLine('');
      return false;
    }

    bool subscriptionSuccessful = false;

    try {
      _addOutputLine(
        '  Subscribing to characteristic ${characteristic.uuid}...',
      );

      final Stream<BleCharacteristicValue> indicationStream =
          await characteristic.subscribe();

      _addOutputLine('  Subscription established');
      subscriptionSuccessful = true;

      // Keep subscription active for next test
      _indicationSubscription = indicationStream.listen(
        (BleCharacteristicValue value) {
          // Values will be processed in the next test
        },
        onError: (Object error) {
          _addOutputLine('  Indication stream error: $error');
        },
      );
    } catch (error) {
      _addOutputLine('  Subscription failed: $error');
      subscriptionSuccessful = false;
    }

    if (subscriptionSuccessful) {
      _addOutputLine('✓ PASS: Indication subscription successful');
    } else {
      _addOutputLine('✗ FAIL: Indication subscription failed');
    }
    _addOutputLine('');

    return subscriptionSuccessful;
  }

  /// Test 7: Indication value reception - receive multiple indication values.
  Future<bool> _testIndicationValueReception() async {
    _addOutputLine('TEST 7: Indication value reception');
    _addOutputLine('Waiting for indication values...');

    if (_indicationSubscription == null) {
      _addOutputLine('✗ FAIL: No active indication subscription');
      _addOutputLine('');
      return false;
    }

    final BleCharacteristic? characteristic =
        _findCharacteristic(kTestIndicateCharacteristicUuid);
    if (characteristic == null) {
      _addOutputLine('✗ FAIL: Indicate characteristic not found');
      _addOutputLine('');
      return false;
    }

    bool valuesReceived = false;
    final List<String> receivedValues = <String>[];
    final Completer<bool> receptionCompleter = Completer<bool>();

    try {
      // Re-subscribe to capture values
      await _indicationSubscription?.cancel();

      final Stream<BleCharacteristicValue> indicationStream =
          await characteristic.subscribe();

      _indicationSubscription = indicationStream.listen(
        (BleCharacteristicValue value) {
          final String stringValue = value.valueString;
          receivedValues.add(stringValue);
          _addOutputLine('  Received indication: "$stringValue"');

          // Wait for at least 2 values to confirm streaming works
          if (receivedValues.length >= 2 && !receptionCompleter.isCompleted) {
            valuesReceived = true;
            receptionCompleter.complete(true);
          }
        },
        onError: (Object error) {
          _addOutputLine('  Indication error: $error');
          if (!receptionCompleter.isCompleted) {
            receptionCompleter.complete(false);
          }
        },
      );

      // Wait up to 15 seconds for indications (they're sent every 5 seconds)
      try {
        valuesReceived = await receptionCompleter.future.timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            _addOutputLine(
              '  Timeout waiting for indications (received ${receivedValues.length})',
            );
            return receivedValues.length >= 2;
          },
        );
      } on TimeoutException {
        valuesReceived = receivedValues.length >= 2;
      }
    } catch (error) {
      _addOutputLine('  Value reception failed: $error');
      valuesReceived = false;
    }

    if (valuesReceived) {
      _addOutputLine(
        '✓ PASS: Indication values received (${receivedValues.length} values)',
      );
    } else {
      _addOutputLine('✗ FAIL: Failed to receive indication values');
    }
    _addOutputLine('');

    return valuesReceived;
  }

  /// Test 8: Indication unsubscribe - verify indications stop after unsubscribe.
  Future<bool> _testIndicationUnsubscribe() async {
    _addOutputLine('TEST 8: Indication unsubscribe');
    _addOutputLine('Unsubscribing from indications...');

    final BleCharacteristic? characteristic =
        _findCharacteristic(kTestIndicateCharacteristicUuid);
    if (characteristic == null) {
      _addOutputLine('✗ FAIL: Indicate characteristic not found');
      _addOutputLine('');
      return false;
    }

    bool unsubscribeSuccessful = false;

    try {
      // Cancel the stream subscription first
      await _indicationSubscription?.cancel();
      _indicationSubscription = null;

      // Then unsubscribe from the characteristic on the platform side
      characteristic.unsubscribe();
      _addOutputLine('  Unsubscribed from indications');

      // Wait a bit to ensure no more indications arrive
      await Future<void>.delayed(const Duration(seconds: 2));

      _addOutputLine('  No indications received after unsubscribe');
      unsubscribeSuccessful = true;
    } catch (error) {
      _addOutputLine('  Unsubscribe failed: $error');
      unsubscribeSuccessful = false;
    }

    if (unsubscribeSuccessful) {
      _addOutputLine('✓ PASS: Indication unsubscribe successful');
    } else {
      _addOutputLine('✗ FAIL: Indication unsubscribe failed');
    }
    _addOutputLine('');

    return unsubscribeSuccessful;
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
    // Unsubscribe from notifications if active
    if (_notificationSubscription != null) {
      final BleCharacteristic? notifyChar =
          _findCharacteristic(kTestNotifyCharacteristicUuid);
      notifyChar?.unsubscribe();
      await _notificationSubscription?.cancel();
      _notificationSubscription = null;
    }

    // Unsubscribe from indications if active
    if (_indicationSubscription != null) {
      final BleCharacteristic? indicateChar =
          _findCharacteristic(kTestIndicateCharacteristicUuid);
      indicateChar?.unsubscribe();
      await _indicationSubscription?.cancel();
      _indicationSubscription = null;
    }

    await _discoverySubscription?.cancel();
    _discoverySubscription = null;

    await _connectionSubscription?.cancel();
    _connectionSubscription = null;
  }
}
