---
title: Overview
sidebar_position: 1
---

# Overview for `BleCharacteristic`

## Description

Represents a Bluetooth Low Energy (BLE) characteristic.

 Each characteristic in BLE has a universally unique identifier (UUID), properties that define how the value of
 the characteristic can be accessed, and permissions that set the security requirements for accessing the value.
 This class encapsulates these details and provides utility methods to decode properties and permissions for
 easier understanding and interaction.

## Members

- **address**: `String`
  The Bluetooth address of the Bluetooth peripheral containing a service with this characteristic.

- **uuid**: `String`
  The universally unique identifier (UUID) for the characteristic.

- **properties**: `List<BleCharacteristicProperty>`
  An integer value representing the properties of the characteristic that is converted into a
 `List<BleCharacteristicProperty>` representing the properties of the Bluetooth characteristic.

- **permissions**: `List<BleCharacteristicPermission>?`
  An integer value representing the permissions of the characteristic that is converted into a
 `List<BleCharacteristicPermission>` representing the permissions of the Bluetooth characteristic.

## Constructors

### Unnamed Constructor
Creates a [BleCharacteristic] instance.

 Requires [uuid], [properties], and [permissions] to initialize.

### fromMap
Constructs a [BleCharacteristic] from a map.

 The map must contain keys 'uuid', 'properties', and 'permissions' with
 appropriate values.

#### Parameters

- `map`: `Map<String, dynamic>`
