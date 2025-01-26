---
title: Overview
sidebar_position: 1
---

# Overview for `ServicesInfo`

## Description

Contains a list of Bluetooth GATT services discovered from a Bluetooth device, each of which is presented in a
 [ExpansionTile] that can be opened to view a list of Bluetooth characteristics under each service.

## Dependencies

- StatelessWidget

## Members

- **services**: `List<BleService>`
  A list of [BleService], representing Bluetooth GATT services discovered from a Bluetooth device.

- **characteristicOnTap**: `void Function(BleCharacteristic)`
  A callback invoked when a characteristic is tapped.

## Constructors

### Unnamed Constructor
Creates an instance of [ServicesInfo].

