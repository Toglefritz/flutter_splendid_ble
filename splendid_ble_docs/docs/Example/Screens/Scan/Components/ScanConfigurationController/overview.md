---
title: Overview
sidebar_position: 1
---

# Overview for `ScanConfigurationController`

## Description

A controller for the [ScanConfigurationRoute] that manages the state and owns all business logic.

## Dependencies

- State

## Members

- **scanMode**: `ScanMode?`
  Determines the behavior of the Bluetooth scanning process with respect to how aggressively the Android
 operating system will surface Bluetooth devices detected by the scanning process.

- **reportDelay**: `int?`
  A delay in reporting devices detected by the scan.

- **allowDuplicates**: `bool`
  Determines if the scanning process will

- **deviceName**: `String?`
  A string used to filter the Bluetooth scan list to show only Bluetooth devices including this name in their
 advertising data.

- **manufacturerId**: `int?`
  A manufacturer ID, which is the initial part of the Bluetooth device address used to filter the Bluetooth scan to
 show only devices from the same manufacturer (or the same manufacturer of the Bluetooth radio). This is useful for
 displaying only devices from a particular device vendor.

- **serviceUuids**: `List<String>?`
  A list of Bluetooth primary service UUID values used to filter the Bluetooth scan to show only devices with
 one of the listed UUID values as their primary services. Since the primary service UUIDs are specified in the
 firmware of a Bluetooth device, this is another method of filtering to show only devices for a particular product
 line or from a particular manufacturer.

