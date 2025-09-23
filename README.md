# FlutterSplendidBLE: Flutter Bluetooth Low Energy (BLE) Plugin

<p align="center">
<image src="https://github.com/Toglefritz/flutter_splendid_ble/blob/main/assets/flutter_splendid_ble_logo.png?raw=true" alt="flutter_splendid_ble plugin logo" width="200"></image></p>

The Flutter Splendid BLE plugin offers a robust suite of functionalities for Bluetooth Low Energy (
BLE) interactions in Flutter applications. It allows Flutter apps to use Bluetooth for interacting
with peripheral devices. This includes scanning for and connecting to BLE peripherals, managing
bonding processes, writing and reading values, subscribing to BLE characteristics, and more. This
plugin provides a comprehensive tool for versatile BLE operations.

[![pub package](https://img.shields.io/pub/v/flutter_splendid_ble.svg)](https://pub.dev/packages/flutter_splendid_ble)
[![style: very good analysis](https://img.shields.io/badge/style-very_good_analysis-B22C89.svg)](https://pub.dev/packages/very_good_analysis)

## Quick Start Guide

This guide provides a streamlined setup process to help you quickly integrate the Flutter Splendid
BLE plugin into your project and perform essential Bluetooth Low Energy (BLE) operations. For more
advanced use cases and configurations, refer to the full documentation on the
[Flutter Splendid BLE Documentation Site](https://splendid-ble.web.app/)

## Testing

The Flutter Splendid BLE plugin includes robust testing capabilities to support reliable development
workflows. It provides a `FakeCentralMethodChannel` implementation that allows developers to simulate
Bluetooth scanning, connection states, characteristic read/write operations, and more, entirely in a
test environment without requiring physical BLE hardware. These tools are designed to make it easy
to write both unit and integration tests that validate application logic under realistic BLE
scenarios. For detailed instructions and examples, refer to the TESTING.md file in this repository.

### **Step 1**: Set Up Your Flutter Project

If you haven’t already, create a new Flutter project:

```bash
flutter create splendid_ble_demo
cd splendid_ble_demo
```

Add the flutter_splendid_ble dependency to your pubspec.yaml:

```
dependencies:
  flutter_splendid_ble: ^0.17.0
```

Run:

```bash
flutter pub get
```

### **Step 2**: Configure Platform-Specific Settings

#### Android Configuration

Modify your android/app/src/main/AndroidManifest.xml to include the necessary BLE permissions:

```xml

<uses-permission android:name="android.permission.BLUETOOTH" /><uses-permission
android:name="android.permission.BLUETOOTH_ADMIN" /><uses-permission
android:name="android.permission.ACCESS_FINE_LOCATION" /><uses-permission
android:name="android.permission.BLUETOOTH_SCAN" /><uses-permission
android:name="android.permission.BLUETOOTH_CONNECT" />

<uses-feature android:name="android.hardware.bluetooth" /><uses-feature
android:name="android.hardware.bluetooth_le" android:required="true" />
```

#### iOS/macOS Configuration

Edit your ios/Runner/Info.plist:

```xml

<key>NSBluetoothAlwaysUsageDescription</key><string>This app requires Bluetooth to connect to BLE
devices.
</string>

<key>NSBluetoothPeripheralUsageDescription</key><string>This app communicates with BLE
peripherals.
</string>

<key>NSBluetoothAlwaysAndWhenInUseUsageDescription</key><string>This app requires Bluetooth access
at all times.
</string>
```

Enable background modes for Bluetooth by going to Xcode → Signing & Capabilities → Background Modes,
then enable:

- Uses Bluetooth LE accessories
- Acts as a Bluetooth LE accessory

### **Step 3**: Scan for BLE Devices

Start scanning for nearby BLE devices:

```dart
import 'dart:async';

/// A StreamSubscription used to listen for discovered BLE devices.
StreamSubscription<BleDevice>? scanSubscription;

/// Start scanning for nearby devices.
void startScan() async {
  final Stream<BleDevice> scanStream = await bleCentral.startScan();
  scanSubscription = scanStream.listen(
        (device) {
      print('Discovered device: ${device.name} (${device.address})');
    },
    onError: (error) {
      print('Scan error: $error');
    },
  );
}

/// Stop the scan when it's no longer needed.
void stopScan() {
  scanSubscription?.cancel();
}
```

### **Step 4**: Connect to a BLE Device

Once a device is discovered, you can initiate a connection:

```dart
/// A StreamSubscription used to listen for connection state updates.
StreamSubscription<BleConnectionState>? connectionSubscription;

/// Connect to a BLE device.
void connectToDevice(BleDevice device) async {
  final Stream<BleConnectionState> connectionStream = await bleCentral.connect(deviceAddress: device.address);
  connectionSubscription = connectionStream.listen(
        (state) {
      print('Connection state: $state');
    },
    onError: (error) {
      print('Connection error: $error');
    },
  );
}

/// Disconnect from the device when done.
void disconnectFromDevice(BleDevice device) {
  bleCentral.disconnect(device.address);
  connectionSubscription?.cancel();
}
```

### **Step 5**: Write to a BLE Characteristic

Writing data to a characteristic (e.g., sending a command to a device):

```dart
/// Write a value to a BLE characteristic.
Future<void> writeCharacteristic(BleCharacteristic characteristic, String value) async {
  await bleCentral.writeCharacteristic(
    characteristic: characteristic,
    value: value,
  );
  print('Wrote: $value');
}
```

### **Step 6**: Read from a BLE Characteristic

Reading data from a characteristic (e.g., retrieving sensor data):

```dart
/// Read a value from a BLE characteristic.
Future<void> readCharacteristic(BleCharacteristic characteristic) async {
  BleCharacteristicValue value = await bleCentral.readCharacteristic(
    characteristic: characteristic,
    timeout: Duration(seconds: 10),
  );
  String result = String.fromCharCodes(value.value); // Convert bytes to string
  print('Read: $result');
}
```

### Final Notes

- Always request permissions before starting any BLE operations.
- Stop scanning once a device is found to save battery.
- Handle connection states properly, including disconnecting when done.
- Some characteristics may require specific permissions or authentication to read/write.

## Detailed Documentation Table of Contents

- [Features](#features)
- [Main Goals](#main-goals)
- [Documentation Site](#documentation-site)
- [Installation](#installation)
- [Prerequisites](#prerequisites)
    - [iOS/macOS Prerequisites](#iosmacos-prerequisites)
    - [Android Prerequisites](#android-prerequisites)
- [Usage](#usage)
    - [Initializing the Plugin](#initializing-the-plugin)
    - [Requesting Bluetooth Permissions](#requesting-bluetooth-permissions)
    - [Checking the Bluetooth Adapter Status](#checking-the-bluetooth-adapter-status)
    - [Getting Connected Bluetooth Devices](#getting-connected-bluetooth-devices)
    - [Starting a Bluetooth Scan for Detecting Nearby BLE Devices](#starting-a-bluetooth-scan-for-detecting-nearby-ble-devices)
    - [Connecting to a Bluetooth Device](#connecting-to-a-bluetooth-device)
    - [Performing Service/Characteristic Discovery on a BLE Peripheral](#performing-servicecharacteristic-discovery-on-a-ble-peripheral)
    - [Subscribing to BLE Characteristic Notifications/Indications](#subscribing-to-ble-characteristic-notificationsindications)
    - [Writing Values to a BLE Characteristic](#writing-values-to-a-ble-characteristic)
    - [Reading Values from a BLE Characteristic](#reading-values-from-a-ble-characteristic)
    - [Disconnecting from a BLE Peripheral](#disconnecting-from-a-ble-peripheral)
- [Tutorial Article](#tutorial-article)
- [Error Handling](#error-handling)
- [Viewing Documentation Locally](#viewing-documentation-locally)
- [Feedback and Contributions](#feedback-and-contributions)
- [License](#license)
- [Disclaimer](#disclaimer)

## Features

This plugin allows a Flutter app to act as a BLE central device. It is designed for scenarios where
the app scans for, connects to, and interacts with BLE peripheral devices. Key functionalities
include:

- Scanning for BLE devices and filtering results.
- Establishing and managing connections with peripherals.
- Reading from and writing to BLE characteristics.
- Subscribing to notifications or indications from peripherals.

**Example Use-Cases:**

- A smart home app managing BLE-enabled IoT devices.
- A fitness app connecting to BLE heart rate monitors.
- A navigation app that connects to BLE cycling computers or wearables for real-time data tracking
  and guidance.

## Main Goals

1. **Efficient Toolset**: The primary objective is to provide developers with an efficient set of
   tools for BLE interactions, reducing the need to rely on multiple libraries or native code.

2. **Best Practices**: The plugin is developed following all Flutter and Dart best practices,
   ensuring smooth integration into any Flutter project and consistency with the broader Flutter
   ecosystem.

3. **Best-in-class Documentation**: Good software should be accompanied by excellent documentation.
   As such, every class, variable, and method in this plugin is accompanied by detailed and
   easy-to-understand documentation to aid developers at all levels in leveraging the full potential
   of this plugin.

## Features

- Scan for available BLE devices.
- Connect to a BLE device.
- Manage the bonding process.
- Read from and write to BLE characteristics.
- Subscribe to characteristics via notifications or indications.
- Disconnect from a BLE device.
- Handle connection errors and other exceptions.
- Monitor connection status and other state changes.
- Have a really good time.

## Documentation Site

For detailed documentation and other information, visit
the [Flutter Splendid BLE Documentation Site](https://splendid-ble.web.app/).

## Installation

First, add the following line to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_splendid_ble: ^0.15.0
```

Then run:

```
flutter pub get
```

In the files in which you wish to use the plugin, import it by adding:

```dart
import 'package:flutter_splendid_ble/splendid_ble.dart';
```

## Prerequisites

Before using the *flutter_splendid_ble* plugin in your Flutter project, you need to ensure that the
necessary configurations are in place for the iOS/macOS and Android platforms, depending upon which
platforms your Flutter app will be targeting. This section details the required prerequisites for
each platform.

### **iOS/macOS Prerequisites**:

#### Info.plist Configuration

To use Bluetooth functionality in your Flutter app on iOS and macOS, you need to add specific
key/value pairs to your Info.plist files. These keys inform the system about your app’s usage of
Bluetooth and the reasons for accessing it. Below are the required keys and their descriptions:

1. NSBluetoothAlwaysUsageDescription (iOS only)

- Description: A message that tells the user why your app needs access to Bluetooth.
- Key: NSBluetoothAlwaysUsageDescription
- Example:

```xml

<key>NSBluetoothAlwaysUsageDescription</key><string>This app uses Bluetooth to connect to external
devices.
</string>
```

2. NSBluetoothPeripheralUsageDescription (iOS only)

- Description: A message that tells the user why your app needs to act as a Bluetooth peripheral.
- Key: NSBluetoothPeripheralUsageDescription
- Example:

```xml

<key>NSBluetoothPeripheralUsageDescription</key><string>This app uses Bluetooth to communicate with
external peripherals.
</string>
```

3. NSBluetoothAlwaysAndWhenInUseUsageDescription (macOS only)

- Description: A message that informs the user why your app needs Bluetooth access both when the app
  is in use and in the background.
- Key: NSBluetoothAlwaysAndWhenInUseUsageDescription
- Example:

```xml

<key>NSBluetoothAlwaysAndWhenInUseUsageDescription</key><string>This app uses Bluetooth to connect
to external devices at all times.
</string>
```

#### Adding Capabilities

Ensure that your project has the necessary capabilities enabled to use Bluetooth features:

1. Background Modes (iOS only)
    - Enable the Uses Bluetooth LE accessories and Acts as a Bluetooth LE accessory options in the
      Background Modes section of your project's target capabilities.
2. App Sandbox (macOS only)
    - Enable the Bluetooth entitlement in the App Sandbox section of your project's target
      capabilities.

### **Android Prerequisites**:

To use Bluetooth functionality in your Flutter app on Android, you need to declare specific
permissions and features in your AndroidManifest.xml file. Additionally, you may need to request
runtime permissions if targeting Android 6.0 (API level 23) or higher.

#### AndroidManifest.xml Configuration

To use Bluetooth functionality in your Flutter app on Android, you need to declare specific
permissions and features in your AndroidManifest.xml file. Additionally, you may need to request
runtime permissions if targeting Android 6.0 (API level 23) or higher.

#### AndroidManifest.xml Configuration

1. Permissions

- BLUETOOTH

```xml

<uses-permission android:name="android.permission.BLUETOOTH" />
```

- BLUETOOTH_ADMIN

```xml

<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
```

- ACCESS_FINE_LOCATION (Required for scanning Bluetooth devices)

```xml

<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

- BLUETOOTH_SCAN (For Android 12 and above)

```xml

<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
```

- BLUETOOTH_CONNECT (For Android 12 and above)

```xml

<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
```

2. Features

- Bluetooth

```xml

<uses-feature android:name="android.hardware.bluetooth" />
```

- Bluetooth LE

```xml

<uses-feature android:name="android.hardware.bluetooth_le" android:required="true" />
```

## Usage

### **Initializing the Plugin**:

All Bluetooth functionality provided by this plugin goes through either the `SplendidBleCentral`
class (which is also aliased as `SplendidBle` for backwards compatibility). So, wherever you need
to conduct Bluetooth operations, you will need an instance of this class.

```dart
import 'package:flutter_splendid_ble/splendid_ble_plugin.dart';

final SplendidBleCentral bleCentral = SplendidBleCentral();
```

You could simply instantiate the `SplendidBleCentral` class in each Dart class where Bluetooth
functionality is needed or, depending upon your needs and the architecture of your application, you
could create a centralized service where these instances are created once and referenced from
everywhere else in your codebase. Some of the examples below show a service class being used to wrap
functionality provided by this plugin.

### **Requesting Bluetooth Permissions**:

If targeting Android 6.0 (API level 23) or higher, you need to request the necessary Bluetooth
permissions at runtime. If targeting iOS, Bluetooth permissions must always be requested. This is
required before performing any Bluetooth related actions, including checking the state of the
Bluetooth adapter (described below). Here is an example of how to request permissions in your
Flutter app:

**Example**

```dart
/// A [SplendidBleCentral] instance used to access BLE functionality.
final SplendidBleCentral _ble = SplendidBleCentral();

/// A [StreamSubscription] used to listen for changes in the state of the Bluetooth permissions 
/// on the host platform.
StreamSubscription<BluetoothPermissionStatus>? _bluetoothPermissionStream;

/// The current status of the Bluetooth permissions on the host platform, represented by the
/// [BluetoothPermissionStatus] enum.
BluetoothPermissionStatus? _bluetoothPermissionStatus;

/// Initializes Bluetooth permission status monitoring.
///
/// This method sets up a listener to monitor the current status of the Bluetooth permissions on the host platform.
void _initBluetoothPermissionStatusMonitor() {
  _bluetoothPermissionStream = _ble.emitCurrentPermissionStatus().listen(
        (status) {
      _bluetoothPermissionStatus = status;

      // Perform actions based on the Bluetooth permission status.
    },
    onError: (error) {
      // Handle any errors encountered while listening to permission status updates.
    },
  );

// Request Bluetooth permissions. If they have already been granted, this method will do nothing.
  _ble.requestBluetoothPermissions();
}

void dispose() {
  // Cancel the Bluetooth permission stream.
  _bluetoothPermissionStream?.cancel();

  super.dispose();
}
```

**Notes and Best Practices**

- Always request Bluetooth permissions before attempting to use any Bluetooth functionality.
- Depending upon the platform and operating system version, your app will only be allowed to request
  permissions a limited number of times. Typically, the app can request permissions only two times
  at maximum. If permissions are denied repeatedly, you may need to instruct the user to manually
  navigate to their device settings to grant the necessary permissions.
- Handle the different permission statuses (granted, denied, or unknown) to provide a good user
  experience.
- Ensure that the necessary permissions are declared in the AndroidManifest.xml file as described in
  the prerequisites section.
- Always dispose of any stream subscriptions when they are no longer needed to avoid memory leaks
  and unnecessary processing.

### **Checking the Bluetooth Adapter Status**:

Before you can use any Bluetooth functionality, you should ensure that the device's Bluetooth
adapter is ready. This step is crucial because attempting to use Bluetooth features when the adapter
is not available or turned off will lead to failures and a poor user experience.

In the example below, the method, `_checkAdapterStatus`, is responsible for setting up a listener
for the state of the host device's Bluetooth adapter. It uses a stream (`_bluetoothStatusStream`)
which emits the current status of the Bluetooth adapter.

The possible states of the Bluetooth adapter are defined in the `BluetoothStatus` enum, which
includes three possible states:

- `enabled`: The adapter is on and available for use.
- `disabled`: The adapter is off and needs to be enabled before proceeding.
- `notAvailable`: The device does not have a Bluetooth adapter.

Here's how you might perform this check:

1. Subscribe to a stream provided by the Splendid BLE plugin that monitors the Bluetooth adapter's
   status.
2. When the status is emitted, update your app's state with the new Bluetooth status.
3. Based on the received status, you can control the flow of your app — e.g., prompt the user to
   turn on Bluetooth if it's off, show a message if the device doesn't support Bluetooth, or proceed
   with the Bluetooth operations if it's on.
4. Always handle exceptions. If an error occurs while trying to check the Bluetooth status, you
   should catch the exception and update the app's state accordingly, which might involve setting
   the status to `notAvailable` or showing an error message to the user.

Including a robust status check at the beginning of your Bluetooth workflow ensures that all
subsequent operations have a higher chance of success and that your app behaves predictably in the
face of changing conditions.

**Example**

```dart
import 'dart:async';

/// [SplendidBleCentral] instance providing BLE functionality. 
final SplendidBleCentral _ble = SplendidBleCentral();

/// A [StreamSubscription] used to listen for changes in the state of the Bluetooth adapter.
StreamSubscription<BluetoothStatus>? _bluetoothStatusStream;

/// Initializes Bluetooth status monitoring.
void initBluetoothStatusMonitor() {
  _checkAdapterStatus();
}

/// Initializes Bluetooth status monitoring.
///
/// This method sets up a listener to monitor the current status of the Bluetooth adapter. It is typically called
/// during the initialization phase of the app or when Bluetooth monitoring is required.
void _checkAdapterStatus() async {
  _bluetoothStatusStream = _ble.emitCurrentBluetoothStatus().listen(
          (status) {
        // Update your UI or logic based on the Bluetooth status.
      },
      onError: (error) {
        // Handle any errors encountered while listening to status updates.
      }
  );
}

/// Dispose stream subscription when it's no longer needed to prevent memory leaks.
void dispose() {
  _bluetoothStatusStream?.cancel();
}
```

**Notes and Best Practices**

- Remember to dispose of any stream subscriptions when they are no longer needed to avoid memory
  leaks and unnecessary processing.

### **Getting Connected Bluetooth Devices**:

In some cases, a Bluetooth device with which you want to interact may already be connected to the
host device. In such scenarios, you may want to retrieve a list of connected devices to check if the
desired device is already connected or to display a list of connected devices to the user. You might
also append (or prepend) the connected devices to the list of discovered devices during a
Bluetooth scan to ensure that the user can see all available devices, including those that are
already connected.

The example below demonstrates how to retrieve a list of connected Bluetooth devices. For each
device, the name and address are returned. This information is represented by objects of the
`ConnectedBluetoothDevice` class.

**Example**

```dart
/// Get a list of Bluetooth devices that are currently connected to the host device.
// TODO: replace the service UUID with a value from your own system
Future<void> _getConnectedDevices() async {
  try {
    final List<ConnectedBleDevice> devices = await _ble.getConnectedDevices(
        ['abcd1234-1234-1234-1234-1234567890aa']);

    debugPrint('Connected devices: $connectedDevices');

    // TODO: use the list of devices as needed
  } on BluetoothScanException catch (e) {
    _showErrorMessage(e.message);
  }
}
```

**Notes and Best Practices**

- On iOS, the identifiers returned for each connected Bluetooth device are UUID values that are
  specific to each iOS device. Therefore, if your app needs the ability to identify particular
  Bluetooth devices across multiple iOS devices, you may need to maintain a mapping of iOS UUID
  values and other values, such as Bluetooth device BDAs or names.
- On iOS and macOS, a list of service UUIDs must be provided to the `getConnectedDevices` method.
  These platforms do not support getting a list of all connected devices. Rather, a service UUID
  must be provided to filter the list of connected devices.

### **Starting a Bluetooth Scan for Detecting Nearby BLE Devices**:

Scanning for nearby Bluetooth Low Energy (BLE) devices is a fundamental feature for BLE-enabled
applications. It's important to conduct these scans responsibly to balance the need for device
discovery against the impact on battery life and user privacy.

Below is a guide and example code snippet for starting a Bluetooth device scan:

**Prerequisites**
Ensure that you have already checked the Bluetooth adapter status as shown above to ensure that
Bluetooth is turned on and available for scanning. You should also handle the necessary permissions
for Bluetooth usage as required by the platform (e.g., location permissions for Android).

**Starting the Scan**
In the example below, the `_startBluetoothScan` method is responsible for initiating a scan for BLE
devices. It uses the Splendid BLE plugin's scanning method, which typically takes filters and
settings as parameters to customize the scan behavior.

- *filters*: This parameter allows you to specify the criteria for devices to be discovered. For
  example, you can filter by service UUIDs, device name, etc.
- *settings*: This parameter allows you to define the scan settings, such as scan mode (low power,
  balanced, low latency), scan duration, and whether to allow duplicates.

**Handling Discovered Devices**
When a BLE device is discovered, the scan stream emits device information. The '_onDeviceDetected'
method is then called with this device information, allowing you to handle new devices as needed
(e.g., updating the UI, starting a connection, or reading services and characteristics).

**Example**

```dart
import 'dart:async';

/// [SplendidBleCentral] instance as discussed above.
final SplendidBleCentral _ble = SplendidBleCentral();

/// A [StreamSubscription] used to listen for newly discovered BLE devices.
StreamSubscription<BleDevice>? _scanStream;

/// Begins a scan for nearby BLE devices.
void _startBluetoothScan() async {
// Assuming `filters` and `settings` are already defined and passed to the widget.
  final Stream<BleDevice> scanStream = await _ble.startScan(filters: filters, settings: settings);
  _scanStream = scanStream.listen((device) => _onDeviceDetected(device), onError: _handleScanError);
}

/// Called when a new device is detected by the Bluetooth scan.
void _onDeviceDetected(BleDevice device) {
  // Handle the discovered device, e.g., by updating a list or attempting a connection.
}

/// Handles any errors that occur during the scan.
void _handleScanError(Object error) {
  // Handle scan error, possibly by stopping the scan, reporting the error, and updating the UI.
}

/// Stops the Bluetooth scan.
Future<void> stopScan() async {
  try {
    await _ble.stopScan();
    // Handle successful scan stop if necessary.
  } on BluetoothScanException catch (e) {
    // Handle the exception, possibly by showing an error message to the user.
  }
}

/// Disposes of the stream subscription when it's no longer needed to prevent memory leaks.
void dispose() {
  _scanStream?.cancel();
}
```

**Notes and Best Practices**

- Always remember to stop the scan once you have found the necessary devices or after a certain
  timeout to save battery life.
- Remember to dispose of any stream subscriptions when the scanning is no longer needed to avoid
  memory leaks and unnecessary processing.

### **Connecting to a Bluetooth Device**:

Establishing a connection with a Bluetooth Low Energy (BLE) device is a key step to enable
communication for data transfer and device interaction. The process of connecting to a BLE device
typically involves using the device's address obtained from the discovery scan.

Below is a guide and example code snippet for connecting to a BLE device:

**Prerequisites**
Ensure you have successfully discovered BLE devices and have access to the device address.
Additionally, ensure the user has granted any permissions necessary for connecting to a Bluetooth
device.

**Initiating a Connection**
To connect to a BLE device, you will use the `connect` method provided by the Splendid BLE plugin.
This method requires the address of the device, which is usually obtained from the discovery
process.

- *deviceAddress*: The address of the BLE device you wish to connect to. This is a unique identifier
  for the BLE device. Note that this address is handled differently by Android/Windows/Linux devices
  compared with iOS and MacOS devices. On the former set of operating systems, BLE devices are
  identified by their Bluetooth MAC addresses. However, on Apple devices, a BLE peripheral is
  instead identified by a unique UUID value. This value is not only unique per BLE device, but also
  unique per Apple device. In other words, the same Bluetooth peripheral discovered by two different
  Apple devices will have two different UUID identifiers.

**Connection State Updates**
Once the connection attempt has been initiated, the connect method will return a stream that emits
the connection state updates. You should listen to this stream to receive updates and handle them
accordingly.

- *onConnectionStateUpdate*: A callback function that will be called with the new connection state
  whenever it changes.

**Error Handling**
It is important to handle any exceptions that may occur during the connection attempt. This could be
due to the device being out of range, the device not being connectable, or other reasons.

**Example**

```dart
import 'dart:async';

/// [SplendidBleCentral] instance as discussed above.
final SplendidBleCentral _ble = SplendidBleCentral();

/// A [StreamSubscription] used to listen for changes in the connection status between the app and the [BleDevice].
StreamSubscription<BleConnectionState>? _connectionStream;

/// Attempt to connect to the [BleDevice].
void _connectToDevice(BleDevice device) async {
  try {
    final Stream<BleConnectionState> connectionStream = await _ble.connect(deviceAddress: device.address);
    _connectionStream = connectionStream.listen(
      _onConnectionStateUpdate,
    );
  } catch (e) {
    debugPrint('Failed to connect to device, ${device.address}, with exception, $e');

    _handleConnectionError(e);
  }
}

/// Handles errors resulting from an attempt to connect to a peripheral.
void _handleConnectionError(Object error) {
  // Handle errors in connecting to a peripheral.
}

/// Called when the connection state is updated.
void _onConnectionStateUpdate(BleConnectionState state) {
  // Handle the updated connection state, e.g., by updating the UI or starting service discovery.
}

void dispose() {
  // Cancel the connection state stream.
  _connectionStream?.cancel();
}
```

**Notes and Best Practices**

- After a successful connection, you may want to perform service discovery to interact with the BLE
  device further. See the next section for a description of this process.
- Always implement disconnection logic to properly disconnect from the BLE device when it's no
  longer needed.
- Implement timeout logic for connection attempts to handle scenarios where a device is not
  responding.
- Remember to handle the various states of the connection such as connecting, connected,
  disconnecting, and disconnected.

### **Performing Service/Characteristic Discovery on a BLE Peripheral**:

After establishing a connection with a Bluetooth Low Energy (BLE) device, the next step is to
discover the services and characteristics offered by the peripheral. This process is crucial for
determining how to interact with the device, as services and characteristics define the
functionalities available.

**Understanding Service Discovery**

- *Service*: A collection of characteristics and relationships to other services that encapsulate
  the behavior of part of a device.
- *Characteristic*: A data value transferred between client and server, e.g., a sensor reading or a
  control point.

**Initiating Service Discovery**
Service discovery is initiated once a connection with a BLE device has been successfully
established. Service discovery is performed by calling the `discoverServices` method from the
Splendid BLE plugin.

**Example**

```dart
import 'dart:async';

/// SplendidBleCentral instance as discussed above.
final SplendidBleCentral _ble = SplendidBleCentral();

/// A [StreamSubscription] used to listen for discovered services.
StreamSubscription<List<BleService>>? _servicesDiscoveredStream;

/// Starts the service discovery process for the connected BLE device.
// Replace `widget.device.address` with the Bluetooth address of your device
void startServiceDiscovery() async {
  final Stream<List<BleService>> servicesStream = await _ble.discoverServices(widget.device.address);
  _servicesDiscoveredStream = servicesStream.listen(
    _onServiceDiscovered,
  );
}

/// Called when services are discovered.
void _onServiceDiscovered(List<BleService> services) {
  // Process the discovered service.
}

/// Dispose method to cancel the subscription when it's no longer needed.
void dispose() {
  _servicesDiscoveredStream?.cancel();
}
```

**Notes and Best Practices**

- Discover all required services and characteristics after the connection is established to ensure
  they are available for use.
- Maintain a list or map of discovered services and characteristics for easy access during the
  application's lifecycle.
- Handle exceptions and errors gracefully to inform the user if service discovery cannot be
  completed.

### **Subscribing to BLE Characteristic Notifications/Indications**:

Bluetooth Low Energy (BLE) characteristics can be configured to notify or indicate a connected
device when their value changes. This is a powerful feature that allows a BLE peripheral to send
updates asynchronously to a central device without the central having to poll for changes. In other
words, subscribing to notifications or indications from a BLE characteristic is essential for
real-time communication in BLE applications.

When subscribing to BLE characteristic notifications or indications using the Splendid BLE plugin,
the
values you receive are instances of BleCharacteristicValue, which contain the raw data as List<int>.
This raw data format represents the bytes sent from the BLE device. For most applications, you will
need to convert these bytes into a more usable format such as a String, Map<String, dynamic> (if the
data is in JSON format), a list, an object, or even a Protocol Buffer (protobuf) if the application
uses them for structured data. See the "Data Conversion" section below for more details.

**Notifications vs. Indications**

- Notifications are a way for the BLE peripheral to inform the central of changes without expecting
  an acknowledgment.
- Indications are similar but require an acknowledgment from the central, providing a guaranteed
  delivery of the notification.

**Prerequisites**
Ensure that the `BLECharacteristic` supports either notifications or indications. Check the
characteristic's properties before attempting to subscribe.

**Setting Up Characteristic Subscription**
To listen for changes in a characteristic's value, you subscribe to the characteristic. When
subscribed, the BLE peripheral will start sending updates whenever the characteristic’s value
changes.

**Example**

```dart
import 'dart:async';
import 'package:flutter_splendid_ble/splendid_ble.dart';

SplendidBleCentral _blePlugin;

/// A [BLECharacteristic] instance for a characteristic that supports indications or
/// notifications.
BLECharacteristic _characteristic;

/// A [StreamSubscription] used to listen for updates in the value of a characteristic.
StreamSubscription<BleCharacteristicValue>? _characteristicValueListener;

/// Constructor accepts a SplendidBle instance and a BLECharacteristic instance.
BLECharacteristicListener(this._blePlugin, this._characteristic);

/// Subscribes to the characteristic updates.
void subscribeToCharacteristic() async {
  if (_characteristic.properties.notify || _characteristic.properties.indicate) {
    final Stream<BleCharacteristicValue> characteristicStream = await _blePlugin.subscribeToCharacteristic(_characteristic);
    _characteristicValueListener = characteristicStream.listen(
      _onCharacteristicChanged,
    );
  } else {
    print("The characteristic does not support notifications or indications.");
  }
}

/// Callback when the characteristic value changes.
void _onCharacteristicChanged(BleCharacteristicValue event) {
  // This is where you handle the incoming data.
  // The 'event' parameter contains the new characteristic value.

  // Add your handling code here.
}

/// Dispose method to cancel the subscription when it's no longer needed.
void dispose() {
  _characteristicValueListener?.cancel();
}
```

**Data Conversion**
The List<int> data received from the BLE characteristic often needs to be decoded or parsed. Here’s
how you can handle different scenarios:

- String: If the data represents a string, you might convert it using utf8.decode from Dart's dart:
  convert package.
- JSON: If the characteristic sends JSON formatted data, you would first convert the List<int> to a
  String, then use a JSON decoder to get a Map<String, dynamic>.
- Lists or Objects: If the data represents serialized structured data, you'll need to deserialize it
  into the corresponding Dart objects.
- Protocol Buffers: When using protobufs, you'll need to use the generated Dart code from your
  .proto files to decode the List<int> into a protobuf object.

**Example**

```dart
/// Converts the [BleCharacteristicValue] instance, containing BLE characteristic values in 
/// their raw, List<int> form, into more usable data structures.
void onCharacteristicChanged(BleCharacteristicValue event) {
  // Get the value from the event, which is a List<int>
  List<int> rawValue = event.value;

  // Example conversion to String
  String stringValue = utf8.decode(rawValue);
  print("String Value: $stringValue");

  // Example conversion to JSON
  try {
    Map<String, dynamic> jsonValue = json.decode(stringValue);
    print("JSON Value: $jsonValue");
  } catch (e) {
    print("Error decoding JSON: $e");
  }

  // Example conversion for protobuf (assuming 'MyProto' is a generated class from your .proto file)
  try {
    MyProto protoValue = MyProto.fromBuffer(rawValue);
    print("Protobuf Value: $protoValue");
  } catch (e) {
    print("Error decoding Protobuf: $e");
  }

  // Implement other conversions based on your application needs
}
```

**Notes and Best Practices**

- Always check if the characteristic supports notifications or indications before subscribing.
- Unsubscribe from the characteristic when it is no longer needed or when the UI is disposed to
  prevent memory leaks and unnecessary operations.
- Gracefully handle any potential errors or exceptions that may occur during subscription or when
  receiving data.
- When performing conversions, it's important to handle exceptions, as data corruption or unexpected
  formats can cause decoding errors.
- The structure of the data you're expecting to receive from the BLE characteristic will inform how
  you convert and use the data in your application.
- Always consult the documentation or specification for the BLE device you're communicating with to
  understand the data format.

### **Writing Values to a BLE Characteristic**:

Interacting with BLE devices often requires writing data to a characteristic to trigger certain
actions or configure settings on the peripheral. The 'SplendidBle' provides a 'writeValue'
method
on the 'BleCharacteristic' class to facilitate this.

When writing to a BLE characteristic, the data typically needs to be in a byte format (`List<int>`).
Depending on the characteristic's specification, this could be a simple string conversion,
serialized structured data, or even encoded protobuf objects.

**Data Preparation**
Before calling the `writeValue` method, you must convert your data into a List<int>. Here are common
scenarios:

- *String*: Convert the string to bytes using `utf8.encode` from Dart's dart:convert package.
- *JSON*: If you have a `Map<String, dynamic>`, you first serialize it into a string
  with `json.encode`, then convert it to bytes.
- *Objects*: Serialize your objects into a byte array according to the object's serialization
  method.
- *Protocol Buffers*: Use the `.writeToBuffer()` method on the protobuf object to obtain
  a `List<int>` representation.

**Example**
The example below demonstrates how to write a string to a characteristic, with error handling:

```dart
// Import the required Dart convert library.
import 'dart:convert';

// ... other code for your Flutter application ...

/// Writes a string value to the given BLE characteristic.
Future<void> writeStringToCharacteristic(String value, BleCharacteristic characteristic) async {
  try {
    // Write the string value to the characteristic using the central method
    await _ble.writeCharacteristic(
      characteristic: characteristic,
      value: value,
    );

    print("Successfully wrote value to the characteristic.");
  } catch (e) {
    // Handle any errors that occur during the write operation
    print("Failed to write value to characteristic: $e");
  }
}

// ... other code for your Flutter application ...
```

**Notes and Best Practices**

- Ensure the data conforms to the expected format of the BLE characteristic you're writing to.
- The `writeValue` operation may throw exceptions if the characteristic is not writable, the
  peripheral is not connected, or the provided data is not valid. Always include error handling to
  manage these cases.
- It's important to understand the BLE device's characteristic properties. Some characteristics
  accept only specific lengths or data patterns.
- Consult the BLE peripheral documentation to determine if a response from the characteristic is
  expected after writing. You may need to listen for a notification or read the characteristic again
  to confirm the write operation's success.

### **Reading Values from a BLE Characteristic**:

Communicating with BLE devices often entails reading data from a characteristic to obtain
information or status updates from the peripheral. The Splendid BLE plugin offers a convenient
`readValue` method on the `BleCharacteristic` class for this purpose.

When reading from a BLE characteristic, you receive the data as `BleCharacteristicValue`, which
consists of a byte stream (`List<int>`). Depending on the characteristic's specification,
this could represent a variety of data types.

**Data Interpretation**
After calling the `readValue` method, you may need to convert the byte stream into a usable format
depending on your application's needs:

- *String*: Convert the byte stream to a string using `utf8.decode` from Dart's dart:convert
  package.
- *JSON*: If the byte stream represents serialized JSON data, convert it to a string with
  `utf8.decode`, then parse it into a `Map<String, dynamic>` with `json.decode`.
- *Objects*: Deserialize your byte stream into objects according to the object's deserialization
  method.
- *Protocol Buffers*: Use the protobuf object's `.mergeFromBuffer()` method to deserialize the
  `List<int>` into a protobuf object.

**Example**
The example below shows how to read from a characteristic and handle potential errors:

```dart
import 'dart:convert';

// ... other code for your Flutter application ...

/// Reads the value from the given BLE characteristic and updates the UI state.
Future<void> readCharacteristicValue(BleCharacteristic characteristic) async {
  try {
    // Read the characteristic value.
    BleCharacteristicValue characteristicValue = await _ble.readCharacteristic(
      characteristic: characteristic,
      timeout: Duration(seconds: 10),
    );

    // Update the state with the new value.
    setState(() {
      _characteristicValue = characteristicValue;
    });

    // Optionally, decode the value if it's expected to be a string or other data structure.
    // String stringValue = utf8.decode(characteristicValue.value);

    debugPrint('Successfully read characteristic value.');
  } catch (e) {
    // Handle any errors that occur during the read operation.
    debugPrint('Failed to read characteristic value with exception: $e');
  }
}

// ... other code for your Flutter application ...
```

**Notes and Best Practices**

- Confirm that the characteristic you're reading from is designed to provide readable data.
- The `readValue` operation may throw exceptions if the characteristic is not readable, the
  peripheral is not connected, or other communication errors occur. It is essential to include error
  handling to cover these scenarios.
- Be aware of the expected data format. Some characteristics provide data in a format that requires
  specific decoding strategies.
- Consult the BLE peripheral documentation to understand the structure and expected format of the
  data provided by the characteristic.

### **Disconnecting from a BLE Peripheral**:

Properly disconnecting from a BLE device is crucial for managing resources and ensuring that the
application behaves predictably. The Splendid BLE plugin simplifies this process by providing a
disconnect method which can be called with the device's address.

**Disconnect Process**
When you no longer need to be connected to the BLE peripheral (e.g., after completing data exchange,
or when the user navigates away from the application), you should invoke the `disconnect` method.
This ensures that the connection is cleanly terminated and the BLE stack does not continue to
consume power for an unnecessary connection.

**Example**
Below is an example of how to disconnect from a BLE peripheral using the device's address:

```dart
// ... other code for your Flutter application ...

/// Disconnects from the connected BLE device.
Future<void> disconnectFromDevice(BleDevice device) async {
  try {
    // Invoke the disconnect method using the device's address
    await _ble.disconnect(device.address);

    // Handle post-disconnection logic, such as updating the UI state
    setState(() {
      // Update your UI or application state to reflect the disconnection
    });

    debugPrint('Successfully disconnected from the device.');
  } catch (e) {
    // Handle any errors that occur during the disconnection
    debugPrint('Failed to disconnect from the device with exception: $e');
  }
}

// ... other code for your Flutter application ...
```

**Notes and Best Practices**

- Always ensure that you perform a disconnect when your app is done interacting with a BLE
  peripheral.
- The disconnection process might not be instantaneous; handle any delays or errors gracefully in
  the UI.
- After disconnecting, it's good practice to handle cleanup tasks, such as nullifying references to
  the disconnected peripheral and updating the UI to reflect the disconnection status.
- Some peripherals might have special requirements for disconnection; consult the device's
  documentation for any additional steps that might need to be performed.

## Tutorial article

For a detailed tutorial article, please
visit https://medium.com/@Toglefritz/flutter-bluetooth-a669fcf4bb44?sk=cbbae5ffb7bd42490448c478bae6a6d7

## Error Handling

This plugin offers detailed error messages to help you handle possible exceptions gracefully in your
Flutter application.

<*other details coming soon*>

## Viewing Documentation Locally

**Prerequisites**
Before you begin, make sure you have the following installed:

- *Dart SDK*: `dhttpd` is a Dart tools, which requires the Dart SDK.
- *dartdoc*: This tool generates the documentation. You can get it by
  running `dart pub global activate dartdoc`.
- *dhttpd*: This is the server for hosting the documentation. Install it by
  running `dart pub global activate dhttpd`.

**Generating Documentation**
To generate the documentation for the Splendid BLE plugin, run the following command from the root
of
the plugin's directory:

```zsh
dart doc .
```

This command will process the Dart comments in the codebase and produce HTML documentation in the
*doc/api* directory.

**Hosting Documentation with dhttpd**
First, navigate to the directory where the documentation was generated:

```zsh
cd doc/api
```

Then, activate the `dhttpd` tool:

```zsh
dart pub global activate dhttpd
```

Start the dhttpd server:

```zsh
dhttpd --path .
```

By default, `dhttpd` will serve files on port 8080. You can specify a different port with
the `--port` argument if needed.

**Accessing the Documentation**
Once `dhttpd` is running, open your web browser and navigate to http://localhost:8080. This will
open the locally hosted version of the documentation.

You'll be able to browse all the classes, methods, and properties of the Splendid BLE plugin, along
with detailed comments and explanations as provided in the source code.

**Stopping the Server**
When you are done viewing the documentation, return to the terminal and press `Ctrl+C` to stop
the `dhttpd` server.

## Feedback and Contributions

Contributions, suggestions, and feedback are all welcome and very much appreciated. Please open an
issue or submit a pull request
on the GitHub repository.

## License:

MIT License

## Disclaimer

In the creation of this Flutter Bluetooth Low Energy plugin, artificial intelligence (AI) tools have
been utilized. These tools have assisted in various stages of the plugin's development, from initial
code generation to the optimization of algorithms.

It is emphasized that the AI's contributions have been thoroughly overseen. Each segment of
AI-assisted code has undergone meticulous scrutiny to ensure adherence to high standards of quality,
reliability, and performance. This scrutiny was conducted by the sole developer responsible for the
plugin's creation.

Rigorous testing has been applied to all AI-suggested outputs, encompassing a wide array of
conditions and use cases. Modifications have been implemented where necessary, ensuring that the
AI's contributions are well-suited to the specific requirements and limitations inherent in
Bluetooth Low Energy technology.

Commitment to the plugin's accuracy and functionality is paramount, and feedback or issue reports
from users are invited to facilitate continuous improvement.

It is to be understood that this plugin, like all software, is subject to evolution over time. The
developer is dedicated to its progressive refinement and is actively working to surpass the
expectations of the Flutter community.