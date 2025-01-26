---
title: Overview
sidebar_position: 1
---

# Overview for `ScanFilter`

## Description

The `ScanFilter` class is used to define criteria that determine which Bluetooth devices are returned during a
 scan for BLE (Bluetooth Low Energy) devices.

 Scanning for BLE devices can be a resource-intensive process, especially when many devices are within range.
 By using filters, the scanning process can be tailored to detect only devices that match certain criteria, thereby
 making the process more efficient and focused.

 The `ScanFilter` class allows for filtering based on various properties of the Bluetooth devices, such as:

 - **Device Name:** The human-readable name of the device.
 - **Device Address:** The unique hardware address of the device.
 - **Manufacturer Data:** Custom data provided by the manufacturer of the device.
 - **Service UUIDs:** Specific universally unique identifiers (UUIDs) for services provided by the device.
 - **Service Data:** Data related to a specific service provided by the device.

 By using one or more of these properties, the `ScanFilter` class enables applications to find and interact with
 only those devices that are of interest. For instance, an application might use a `ScanFilter` to look only for
 devices that provide a particular service or that have a specific name.

 Example usage:
 ```dart
 var filter = ScanFilter(deviceName: 'DeviceName');
 ```

## Members

- **deviceName**: `String?`
  The device name that should match the device's advertised name.

- **serviceUuids**: `List<String>?`
  The service UUIDs that should match the advertised service UUIDs.

- **manufacturerId**: `int?`
  The manufacturer ID associated with a specific device manufacturer.

- **manufacturerData**: `Map<int, List<int>>?`
  Additional manufacturer data that must match the advertised data.

## Constructors

### Unnamed Constructor
Constructs a [ScanFilter] instance with specified filter parameters.

 You can specify one or more criteria that scanned devices must match. If all parameters are left `null`, the
 filter will not apply any restrictions.

 [deviceName] filters devices based on their advertised name.
 [serviceUuids] filters devices based on their advertised service UUIDs.
 [manufacturerId] filters devices based on their manufacturer ID.
 [manufacturerData] filters devices based on their manufacturer-specific data.

