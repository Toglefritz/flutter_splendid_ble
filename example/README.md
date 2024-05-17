# Flutter Splendid BLE Example App

This example application demonstrates the usage of the Flutter Splendid BLE plugin. The application can operate in two modes: as a central device or as a BLE peripheral.

## Central Device

In this mode, the application demonstrates the following features:

- **Scanning for Nearby BLE Devices**: The application can scan for nearby Bluetooth Low Energy (BLE) devices. It provides a list of discovered devices, displaying their names and signal strengths.
- **Connecting to BLE Devices**: The application can establish a connection with a selected BLE device. It handles connection errors and timeouts gracefully.
- **Communicating with BLE Devices**: Once connected, the application can communicate with the BLE device. It can read and write to the device's characteristics, and subscribe to notifications/indications from the device.
- **Disconnecting from BLE Devices**: The application can disconnect from a connected BLE device. It also handles disconnections initiated by the device or due to signal loss.

## BLE Peripheral

In this mode, the application acts as a BLE peripheral and demonstrates the following features:

- **Configuring the BLE Server**: The application allows the configuration of the BLE server, including the setting of the device name and the services it offers.
- **Starting and Stopping Advertising**: The application can start advertising its services to nearby BLE devices. It can also stop advertising on demand.
- **Accepting Incoming Connections**: The application can accept incoming connections from central devices. It handles multiple concurrent connections.
- **Responding to Disconnections**: The application can respond to disconnections, whether initiated by the central device or due to signal loss.
- **Handling Read and Write Requests**: The application can handle read and write requests from connected central devices. It can respond with data or an error status as appropriate.
- **Notifying Connected Devices**: The application can send notifications to connected devices when certain characteristics change.

This example application provides a comprehensive demonstration of the capabilities of the Flutter Splendid BLE plugin. It serves as a great starting point for developers looking to integrate BLE functionality into their Flutter applications.