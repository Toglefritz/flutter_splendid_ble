# Flutter Splendid BLE Plugin – Mocking Bluetooth for Testing

The **Flutter Splendid BLE** plugin provides a flexible and developer-friendly Bluetooth Low
Energy (BLE) API for Flutter applications. To support testing and simulator-based development, the
plugin includes built-in tools for mocking BLE behavior, most notably the
`FakeCentralMethodChannel`.

This guide explains how to simulate BLE interactions using `FakeCentralMethodChannel`, enabling
integration tests and development on simulators or devices without real BLE hardware.

## Why Mock BLE?

Flutter integration tests typically run on emulators and simulators that lack BLE capabilities.
Additionally, during development, it’s often useful to simulate different device behaviors (e.g.
connecting, disconnecting, advertising services) without needing real devices.

Mocking helps you:

- Test your app logic reliably and repeatedly.
- Develop features that depend on BLE on platforms that don’t support it.
- Validate filtering and connection logic without custom device firmware.

## FakeCentralMethodChannel Overview

`FakeCentralMethodChannel` is a fake implementation of the `CentralPlatformInterface` and can be
injected into your app in place of the real platform channel.

It lets you:

- Add mock BLE devices.
- Simulate scanning results.
- Control device connection states.
- Mock service discovery and characteristic reads.
- Inject Bluetooth state and permission status.

## Getting Started

### Injecting the Fake Central into Your App

In tests, initialize `SplendidBleCentral` with `FakeCentralMethodChannel`:

```dart
late FakeCentralMethodChannel fakeCentral;
late SplendidBle ble;

setUp(() {
    fakeCentral = FakeCentralMethodChannel();
    ble = SplendidBleCentral(platform: fakeCentral);
});
```

### Simulating BLE Scans

Add fake BLE devices before launching your test widget:

```dart
fakeCentral.addFakeDevice(
    BleDevice(
        name: 'Test Device',
        address: '00:11:22:33:44:55',
        rssi: -50,
        manufacturerData: null,
        advertisedServiceUuids: ['abcd1234-1234-1234-1234-1234567890aa'],
    ),
);
```

Then start a scan through your UI or logic. For example, in integration tests:

```dart
await tester.pumpWidget(
    SplendidBleExampleMaterialApp(
      home: ScanRoute(ble: ble),
    ),
);

await tester.pumpAndSettle();

expect(find.text('Test Device'), findsOneWidget);
```

### Device Filtering

Filters can be applied in tests using the `ScanFilter` class:

```dart
ScanFilter(
    deviceName: 'Test Device',
    serviceUuids: ['abcd1234-1234-1234-1234-1234567890aa'],
)
```

`FakeCentralMethodChannel` respects the same filtering logic as the native layer, so you can
validate filter behavior in tests. Advanced filtering includes:

- Manufacturer ID matching
- Full manufacturer data
- Custom vendor ID matchers (e.g. extracting IDs from names)

```dart
ScanFilter(
    manufacturerId: 0x004C,
    customVendorIdMatcher: (BleDevice device) {
      if (device.name?.length ?? 0 >= 2) {
        final bytes = device.name!.codeUnits.take(2).toList();
        final id = bytes[0] | (bytes[1] << 8);
        
        return id == 0x004C;
      }
      
      return false;
    },
)
```

### Simulating Connections

You can set and update connection states manually:

```dart
fakeCentral.setConnectionState
(device.address, BleConnectionState.connected);

// or emit a state update later
fakeCentral.simulateConnectionStateUpdate
(device.address, BleConnectionState.disconnected);
```

This enables validation of UI reactions to state transitions in widgets like `DeviceDetailsRoute`
found in the example app.

### Mocking Service Discovery

Add mock services to simulate discovery results:

```dart
fakeCentral.setServices(device.address, [
    BleService(
    serviceUuid: '180D',
    characteristics: [
    BleCharacteristic(uuid: '2A37', address: device.address),
    ],
    ),
]);
```

This is useful when testing navigation to service/characteristic details after connecting.

## Where to See It in Action

See _scan_route_test.dart_ in the _example/_ directory for a full examples using:

- Name and service UUID filters
- Manufacturer ID and custom matchers
- Handling multiple results
- Avoiding duplicates

See _device_details_route_test.dart_ for testing connection state changes and service discovery.

## Summary

`FakeCentralMethodChannel` makes it easy to:

- Simulate full BLE flows for tests
- Validate UI logic and filtering
- Run tests on CI or simulators
- Develop BLE apps without real hardware

It’s a powerful tool built into the Flutter Splendid BLE plugin to ensure confidence and flexibility
in your BLE app development workflow.