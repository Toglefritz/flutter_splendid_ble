---
title: Overview
sidebar_position: 1
---

# Overview for `HomeController`

## Description

A controller for the [HomeRoute] that manages the state and owns all business logic.

## Dependencies

- State

## Members

- **_ble**: `SplendidBleCentral`
  A [SplendidBleCentral] instance used for Bluetooth operations conducted by this route.

- **_permissionsGranted**: `bool?`
  Determines if Bluetooth permissions have been granted.

 A null value indicates that permissions have neither been granted nor denied. It is simply a mystery.

- **_bluetoothStatusStream**: `StreamSubscription<BluetoothStatus>?`
  A [Stream] used to listen for changes in the status of the Bluetooth adapter on the host device and set the
 value of [_bluetoothStatus].

- **_bluetoothPermissionsStream**: `StreamSubscription<BluetoothPermissionStatus>?`
  A [Stream] used to listen for changes in the status of the Bluetooth permissions required for the app to operate
 and set the value of [_permissionsGranted].

- **_bluetoothStatus**: `BluetoothStatus?`
  The status of the Bluetooth adapter on the host device.

