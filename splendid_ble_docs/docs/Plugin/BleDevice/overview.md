---
title: Overview
sidebar_position: 1
---

# Overview for `BleDevice`

## Description

Represents a discovered BLE device.

## Members

- **name**: `String?`
  The name of the device.

 Bluetooth devices are not required to provide a name so this String is nullable.

- **address**: `String`
  The Bluetooth address of the device.

- **rssi**: `int`
  The RSSI (Received Signal Strength Indicator) value for the device.

- **manufacturerData**: `String?`
  The manufacturer data associated with the device.

 Bluetooth devices are not required to provide manufacturer data so this field is nullable.

## Constructors

### Unnamed Constructor
Creates an instance of [BleDevice].

### fromMap
Converts a Map to a [BleDevice] object.

 The `map`, which contains information about the discovered Bluetooth device, comes from the plugin's method
 channel. Therefore, the type annotation is `<dynamic dynamic>`.

#### Parameters

- `map`: `Map<dynamic dynamic>`
