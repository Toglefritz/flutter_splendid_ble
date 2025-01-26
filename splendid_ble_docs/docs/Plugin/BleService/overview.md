---
title: Overview
sidebar_position: 1
---

# Overview for `BleService`

## Description

Represents a Bluetooth Low Energy (BLE) service.

 In the BLE protocol, services encapsulate one or more characteristics that
 contain data provided by the peripheral device. Each service has a universally
 unique identifier (UUID) and contains a collection of [BleCharacteristic]
 instances which detail the properties and permissions of each characteristic.

## Members

- **serviceUuid**: `String`
  The universally unique identifier (UUID) for the service.

- **characteristics**: `List<BleCharacteristic>`
  A list of [BleCharacteristic] objects that belong to this service.

 Each [BleCharacteristic] encapsulates the UUID, properties, and permissions
 of a particular characteristic within this service.

## Constructors

### Unnamed Constructor
Creates a [BleService] instance.

 Requires [serviceUuid] and a list of [characteristics] to initialize.

### fromMap
Constructs a [BleService] from a map.

 The map should contain a 'serviceUuid' key for the UUID of the service and a
 'characteristics' key containing a list of maps, each of which can be used
 to initialize a [BleCharacteristic] instance.

#### Parameters

- `map`: `Map<String, dynamic>`
