---
title: Overview
sidebar_position: 1
---

# Overview for `ConnectedBleDevice`

## Description

Represents a BLE device that is connected to the host device.

 Because this class is used to represent devices that are already connected to the system. Their RSSI and
 manufacturer data are not needed.

## Dependencies

- BleDevice

## Constructors

### Unnamed Constructor
Creates an instance of [ConnectedBleDevice].

### fromMap
Converts a Map to a [ConnectedBleDevice] object.

 The [map], which contains information about the connected Bluetooth device, comes from the plugin's method
 channel. Therefore, the type annotation is `<dynamic dynamic>`.

#### Parameters

- `map`: `Map<dynamic, dynamic>`
