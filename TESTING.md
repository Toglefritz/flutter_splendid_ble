# Flutter Splendid BLE Plugin – Testing Guide

The **Flutter Splendid BLE** plugin provides comprehensive testing capabilities to ensure reliable
development workflows across multiple testing levels. This guide covers both mock-based testing
for unit and integration tests, and hardware-based testing using real BLE devices.

## Testing Approaches

The plugin supports two complementary testing strategies:

1. **Mock Testing**: Using `FakeCentralMethodChannel` for unit tests, integration tests, and
   simulator-based development without requiring physical BLE hardware.

2. **Hardware Integration Testing**: Using the included ESP32 firmware submodule to test against
   real BLE hardware with standardized, predictable behavior.

Both approaches are essential for comprehensive validation of BLE functionality.

## Part 1: Mock Testing with FakeCentralMethodChannel

### Why Mock BLE?

Flutter integration tests typically run on emulators and simulators that lack BLE capabilities.
Additionally, during development, it’s often useful to simulate different device behaviors (e.g.
connecting, disconnecting, advertising services) without needing real devices.

Mocking helps you:

- Test your app logic reliably and repeatedly.
- Develop features that depend on BLE on platforms that don’t support it.
- Validate filtering and connection logic without custom device firmware.

### FakeCentralMethodChannel Overview

`FakeCentralMethodChannel` is a fake implementation of the `CentralPlatformInterface` and can be
injected into your app in place of the real platform channel.

It lets you:

- Add mock BLE devices.
- Simulate scanning results.
- Control device connection states.
- Mock service discovery and characteristic reads.
- Inject Bluetooth state and permission status.

### Getting Started with Mock Testing

#### Injecting the Fake Central into Your App

In tests, initialize `SplendidBleCentral` with `FakeCentralMethodChannel`:

```dart
late FakeCentralMethodChannel fakeCentral;
late SplendidBle ble;

setUp(() {
    fakeCentral = FakeCentralMethodChannel();
    ble = SplendidBleCentral(platform: fakeCentral);
});
```

#### Simulating BLE Scans

Add fake BLE devices before launching your test widget:

```dart
fakeCentral.addFakeDevice(
    BleDevice(
        name: 'Test Device',
        address: '00:11:22:33:44:55',
        rssi: -50,
        manufacturerData: null,
        advertisedServiceUuids: ['abcd1234-1234-1234-1234-1234567890aa'],
    ),
);
```

Then start a scan through your UI or logic. For example, in integration tests:

```dart
await tester.pumpWidget(
    SplendidBleExampleMaterialApp(
      home: ScanRoute(ble: ble),
    ),
);

await tester.pumpAndSettle();

expect(find.text('Test Device'), findsOneWidget);
```

#### Device Filtering

Filters can be applied in tests using the `ScanFilter` class:

```dart
ScanFilter(
    deviceName: 'Test Device',
    serviceUuids: ['abcd1234-1234-1234-1234-1234567890aa'],
)
```

`FakeCentralMethodChannel` respects the same filtering logic as the native layer, so you can
validate filter behavior in tests. Advanced filtering includes:

- Manufacturer ID matching
- Full manufacturer data
- Custom vendor ID matchers (e.g. extracting IDs from names)

```dart
ScanFilter(
    manufacturerId: 0x004C,
    customVendorIdMatcher: (BleDevice device) {
      if (device.name?.length ?? 0 >= 2) {
        final bytes = device.name!.codeUnits.take(2).toList();
        final id = bytes[0] | (bytes[1] << 8);
        
        return id == 0x004C;
      }
      
      return false;
    },
)
```

#### Simulating Connections

You can set and update connection states manually:

```dart
fakeCentral.setConnectionState
(device.address, BleConnectionState.connected);

// or emit a state update later
fakeCentral.simulateConnectionStateUpdate
(device.address, BleConnectionState.disconnected);
```

This enables validation of UI reactions to state transitions in widgets like `DeviceDetailsRoute`
found in the example app.

#### Mocking Service Discovery

Add mock services to simulate discovery results:

```dart
fakeCentral.setServices(device.address, [
    BleService(
    serviceUuid: '180D',
    characteristics: [
    BleCharacteristic(uuid: '2A37', address: device.address),
    ],
    ),
]);
```

This is useful when testing navigation to service/characteristic details after connecting.

### Mock Testing Examples

See _scan_route_test.dart_ in the _example/_ directory for a full examples using:

- Name and service UUID filters
- Manufacturer ID and custom matchers
- Handling multiple results
- Avoiding duplicates

See _device_details_route_test.dart_ for testing connection state changes and service discovery.

## Summary

`FakeCentralMethodChannel` makes it easy to:

- Simulate full BLE flows for tests
- Validate UI logic and filtering
- Run tests on CI or simulators
- Develop BLE apps without real hardware

It’s a powerful tool built into the Flutter Splendid BLE plugin to ensure confidence and flexibility
in your BLE app development workflow.

## Part 2: Hardware Integration Testing with ESP32

### Why Hardware Testing?

While mock testing validates application logic, hardware integration testing ensures that the plugin
works correctly with real BLE devices. This is essential for:

- Validating actual BLE protocol implementation
- Testing performance and reliability under real-world conditions
- Ensuring compatibility across different BLE chipsets and implementations
- Catching platform-specific issues that mocks cannot simulate
- Verifying timing-sensitive operations like connection intervals and notifications

### ESP32 Test Firmware Overview

This repository includes an ESP32 firmware submodule (`firmware/esp32_bluetooth_tester`) that provides
a standardized BLE peripheral specifically designed for testing the Flutter Splendid BLE plugin.

The firmware is implemented as a **PlatformIO project** and is configured by default for the 
**M5 Stack ATOM Matrix ESP32 Development Kit**, though it can be easily adapted for other ESP32 boards
by modifying the `platformio.ini` configuration file.

**Important**: The actual PlatformIO project is located at `firmware/esp32_bluetooth_tester/esp32_bluetooth_tester/`
due to the git submodule structure. The build tools in the `tools/` directory handle this automatically.

The ESP32 test firmware implements:

- **Standard BLE Services**: Heart Rate, Battery, Device Information, and custom test services
- **Comprehensive Characteristics**: Read, write, notify, and indicate characteristics with various properties
- **Error Simulation**: Configurable error conditions for testing error handling
- **Performance Testing**: High-frequency notifications and large data transfers
- **Edge Cases**: Connection parameter negotiation, bonding, and security features
- **Visual Feedback**: LED matrix display on M5 Stack ATOM Matrix for connection status and activity

### Hardware Setup

#### Prerequisites

- ESP32 development board (by default configured for the M5 Stack ATOM Matrix ESP32 Development Kit)
- USB cable for programming and power
- PlatformIO IDE development environment
- Git submodule initialized (the build tools can do this automatically)

**Note**: While the firmware is configured for the M5 Stack ATOM Matrix by default, it can be adapted 
for other ESP32 boards by modifying the `board` setting in `platformio.ini`. Common alternatives include:
- `esp32dev` (Generic ESP32 development board)
- `esp32-s3-devkitc-1` (ESP32-S3 DevKitC)
- `m5stack-core-esp32` (M5Stack Core)
- `m5stick-c` (M5StickC)

#### Setting Up the Development Environment

1. **Install PlatformIO** (recommended approach):
   ```bash
   # Install PlatformIO Core CLI
   pip install platformio
   
   # Or install PlatformIO IDE extension for VS Code
   # Search for "PlatformIO IDE" in VS Code extensions
   ```

2. **Alternative: ESP-IDF Setup**:
   ```bash
   # Follow the official ESP-IDF installation guide
   # https://docs.espressif.com/projects/esp-idf/en/latest/esp32/get-started/
   ```

#### Building and Flashing the Firmware

The repository includes convenient build tools in the `tools/` directory for easy firmware management.

**Option 1: Using the Makefile (Linux/macOS)**
```bash
cd tools
make flash  # Build, upload, and monitor (recommended)
```

**Option 2: Using the shell script (Linux/macOS)**
```bash
cd tools
./flash_firmware.sh flash
```

**Option 3: Using PowerShell script (Windows)**
```powershell
cd tools
.\flash_firmware.ps1 flash
```

**Option 4: Direct PlatformIO commands**
1. **Navigate to the firmware directory**:
   ```bash
   cd firmware/esp32_bluetooth_tester/esp32_bluetooth_tester
   ```

2. **Build and flash using PlatformIO** (recommended):
   ```bash
   # Build the project
   pio run
   
   # Upload to connected device (auto-detects port)
   pio run --target upload
   
   # Monitor serial output
   pio device monitor
   
   # Or combine upload and monitor
   pio run --target upload --target monitor
   ```

3. **Alternative: Build and flash using ESP-IDF**:
   ```bash
   idf.py build
   idf.py -p /dev/ttyUSB0 flash monitor
   ```

For detailed information about the build tools, see `tools/README.md`.

#### Verifying the Setup

After flashing, the ESP32 should:

- Start advertising as "SplendidBLE-Tester"
- Show status information via serial output
- Be discoverable by BLE scanning applications
- Display connection status on the LED matrix (M5 Stack ATOM Matrix only)

#### Customizing for Different ESP32 Boards

If you're using a different ESP32 board, modify the `platformio.ini` file in the firmware directory:

```ini
[env:your_board]
platform = espressif32
board = esp32dev  ; Change this to your board type
framework = arduino
monitor_speed = 115200

; Add any board-specific build flags
build_flags = 
    -DCORE_DEBUG_LEVEL=3
    -DBOARD_HAS_PSRAM
```
