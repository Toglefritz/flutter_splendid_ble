---
title: Overview
sidebar_position: 1
---

# Overview for `CharacteristicInteractionController`

## Description

A controller for the [CharacteristicInteractionRoute] that manages the state and owns all business logic.

## Dependencies

- State

## Members

- **messages**: `List<Message>`
  A list of "messages" sent between the host mobile device and a Bluetooth peripheral, in either direction.

- **controller**: `TextEditingController`
  A controller for the text field used to input commands to be sent to the Bluetooth peripheral.

- **_characteristicValueListener**: `StreamSubscription<BleCharacteristicValue>?`
  A [StreamSubscription] used to listen for changes in the value of the characteristic.

