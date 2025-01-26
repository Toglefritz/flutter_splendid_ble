---
title: Overview
sidebar_position: 1
---

# Overview for `ScanResultTile`

## Description

Displays information about a Bluetooth device detected by the Bluetooth scan.

 Each [BleDevice] detected by the Bluetooth scan is displayed in a [ListTile], provided the device has a non-null
 value for its name. The tile also includes the Bluetooth address for the Bluetooth device. Finally, the RSSI
 of the device is represented as a

## Dependencies

- StatelessWidget

## Members

- **device**: `BleDevice`
  A [BleDevice] detected by the Bluetooth scanning process.

- **onTap**: `VoidCallback`
  A callback for taps on this scan result.

## Constructors

### Unnamed Constructor
Creates an instance of [ScanResultTile].

