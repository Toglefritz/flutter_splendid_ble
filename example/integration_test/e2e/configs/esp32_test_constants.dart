/// Constants for ESP32 BLE test device integration testing.
///
/// This file contains UUIDs and device identifiers used by the ESP32 BLE
/// test device firmware. These constants ensure consistency between the
/// hardware device and integration tests.
library;

import 'package:flutter/foundation.dart';

/// BLE device name for the ESP32 test device.
///
/// This name is advertised by the ESP32 and used by integration tests
/// to identify and connect to the correct test device.
@visibleForTesting
const String kTestDeviceName = 'SplendidBLE-Tester';

/// Primary test service UUID.
///
/// The ESP32 firmware exposes a single service containing all test
/// characteristics for comprehensive BLE functionality validation.
@visibleForTesting
const String kTestServiceUuid = '10000000-1234-1234-1234-123456789abc';

/// Read/Write characteristic UUID.
///
/// Supports both read and write operations for basic data exchange testing.
/// Default value: "Hello BLE"
@visibleForTesting
const String kReadWriteCharUuid = '10000001-1234-1234-1234-123456789abc';

/// Read-only characteristic UUID.
///
/// Provides device information that can only be read, not modified.
/// Value: "ESP32-BLE-Tester v1.0"
@visibleForTesting
const String kReadOnlyCharUuid = '10000002-1234-1234-1234-123456789abc';

/// Write-only characteristic UUID.
///
/// Accepts commands and data that cannot be read back.
/// Used for command processing and write-only operation testing.
@visibleForTesting
const String kWriteOnlyCharUuid = '10000003-1234-1234-1234-123456789abc';

/// Notify characteristic UUID.
///
/// Sends periodic notifications to subscribed clients.
/// Notification format: "Counter: X" every 3 seconds
@visibleForTesting
const String kNotifyCharUuid = '10000004-1234-1234-1234-123456789abc';

/// Large data characteristic UUID.
///
/// Contains approximately 500 bytes of test data for MTU and
/// large data transfer testing.
@visibleForTesting
const String kLargeDataCharUuid = '10000005-1234-1234-1234-123456789abc';
