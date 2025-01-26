---
title: Overview
sidebar_position: 1
---

# Overview for `ScanController`

## Description

A controller for the [ScanRoute] that manages the state and owns all business logic.

## Dependencies

- State

## Members

- **_ble**: `SplendidBleCentral`
  A [SplendidBleCentral] instance used for Bluetooth operations conducted by this route.

- **_scanInProgress**: `bool`
  Determines if a scan is currently in progress.

- **_scanStream**: `StreamSubscription<BleDevice>?`
  A [StreamSubscription] for the Bluetooth scanning process.

- **discoveredDevices**: `List<BleDevice>`
  A list of [BleDevice]s discovered by the Bluetooth scan.

