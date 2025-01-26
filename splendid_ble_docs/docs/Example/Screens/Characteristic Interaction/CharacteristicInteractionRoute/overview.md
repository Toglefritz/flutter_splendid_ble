---
title: Overview
sidebar_position: 1
---

# Overview for `CharacteristicInteractionRoute`

## Description

Provides an interface for interacting with a [BleCharacteristic].

 Depending upon the properties of the provided [BleCharacteristic], this route can be used to write values to and/or
 read values from the characteristic. The interface resembles a chat interface, with messages sent to the
 Bluetooth device displayed on the right side of the interface and messages read from the device displayed on the
 left.

 For Bluetooth characteristics that only have read properties (whether encrypted or unencrypted), the UI element
 used to input messages to be sent to the Bluetooth characteristic is hidden. This interface is displayed for
 characteristics that have write (again whether encrypted or unencrypted) properties.

## Dependencies

- StatefulWidget

## Members

- **device**: `BleDevice`
  The [BleDevice] with which the app will communicate in this route.

- **characteristic**: `BleCharacteristic`
  The Bluetooth characteristic with which this route will interact.

## Constructors

### Unnamed Constructor
Creates an instance of [CharacteristicInteractionRoute].

