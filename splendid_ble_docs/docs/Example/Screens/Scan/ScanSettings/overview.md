---
title: Overview
sidebar_position: 1
---

# Overview for `ScanSettings`

## Description

The [ScanSettings] class encapsulates options that can be used to configure Bluetooth Low Energy (BLE) scan
 behavior.

 Use this class to specify options like the scan mode, report delay, whether to allow duplicates, and the desired
 callback type.

 Example usage:
 ```dart
 var settings = ScanSettings(scanMode: ScanMode.lowPower);
 ```

## Members

- **scanMode**: `ScanMode?`
  The mode to be used for the BLE scan.

 This can be one of [ScanMode.lowPower], [ScanMode.balanced], or [ScanMode.lowLatency].

- **reportDelayMillis**: `int?`
  The delay in milliseconds for reporting the scan results.

 Defaults to 0, which means results are reported as soon as they are available.

- **allowDuplicates**: `bool?`
  Whether to report only unique advertisements or to include duplicates.

 If `true`, each advertisement is reported only once. If `false`, advertisements
 might be reported multiple times.

## Constructors

### Unnamed Constructor
Constructs a [ScanSettings] instance with the specified scan settings.

 [scanMode] determines the mode used for scanning.
 [reportDelayMillis] determines the delay for reporting results.
 [allowDuplicates] specifies whether to include duplicate advertisements.

