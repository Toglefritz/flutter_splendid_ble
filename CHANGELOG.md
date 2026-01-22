# Changelog

All notable changes to the `flutter_splendid_ble` plugin will be documented in this file.

## [0.1.0] 2023/10/07

- Initial support for Bluetooth operations on Android:
    - Bluetooth status checking.
    - Emitting current Bluetooth status.
    - Bluetooth device scanning.
    - Bluetooth device connection handling.
    - Bluetooth service and characteristic discovery and subscription.
    - Reading from Bluetooth characteristics.
    - Writing to Bluetooth characteristics.
    - Terminating a connection to a BLE device.
- Android example application to demonstrate basic usage.
- Comprehensive documentation for Android functionality.

## [0.2.0] 2023/11/02

- Finalized support for Android.
- Added support for Bluetooth operations MacOS:
    - Bluetooth status checking.
    - Emitting current Bluetooth status.
    - Bluetooth device scanning.
    - Bluetooth device connection handling.
    - Bluetooth service and characteristic discovery and subscription.
    - Reading from Bluetooth characteristics.
    - Writing to Bluetooth characteristics.
    - Terminating a connection to a BLE device.
- Added MacOS support to the example application.
- Comprehensive documentation for MacOS functionality.
- Added automated test for all plugin methods.

## [0.3.0] 2023/11/07

- Added support for Bluetooth operations on iOS:
    - Bluetooth status checking.
    - Emitting current Bluetooth status.
    - Bluetooth device scanning.
    - Bluetooth device connection handling.
    - Bluetooth service and characteristic discovery and subscription.
    - Reading from Bluetooth characteristics.
    - Writing to Bluetooth characteristics.
    - Terminating a connection to a BLE device.
- Added iOS support to the example application.
- Comprehensive documentation for iOS functionality.
- Added extensive usage/tutorials content to README.

## [0.4.0] 2023/11/08

- Fixed linter issues
- Updated documentation, especially around handling of streams

## [0.4.1] 2023/11/08

- Cosmetic updates to README

## [0.4.2] 2023/11/08

- README updates

## [0.5.0] 2023/11/17

- Updated example app
- Wrote extensive tutorial article

## [0.6.0] 2023/12/16

- Updated dependencies
- Updated scan filtering by UUID

## [0.7.0] 2023/01/11

- Updated dependencies
- Updated documentation
- Updated formatting to meet Dart standards

## [0.8.0] 2023/01/15

- Clear scan results when restarting BLE scan
- Updated documentation for example app

## [0.9.0] 2024/05/23

- Updated Bluetooth permissions handling process
- Updated documentation

## [0.10.0] 2024/05/24

- Re-formatted project according to Dart standards

## [0.11.0] 2024/05/31

- Added ability to filter scans by service UUIDs on macOS
- Added content to the README about configuring and requesting permissions

## [0.11.1] 2024/06/02

- Updated Dartdoc references

## [0.11.2] 2024/06/11

- Updated documentation

## [0.11.3] 2024/06/14

- Updated documentation

## [0.12.0] 2024/08/24

- Updated lint rules for example
- Updated lint rules for plugin
- Updated documentation
- Updated characteristic interaction UI

## [0.13.0] 2024/08/31

- Added method to get connected Bluetooth devices (currently only for iOS and macOS)

## [0.14.0] 2025/01/25

- Created a new documentation site using Docusaurus: https://splendid-ble.web.app/
- Updated handling of scan filters on Android

## [0.15.0] 2025/02/10

- Added support for scanning BLE peripherals capable of accepting scan requests. Devices like this
  may spread their advertising data over multiple packets. This change allows app using this plugin
  to get the full data for this type of device.
- Updated documentation

### Breaking Changes
- Manufacturer data for the `BleDevice` class is now represented by a custom class rather than a string; this is the `ManufacturerData` class.
  - If you wish to continue using the manufacturer data as a string, you can use `manufacturerData.payload` to get the raw data.

## [0.16.0] 2025/04/07

- Added support for scanning BLE peripherals capable of accepting scan requests on macOS platforms.

## [0.16.1] 2025/04/19

- Updated Android Gradle plugin version and dependencies

## [0.16.2] 2025/06/14

- Updated example app localization dependencies
- Fixed scan filtering by UUID for Android

## [0.17.0] 2025/06/29

- Updated filtering devices by name
- Updated filtering devices by vendor ID
- Updated filtering devices by manufacturer data
- Added Bluetooth mocking tools for testing purposes
- Added integration tests for the example app as references

## [0.18.0] 2025/09/23

- Updated Method Channel calls to be asynchronous
  - Async Method Channel calls allow for more robust error handling 

## [0.19.0] 2025/11/28

- Implemented native Android Bluetooth permission handling
  - Added `BluetoothPermissionsHandler` class for Android platform
  - Automatic permission selection based on Android version (API 23-34)
  - Android 12+ (API 31+): Requests BLUETOOTH_SCAN and BLUETOOTH_CONNECT permissions
  - Android 10-11 (API 29-30): Requests ACCESS_FINE_LOCATION permission
  - Android 6-9 (API 23-28): Requests ACCESS_FINE_LOCATION permission
- Fixed `MissingPluginException` for `requestBluetoothPermissions` and `emitCurrentPermissionStatus` on Android
- Updated `FlutterSplendidBlePlugin` to implement `ActivityAware` for proper permission request handling
- Fixed race condition in permission status emission to ensure listeners receive initial values
- Updated AndroidManifest.xml with version-specific permission declarations
- Updated example app to demonstrate proper permission request flow
- Added unit tests for permission methods

### Breaking Changes
- Android apps must now declare Bluetooth permissions in their AndroidManifest.xml (see documentation)

## [0.20.0] 2025/12/30

- Enhanced Android BLE write operations with improved reliability and asynchronous handling
  - Implemented sequential write operation queue to prevent race conditions
  - Added completion feedback for successful write operations
  - Updated Method Channel to return results after write operations complete
  - Improved error handling for Android API 33+
- Fixed UUID filtering for BLE device scanning on Android
- Fixed service UUID reporting accuracy on iOS
- Code cleanup and optimization for better performance
- Updated documentation for improved clarity

## [1.0.0] 2026/01/22

### Platform Synchronization
- Synchronized BLE APIs across Android, iOS, and macOS platforms for consistent behavior
- Unified scan response handling across all platforms
- Standardized manufacturer data reporting format
- Consistent UUID filtering implementation delegated to Dart layer for cross-platform reliability
- Updated iOS scan response handling to properly aggregate advertising and scan response data
- Improved macOS deployment target compatibility

### Enhanced BLE Operations
- Implemented MTU negotiation immediately after connection establishment for optimal data transfer
- Added support for characteristic indications in addition to notifications
- Enhanced descriptor write operations with proper completion awaiting
- Improved subscription/unsubscription reliability with confirmation waiting
- Added method to monitor device connection state changes in real-time
- Enhanced disconnect handling and connection state management

### Testing Infrastructure
- Created comprehensive ESP32-based BLE test device firmware for hardware-in-the-loop testing
  - Implements multiple test characteristics (read, write, notify, indicate, encrypted, MITM)
  - Provides manufacturer data in both advertisement and scan response packets
  - Visual feedback via LED matrix for connection status
  - Standardized test service with known UUIDs for validation
- Developed dedicated test application for systematic BLE functionality validation
  - Automated test suite covering all plugin capabilities
  - Real-time test result reporting with pass/fail indicators
  - Tests for scanning, connection, service discovery, read/write operations, notifications, and pairing
  - Cross-platform validation (Android, iOS, macOS)
- Added Makefile commands for firmware building and flashing
- Integrated ESP32 test firmware as Git submodule

### Reliability Improvements
- Enhanced permission and adapter status checking logic
- Improved error handling throughout the plugin
- Code cleanup and optimization across all platform implementations
- Better handling of edge cases in BLE operations

### Developer Experience
- Comprehensive hardware-in-the-loop testing capability
- Clear visual feedback for test results
- Detailed logging for debugging
- Improved documentation for testing procedures

### Breaking Changes
None - this release maintains backward compatibility with 0.x versions while adding new capabilities.

