# Flutter Splendid BLE - Build Tools

This directory contains build tools and utilities for the Flutter Splendid BLE plugin, specifically for working with the ESP32 BLE testing firmware.

## Makefile Usage

The `Makefile` provides convenient commands for building and flashing the ESP32 BLE testing firmware using PlatformIO CLI.

### Quick Start

1. **First-time setup**:
   ```bash
   cd tools
   make setup
   ```
   This will install PlatformIO and initialize the firmware submodule.

2. **Flash firmware** (most common command):
   ```bash
   make flash
   ```

### Available Commands

| Command | Description |
|---------|-------------|
| `make help` | Show all available commands |
| `make install` | Install PlatformIO CLI |
| `make setup` | Complete setup (install + init submodule) |
| `make init-submodule` | Initialize the firmware git submodule |
| `make flash` | Build, upload, and monitor (recommended) |
| `make build` | Build the firmware only |
| `make upload` | Build and upload firmware |
| `make monitor` | Start serial monitor |
| `make clean` | Clean build artifacts |
| `make list-devices` | List connected serial devices |
| `make check-env` | Check PlatformIO environment |
| `make update` | Update PlatformIO and libraries |
| `make info` | Show project information |
| `make size` | Show firmware size information |
| `make erase` | Erase ESP32 flash memory |
| `make test` | Run firmware tests |

### Prerequisites

- **PlatformIO CLI**: Install with `make install` or manually with `pip install platformio`
- **ESP32 Development Board**: Connected via USB
- **USB Drivers**: Appropriate drivers for your ESP32 board

### Typical Workflow

1. **Connect your ESP32** development board via USB
2. **Check connection**: `make list-devices`
3. **Flash firmware**: `make flash`
4. **Verify operation**: The device should advertise as "SplendidBLE-Tester"

### Troubleshooting

#### Submodule Not Initialized
```bash
make init-submodule
# or manually:
git submodule update --init --recursive
```

#### PlatformIO Not Found
```bash
make install
# or manually:
pip install platformio
```

#### Device Not Detected
```bash
make list-devices
# Check USB connection and drivers
```

#### Permission Issues (Linux/macOS)
```bash
# Add user to dialout group (Linux)
sudo usermod -a -G dialout $USER
# Then logout and login again

# Or use sudo for one-time access
sudo make flash
```

#### Build Errors
```bash
# Clean and rebuild
make clean
make build
```

### Board Configuration

The firmware is configured by default for the **M5 Stack ATOM Matrix ESP32 Development Kit**. To use a different board:

1. Edit `../firmware/esp32_bluetooth_tester/platformio.ini`
2. Change the `board` setting to your board type
3. Run `make flash`

Common board types:
- `esp32dev` - Generic ESP32 development board
- `esp32-s3-devkitc-1` - ESP32-S3 DevKitC
- `m5stack-core-esp32` - M5Stack Core
- `m5stick-c` - M5StickC

### Development Mode

For active development, use:
```bash
make dev
```
This watches for file changes and automatically rebuilds/uploads.

### Integration with Testing

The flashed firmware provides a standardized BLE peripheral for testing the Flutter Splendid BLE plugin. After flashing:

1. The ESP32 advertises as "SplendidBLE-Tester"
2. Implements standard BLE services (Heart Rate, Battery, etc.)
3. Provides test characteristics for read/write/notify operations
4. Displays connection status on LED matrix (M5 Stack ATOM Matrix)

### CI/CD Integration

For automated testing environments:

```bash
# Install PlatformIO
make install

# Flash firmware
make upload

# Run Flutter integration tests
cd ..
flutter test integration_test/hardware_integration_test.dart
```

### Additional Scripts

You can add additional build scripts or utilities to this directory. The Makefile can be extended to include custom commands for your specific testing needs.

## Support

For issues with the build tools:
1. Check the main project README.md
2. Verify PlatformIO installation: `make check-env`
3. Review the TESTING.md guide for hardware setup details
4. Open an issue on the project repository