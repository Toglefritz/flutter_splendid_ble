---
title: Overview
sidebar_position: 1
---

# Overview for `DeviceDetailsController`

## Description

A controller for the [DeviceDetailsRoute] that manages the state and owns all business logic.

## Dependencies

- State

## Members

- **_ble**: `SplendidBleCentral`
  A [SplendidBleCentral] instance used for Bluetooth operations conducted by this route.

- **_connectionStateStream**: `StreamSubscription<BleConnectionState>?`
  A [StreamSubscription] for the connection state between the Flutter app and the Bluetooth peripheral.

- **_currentConnectionState**: `BleConnectionState`
  The current connection state between the host mobile device and the [BleDevice] provided to this route.

- **_connecting**: `bool`
  Determines if a connection attempt is currently in progress.

- **_discoveringServices**: `bool`
  Determines if the service and characteristic discovery process is currently in progress.

- **_servicesDiscoveredStream**: `StreamSubscription<List<BleService>>?`
  A [StreamController] used to listen for updates during the BLE service discovery process.

- **_discoveredServices**: `List<BleService>`
  A list of Bluetooth service information that includes a list of characteristics under each service.

