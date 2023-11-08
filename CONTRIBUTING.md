# FlutterSplendidBLE Example App

This example app demonstrates how to use the flutter_splendid_ble plugin to interact with Bluetooth
Low Energy (BLE) devices on both Android and iOS platforms.

## Getting Started

### Prerequisites

- Flutter SDK installed and configured
- A real Android or iOS device (the plugin doesn't support simulators/emulators)
- A real BLE device or a test device created with an ESP32 board (find the
  code [here](https://github.com/Toglefritz/esp32_ble_tester))

### Running the Example

1. **Clone the Repository**: Clone the flutter_splendid_ble repository, including this example app.
2. **Navigate to the Example Directory**: Use your terminal or command line to navigate to the
   example directory:

```bash
cd path/to/flutter_splendid_ble/example
```

3. Run the App: Connect your Android or iOS device and run the app using:

```bash
flutter run
```

## Features

This example app showcases the following features of the flutter_splendid_ble plugin:

- Scanning for nearby BLE devices
- Connecting to a BLE device
- Managing the bonding process
- Reading from and writing to BLE characteristics
- Subscribing to characteristics via notifications or indications
- Handling connection errors and other exceptions
- Monitoring connection status and other state changes

## How to Use

1. **Start Scanning**: Tap the "Start Scanning" button to begin scanning for nearby BLE devices.
2. **Connect to a Device**: Select a device from the list to connect.
3. **Interact with the Device**: Explore various options like reading/writing characteristics.
4. **Stop Scanning**: Tap the "Stop Scanning" button to stop scanning for devices.

## Support and Feedback

For any issues, feedback, or contributions, please refer to the main flutter_splendid_ble
repository.

## License

This project is licensed under the MIT License. See the LICENSE file for details.