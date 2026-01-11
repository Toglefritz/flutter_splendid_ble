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

/// A different UUID not advertised by the ESP32 test device.
///
/// This UUID is used in negative tests to confirm that filtering
/// works correctly and the test device is not detected when
/// searching for services it doesn't provide.
const String kDifferentServiceUuid = '20000000-5678-5678-5678-123456789def';
