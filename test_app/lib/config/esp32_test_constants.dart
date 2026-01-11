/// The advertised name of the ESP32 BLE test device.
///
/// This name is broadcast by the ESP32 and used by tests to identify
/// and filter for the correct test device during scanning operations.
const String kTestDeviceName = 'SplendidBLE-Tester';

/// The primary service UUID advertised by the ESP32 test device.
///
/// This UUID identifies the main BLE service provided by the test device
/// and is used for service-based filtering during device discovery.
const String kTestServiceUuid = '10000000-1234-1234-1234-123456789abc';

/// Test characteristic UUID for read operations.
///
/// This characteristic should be discoverable within the test service
/// and support read operations for service discovery validation.
const String kTestReadCharacteristicUuid = '10000001-1234-1234-1234-123456789abc';

/// Test characteristic UUID for write operations.
///
/// This characteristic should be discoverable within the test service
/// and support write operations for service discovery validation.
const String kTestWriteCharacteristicUuid = '10000002-1234-1234-1234-123456789abc';

/// A different UUID not advertised by the ESP32 test device.
///
/// This UUID is used in negative tests to confirm that filtering
/// works correctly and the test device is not detected when
/// searching for services it doesn't provide.
const String kDifferentServiceUuid = '20000000-5678-5678-5678-123456789def';

/// The manufacturer ID used by the ESP32 test device.
///
/// This is the company identifier (0xFFFF) used in manufacturer data.
/// 0xFFFF is reserved for testing purposes.
const int kTestManufacturerId = 0xFFFF;

/// Expected manufacturer data payload in the main advertisement.
///
/// The ESP32 test device broadcasts consecutive numbers 0x00 through 0x0F
/// in the advertisement manufacturer data payload.
const List<int> kExpectedAdvertisementData = <int>[
  0x00,
  0x01,
  0x02,
  0x03,
  0x04,
  0x05,
  0x06,
  0x07,
  0x08,
  0x09,
  0x0A,
  0x0B,
  0x0C,
  0x0D,
  0x0E,
  0x0F,
];

/// Expected manufacturer data payload in the scan response.
///
/// The ESP32 test device broadcasts consecutive numbers 0x10 through 0x1F
/// in the scan response manufacturer data payload.
const List<int> kExpectedScanResponseData = <int>[
  0x10,
  0x11,
  0x12,
  0x13,
  0x14,
  0x15,
  0x16,
  0x17,
  0x18,
  0x19,
  0x1A,
  0x1B,
  0x1C,
  0x1D,
  0x1E,
  0x1F,
];
