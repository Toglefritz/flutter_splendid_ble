# Error and Failure Reporting

This document describes how the `flutter_splendid_ble` plugin reports problems, with a focus on the
in-band failure detail attached to the connection process (introduced in 1.5.0) and the bonding
process (introduced in 1.6.0). It covers the data model, the complete per-platform category
mappings, the known iOS/macOS bonding limitation, and recommended recovery patterns.

For the general usage of the plugin, see the [README](../README.md).

## Table of Contents

- [Two Reporting Mechanisms](#two-reporting-mechanisms)
- [Thrown Exceptions](#thrown-exceptions)
- [The Event + Failure Model](#the-event--failure-model)
- [Connection Failure Reporting](#connection-failure-reporting)
    - [`BleConnectionState`](#bleconnectionstate)
    - [When `failure` Is Populated](#when-failure-is-populated)
    - [`BleConnectionFailure`](#bleconnectionfailure)
    - [`BleConnectionFailureCategory` Mappings](#bleconnectionfailurecategory-mappings)
- [Bonding Failure Reporting](#bonding-failure-reporting)
    - [`BleBondState`](#blebondstate)
    - [`BleBondFailure`](#blebondfailure)
    - [`BleBondFailureCategory` Mappings](#blebondfailurecategory-mappings)
    - [The iOS/macOS Bonding Limitation](#the-iosmacos-bonding-limitation)
- [Recovery Patterns](#recovery-patterns)
    - [Branch on Category, Log the Raw Detail](#branch-on-category-log-the-raw-detail)
    - [Handling a Failed Connection Attempt](#handling-a-failed-connection-attempt)
    - [Diagnosing a Bonding Failure](#diagnosing-a-bonding-failure)
- [Design Notes](#design-notes)

## Two Reporting Mechanisms

The plugin reports problems through two complementary mechanisms:

1. **Thrown exceptions** for operations that fail synchronously or while awaiting a `Future`.
2. **In-band failure detail on lifecycle streams** for the connection and bonding processes, where
   the underlying work is performed asynchronously by the operating system and a failure is a normal
   part of the lifecycle rather than an exceptional control-flow event.

The distinction matters: a failed connection attempt or a failed bond is not an exception in the
Dart sense — it is an outcome reported on the same stream that carries the successful outcomes, so
that the reason travels in-band with the state it describes.

## Thrown Exceptions

Operations that can fail while you `await` them throw typed exceptions. Wrap calls in `try`/`catch`
and branch on the exception type to respond appropriately. The available types include:

| Exception | Thrown by |
| --- | --- |
| `BluetoothScanException` | Scanning operations (`startScan`, `stopScan`, `getConnectedDevices`). |
| `BluetoothConnectionException` | Connection setup errors, and errors emitted on the connection stream via its `error` channel. |
| `BluetoothPermissionException` | Permission-related failures. |
| `BluetoothReadException` | Characteristic read failures. |
| `BluetoothWriteException` | Characteristic write failures. |
| `BluetoothSubscriptionException` | Characteristic subscribe/unsubscribe failures. |
| `ServiceDiscoveryException` | Service discovery failures. |
| `GattCacheException` | GATT cache refresh failures (Android). |

```dart
try {
  await _ble.writeCharacteristic(characteristic: characteristic, value: value);
} on BluetoothWriteException catch (e) {
  // Handle a write-specific failure.
  debugPrint('Write failed: ${e.message}');
}
```

## The Event + Failure Model

The connection and bonding processes share the same design: a stream emits **event** objects, each
of which pairs a **state** with an optional **failure** detail. This is the central idea behind the
error reporting added in 1.5.0 and 1.6.0.

Why an event rather than a bare state? A plain state enum cannot answer "why did this fail?". Both
Apple and Android platforms surface failure detail alongside the state change — a `CBError`/
`CBATTError` on Apple, a GATT/HCI or unbond-reason integer on Android — but a bare enum has nowhere
to carry it. Coupling the state with an optional failure guarantees the reason arrives in the correct
order with the state it describes, and removes the need for a parallel error channel.

Every failure object carries two kinds of information:

- A **normalized, cross-platform `category`** — branch on this to write recovery logic once, rather
  than per platform.
- The **raw platform-specific detail** (`platform`, `rawCode`, `domain`, `description`) — use this
  for logging and deep diagnosis. The raw values differ per platform and are preserved verbatim.

Both `BleConnectionEvent` and `BleBondEvent` expose an `isFailure` getter (`true` when `failure` is
non-null) as a convenience.

## Connection Failure Reporting

`connect` and `observeConnectionState` return `Future<Stream<BleConnectionEvent>>`.

### `BleConnectionState`

| Value | Meaning |
| --- | --- |
| `connected` | The peripheral is successfully connected. |
| `connecting` | A connection is being established (platform-dependent). |
| `disconnecting` | The connection is being torn down (platform-dependent). |
| `disconnected` | The peripheral is disconnected from the host. |
| `failed` | A connection attempt never succeeded. Distinct from `disconnected`, which is the loss of a connection that had been established. |
| `unknown` | The state could not be determined. |

`BleConnectionState.failed` was added in 1.5.0 to distinguish a connection attempt that never
succeeded (for example, the peripheral was out of range or rejected the connection) from the
termination of a previously established link.

### When `failure` Is Populated

| Event state | `failure` |
| --- | --- |
| `failed` | Always present. Describes why the attempt never succeeded. |
| `disconnected` | Present **only** when the disconnection was unexpected (the platform reported an error). A clean, application-initiated disconnect produces a `disconnected` event with a `null` failure. |
| `connected`, `connecting`, `disconnecting`, `unknown` | Always `null`. |

### `BleConnectionFailure`

| Field | Type | Description |
| --- | --- | --- |
| `category` | `BleConnectionFailureCategory` | Normalized, cross-platform classification. Branch on this. |
| `platform` | `String?` | The reporting host: `"ios"`, `"macos"`, or `"android"`. |
| `rawCode` | `int?` | The raw platform code. The `NSError` code on Apple; the GATT/HCI status integer on Android. |
| `domain` | `String?` | The `NSError` domain on Apple (e.g. `CBErrorDomain`); `"android_gatt"` on Android. |
| `description` | `String?` | A human-readable label for logs and diagnostics — not for display to end users. |

On Apple platforms, CoreBluetooth frequently delivers a `nil` error on a failed connection; in that
case `rawCode`, `domain`, and `description` are all `null` and `category` is `unknown`.

### `BleConnectionFailureCategory` Mappings

The normalized categories and how each platform's raw codes map onto them:

| Category | iOS/macOS (`CBError` / `CBATTError`) | Android (GATT/HCI status) |
| --- | --- | --- |
| `timeout` | `connectionTimeout` | 8 (`0x08`, connection timeout), 62 (failure to establish) |
| `peerTerminated` | `peripheralDisconnected` | 19 (`0x13`, terminated by peer) |
| `hostTerminated` | — | 22 (`0x16`, terminated by local host) |
| `authenticationFailure` | `encryptionTimedOut`; `insufficientAuthentication`, `insufficientEncryption`, `insufficientAuthorization` (`CBATTErrorDomain`) | 5 (insufficient authentication), 137 (GATT auth / encryption failure) |
| `connectionLimitReached` | `connectionLimitReached` | — (Android reports no dedicated status) |
| `unreachable` | `unknownDevice` | — |
| `unknown` | any unrecognized code, or a `nil` error | any unmapped status, including the catch-all `GATT_ERROR` (133) |

A dash (—) means the platform does not report a dedicated code for that category. A firmware watchdog
that drops the link, for example, appears as `CBError.peripheralDisconnected` on iOS and as GATT
status 19 on Android; both normalize to `peerTerminated`.

> **Interpreting `unknown`.** `unknown` does not mean "no failure". It means the platform either
> provided no error object (common on CoreBluetooth's `didFailToConnect`) or a code this plugin does
> not yet map to a more specific category (such as Android's catch-all status 133). When the category
> is `unknown`, consult `rawCode`, `domain`, and `description` for whatever detail the platform did
> supply.

## Bonding Failure Reporting

`observeBondState` returns `Future<Stream<BleBondEvent>>`. Bonding (pairing) is performed by the
operating system, not by the plugin. `observeBondState` does not *initiate* a bond — it reports the
bond-state transitions the OS surfaces. To provoke a bond, interact with an encrypted characteristic
once the device is connected (on Android you may also trigger it directly).

### `BleBondState`

| Value | Meaning |
| --- | --- |
| `none` | No bond exists between the host and the peripheral. |
| `bonding` | The OS is actively establishing a bond. |
| `bonded` | A bond has been successfully established and persisted. |
| `failed` | A bond attempt failed. The accompanying `failure` describes why, to the extent the platform provides it. |
| `unknown` | The bonding state could not be determined. |

`failure` is populated only for the `failed` state; it is `null` for all other states.

### `BleBondFailure`

| Field | Type | Description |
| --- | --- | --- |
| `category` | `BleBondFailureCategory` | Normalized, cross-platform classification. Branch on this. |
| `platform` | `String?` | The reporting host: `"ios"`, `"macos"`, or `"android"`. |
| `rawCode` | `int?` | Android: the unbond reason integer. Apple: the `NSError` code from an attribute-level error, when available. |
| `domain` | `String?` | `"android_bond"` on Android; the `NSError` domain (e.g. `CBATTErrorDomain`) on Apple. |
| `description` | `String?` | A human-readable label for logs and diagnostics. |

### `BleBondFailureCategory` Mappings

| Category | Android (unbond reason) | iOS/macOS |
| --- | --- | --- |
| `authenticationFailure` | `AUTH_FAILED` (1) | `insufficientAuthentication`, `insufficientEncryption`, `insufficientAuthorization` (`CBATTErrorDomain`); `encryptionTimedOut` (`CBErrorDomain`) |
| `authenticationRejected` | `AUTH_REJECTED` (2), `REMOTE_AUTH_CANCELED` (8) | — |
| `authenticationTimeout` | `AUTH_TIMEOUT` (6) | — |
| `remoteDeviceDown` | `REMOTE_DEVICE_DOWN` (4) | — |
| `removed` | `AUTH_CANCELED` (3), `REMOVED` (9) | — |
| `unknown` | any other reason | any unrecognized code, or no error detail (the common case) |

A dash (—) means the platform does not report a dedicated reason for that category. The richer
categories (`authenticationRejected`, `authenticationTimeout`, `remoteDeviceDown`, `removed`) are
effectively Android-only, because iOS and macOS do not expose those reasons (see below).

On Android, the raw reason codes come from the `ACTION_BOND_STATE_CHANGED` broadcast's reason extra.
Note that a transition to the unbonded state is ambiguous on Android: it represents both a deliberate
unbond (reported as `none`, no failure) and a failed bond attempt (reported as `failed`, with a
reason). The plugin disambiguates the two using the presence of a reason code.

### The iOS/macOS Bonding Limitation

**This is a platform restriction imposed by the operating system, not a limitation of this plugin.**

CoreBluetooth does not expose a bonding API, a bond-state callback, or a bonding failure reason to
apps. There is no `didBond` / `didFailToBond` delegate method, and no way to read a device's current
bond state. Apple deliberately hides the pairing process: an app can only *provoke* bonding by
interacting with an encrypted characteristic, and the OS performs the pairing exchange out of band.

Because of this, `observeBondState` on iOS and macOS is **best-effort and coarse**. It derives
updates from the lifecycle of operations on encrypted characteristics:

| Emitted | Trigger |
| --- | --- |
| `unknown` | Immediately on subscription (the real bond state cannot be read). |
| `bonding` | An acknowledged (`withResponse`) write to an observed device begins; the OS may transparently initiate pairing to satisfy an encrypted characteristic. |
| `bonded` | Such a write succeeds, implying any required bond is now in place. |
| `failed` | Such a write fails with an authentication/encryption error. The `category` resolves to `authenticationFailure` or `unknown`, carrying whatever `CBATTError`/`CBError` detail is available. |

If your application needs rich bonding diagnostics, expect them on Android and design the iOS/macOS
experience around the coarser signal. Treat `BleBondFailureCategory.unknown` on Apple platforms as
"the pairing did not complete" rather than expecting a specific reason.

## Recovery Patterns

### Branch on Category, Log the Raw Detail

The intended usage is to branch behavior on the normalized `category` and log the raw fields for
diagnosis. This keeps recovery logic single-sourced across platforms.

```dart
void _onConnectionEvent(BleConnectionEvent event) {
  if (!event.isFailure) {
    // Handle non-failure states (connected, connecting, clean disconnect, ...).
    return;
  }

  final BleConnectionFailure failure = event.failure!;

  // Log the raw platform detail for diagnosis.
  debugPrint(
    'Connection failure on ${failure.platform}: '
    'code=${failure.rawCode}, domain=${failure.domain}, '
    'description=${failure.description}',
  );

  // Branch behavior on the normalized, cross-platform category.
  switch (failure.category) {
    case BleConnectionFailureCategory.timeout:
    case BleConnectionFailureCategory.unreachable:
      // Likely out of range — retry with backoff or prompt the user to move closer.
      break;
    case BleConnectionFailureCategory.peerTerminated:
      // The peripheral closed the link — a firmware watchdog or app-layer disconnect.
      break;
    case BleConnectionFailureCategory.authenticationFailure:
      // Pairing/encryption failed — the bond may need to be removed and re-established.
      break;
    case BleConnectionFailureCategory.connectionLimitReached:
      // Disconnect another peripheral before retrying.
      break;
    case BleConnectionFailureCategory.hostTerminated:
    case BleConnectionFailureCategory.unknown:
      // Fall back to raw detail; a generic retry is often reasonable.
      break;
  }
}
```

### Handling a Failed Connection Attempt

Distinguish a never-succeeded attempt (`failed`) from an unexpected loss of an established link
(`disconnected` with a non-null `failure`), since the two usually warrant different responses:

```dart
void _onConnectionEvent(BleConnectionEvent event) {
  switch (event.state) {
    case BleConnectionState.failed:
      // The attempt never succeeded. Consider a bounded number of retries.
      _scheduleReconnect();
      break;
    case BleConnectionState.disconnected:
      if (event.isFailure) {
        // An established link was lost unexpectedly — often worth reconnecting immediately.
        _scheduleReconnect();
      } else {
        // A clean, intentional disconnect — no recovery needed.
      }
      break;
    default:
      break;
  }
}
```

### Diagnosing a Bonding Failure

```dart
late final StreamSubscription<BleBondEvent> _bondSub;

Future<void> _observeBond(String deviceAddress) async {
  final Stream<BleBondEvent> stream =
      await _ble.observeBondState(deviceAddress: deviceAddress);

  _bondSub = stream.listen((BleBondEvent event) {
    switch (event.state) {
      case BleBondState.bonding:
        // Show a "pairing..." indicator.
        break;
      case BleBondState.bonded:
        // Pairing succeeded; proceed with encrypted operations.
        break;
      case BleBondState.failed:
        final BleBondFailure failure = event.failure!;
        debugPrint(
          'Bond failed on ${failure.platform}: '
          'category=${failure.category}, code=${failure.rawCode}, '
          'description=${failure.description}',
        );

        switch (failure.category) {
          case BleBondFailureCategory.authenticationTimeout:
            // The user likely did not respond to the pairing prompt in time — retry.
            break;
          case BleBondFailureCategory.authenticationRejected:
            // The peripheral or user refused — do not silently retry.
            break;
          case BleBondFailureCategory.authenticationFailure:
            // Keys may be stale; the user may need to remove the device in system settings.
            break;
          case BleBondFailureCategory.remoteDeviceDown:
            // The peripheral went away mid-pairing — reconnect and retry.
            break;
          case BleBondFailureCategory.removed:
          case BleBondFailureCategory.unknown:
            // On iOS/macOS this is the typical value; treat as "pairing did not complete".
            break;
        }
        break;
      case BleBondState.none:
      case BleBondState.unknown:
        break;
    }
  });
}

void dispose() {
  _bondSub.cancel();
}
```

## Design Notes

- **Tolerant parsing.** The Dart factories that decode native payloads (`fromMap` / `fromIdentifier`)
  never throw. An unrecognized or missing state resolves to `unknown`, and a partial failure payload
  still produces a well-formed object. A newer native layer that introduces additional categories
  cannot crash older Dart code. (This also fixed a pre-1.5.0 crash where a `"FAILED"` status from
  iOS/macOS had no matching enum value.)
- **Single operation handler per channel.** Internally, the method channel supports one active
  operation handler at a time. Observing connection state and bond state simultaneously on the same
  channel is therefore not supported; this is a pre-existing constraint of the channel router.
- **Additive vs. breaking.** The bonding diagnostics in 1.6.0 are purely additive. The connection
  diagnostics in 1.5.0 were a breaking change: `connect` and `observeConnectionState` changed from
  returning `Stream<BleConnectionState>` to `Stream<BleConnectionEvent>`. Read the state from
  `event.state` and the failure from `event.failure`.
