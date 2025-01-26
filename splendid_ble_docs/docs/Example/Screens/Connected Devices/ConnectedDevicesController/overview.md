---
title: Overview
sidebar_position: 1
---

# Overview for `ConnectedDevicesController`

## Description

A controller for the [ConnectedDevicesRoute] that manages the state and owns all business logic.

## Dependencies

- State

## Members

- **_ble**: `SplendidBleCentral`
  A [SplendidBleCentral] instance used for Bluetooth operations conducted by this route.

- **connectedDevices**: `List<ConnectedBleDevice>?`
  A list of Bluetooth devices currently connected to the host device.

