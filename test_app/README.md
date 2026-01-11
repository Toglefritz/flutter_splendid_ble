# Flutter Splendid BLE Test App

A manual testing application for the Flutter Splendid BLE plugin. This app runs like a regular Flutter application but performs systematic end-to-end testing of BLE functionality with the ESP32 test device.

## Purpose

This test app provides a practical alternative to automated integration tests for BLE functionality that requires system-level interactions (like pairing dialogs). Instead of trying to automate system prompts, the app allows a human tester to accept pairing dialogs naturally while the app performs automated testing.

## How It Works

The app runs a series of BLE tests against the ESP32 test device:

1. **Device Discovery** - Scans for and identifies the ESP32 test device
2. **Connection** - Connects to the device (user accepts any pairing prompts)
3. **Service Discovery** - Discovers available BLE services and characteristics
4. **Read Operations** - Tests reading from various characteristics
5. **Write Operations** - Tests writing data to characteristics
6. **Notifications** - Tests subscribing to and receiving notifications
7. **Large Data Transfer** - Tests MTU negotiation and large data handling
8. **Error Handling** - Tests invalid operations and error responses

Each test displays real-time results with pass/fail status and detailed information.

## Prerequisites

### Hardware
- ESP32 BLE test device (M5 Stack ATOM Matrix recommended)
- ESP32 must be running the BLE test firmware
- Mobile device with Bluetooth capability

### Setup
1. Power on the ESP32 test device
2. Verify it's advertising (LED matrix shows pulsing blue)
3. Enable Bluetooth on your mobile device

## Running Tests

1. Install dependencies:
   ```bash
   flutter pub get
   ```

2. Run the application:
   ```bash
   flutter run
   ```

3. In the app:
   - Tap "Start BLE Tests" to begin the test suite
   - Accept any system pairing dialogs when prompted
   - Watch test results appear in real-time
   - Review the final test report

## Test Results

The app provides:
- **Real-time progress** - See each test as it runs
- **Pass/fail indicators** - Clear visual feedback for each test
- **Detailed logs** - Technical details for debugging
- **Summary report** - Overall test results and any failures
