# Flutter Splendid BLE - Hardware-in-the-Loop Integration Tests

This directory contains integration tests for the Flutter Splendid BLE plugin that use a physical ESP32 BLE test device for hardware-in-the-loop (HIL) testing. These tests validate real-world BLE functionality by communicating with an actual BLE peripheral device.

## Overview

Hardware-in-the-loop testing provides several critical advantages over mocked or simulated BLE testing:

- **Real BLE Stack Behavior**: Tests interact with actual BLE hardware and protocol stacks
- **Platform-Specific Validation**: Verifies behavior across different mobile platforms (Android/iOS)
- **Timing and Concurrency**: Tests real-world timing constraints and concurrent operations
- **MTU and Data Transfer**: Validates actual data transfer limits and chunking behavior
- **Connection Management**: Tests real connection establishment, maintenance, and recovery

## ESP32 BLE Test Device

### Hardware Requirements

- **Device**: M5 Stack ATOM Matrix (ESP32-PICO-D4)
- **Connectivity**: USB-C for programming and power
- **Visual Feedback**: 5x5 RGB LED matrix for status indication

### Firmware Capabilities

The ESP32 test device runs custom firmware that provides a standardized BLE peripheral with the following service and characteristics:

#### Test Service
- **UUID**: `10000000-1234-1234-1234-123456789abc`
- **Purpose**: Primary service containing all test characteristics

#### Characteristics

1. **Read/Write Characteristic**
   - **UUID**: `10000001-1234-1234-1234-123456789abc`
   - **Properties**: Read, Write
   - **Default Value**: `"Hello BLE"`
   - **Purpose**: Basic read/write operations testing

2. **Read-Only Characteristic**
   - **UUID**: `10000002-1234-1234-1234-123456789abc`
   - **Properties**: Read
   - **Value**: `"ESP32-BLE-Tester v1.0"`
   - **Purpose**: Read-only access validation

3. **Write-Only Characteristic**
   - **UUID**: `10000003-1234-1234-1234-123456789abc`
   - **Properties**: Write
   - **Purpose**: Command processing and write-only validation
   - **Commands**:
     - `"ping"` → Responds with "pong" in serial output
     - `"status"` → Responds with "Device is running"
     - Other values → "Unknown command"

4. **Notify Characteristic**
   - **UUID**: `10000004-1234-1234-1234-123456789abc`
   - **Properties**: Notify
   - **Behavior**: Sends `"Counter: X"` every 3 seconds when subscribed
   - **Purpose**: Notification and subscription testing

5. **Large Data Characteristic**
   - **UUID**: `10000005-1234-1234-1234-123456789abc`
   - **Properties**: Read, Write
   - **Value**: ~500-byte test string for MTU testing
   - **Purpose**: Large data transfer and MTU negotiation testing

### Visual Status Indicators

The LED matrix provides real-time feedback about the device state:

- **Pulsing Blue**: Advertising and ready for connections
- **Solid Green**: Connected to a BLE client
- **Red**: Error state

## Test Environment Setup

### Prerequisites

1. **ESP32 Test Device**: Programmed with the BLE test firmware
2. **Mobile Device**: Android or iOS device with BLE capability
3. **Development Environment**: Flutter development setup with integration test support

### Device Preparation

1. **Flash Firmware**: Program the ESP32 with the BLE test firmware
2. **Power On**: Connect via USB-C or battery power
3. **Verify Status**: LED matrix should show pulsing blue (advertising)
4. **Serial Monitor**: Optional - connect serial monitor for debugging

### Test Device Discovery

The integration tests will discover the ESP32 device using:
- **Device Name**: `"SplendidBLE-Tester"`
- **Service UUID**: `10000000-1234-1234-1234-123456789abc`

## Integration Test Structure

### Test Categories

1. **Device Discovery Tests**
   - Scan for BLE devices
   - Filter by device name and service UUID
   - Validate advertised service data

2. **Connection Management Tests**
   - Establish BLE connection
   - Handle connection state changes
   - Test connection recovery after disconnection
   - Validate connection timeout behavior

3. **Service Discovery Tests**
   - Discover primary service
   - Enumerate all characteristics
   - Validate characteristic properties
   - Test service caching behavior

4. **Read Operations Tests**
   - Read from read/write characteristic
   - Read from read-only characteristic
   - Attempt invalid reads (write-only characteristic)
   - Test concurrent read operations

5. **Write Operations Tests**
   - Write to read/write characteristic
   - Write to write-only characteristic
   - Attempt invalid writes (read-only characteristic)
   - Test write response handling

6. **Notification Tests**
   - Subscribe to notifications
   - Receive periodic notifications
   - Unsubscribe from notifications
   - Test notification reliability

7. **Large Data Transfer Tests**
   - Read large data characteristic (~500 bytes)
   - Write large data to characteristic
   - Test MTU negotiation
   - Validate data integrity

8. **Error Handling Tests**
   - Invalid characteristic UUIDs
   - Operations on disconnected device
   - Timeout scenarios
   - Permission violations
