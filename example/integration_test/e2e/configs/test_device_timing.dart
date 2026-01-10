/// Timing constants for ESP32 test device behavior.
///
/// This class defines timeout values for BLE operations with the ESP32 test device.
/// These values are based on typical BLE operation durations and provide reasonable
/// timeouts for integration testing scenarios.
class TestDeviceTiming {
  /// Maximum time to wait for device discovery in milliseconds.
  ///
  /// This timeout ensures that device discovery tests don't hang
  /// indefinitely if the ESP32 device is not available or advertising.
  static const int discoveryTimeoutMs = 10000;
}
