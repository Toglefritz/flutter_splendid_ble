import 'package:flutter_splendid_ble/central/fake_central_method_channel.dart';
import 'package:flutter_splendid_ble/central/models/ble_connection_event.dart';
import 'package:flutter_splendid_ble/central/models/ble_connection_state.dart';
import 'package:flutter_splendid_ble/central/splendid_ble_central.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for the observeConnectionState functionality.
///
/// This test suite verifies that passive connection state monitoring works correctly, allowing observation of
/// connection state changes without initiating a connection. The streams now emit [BleConnectionEvent] values, so the
/// tests assert on each event's [BleConnectionEvent.state].
void main() {
  group('observeConnectionState', () {
    late FakeCentralMethodChannel fakePlatform;
    late SplendidBleCentral splendidBle;

    setUp(() {
      fakePlatform = FakeCentralMethodChannel();
      splendidBle = SplendidBleCentral(platform: fakePlatform);
    });

    test(
        'should return a stream that emits connection state changes without connecting',
        () async {
      const String deviceAddress = 'AA:BB:CC:DD:EE:FF';

      // Set up passive monitoring (does not initiate connection)
      final Stream<BleConnectionEvent> stream =
          await splendidBle.observeConnectionState(
        deviceAddress: deviceAddress,
      );

      // Create a list to collect emitted events
      final List<BleConnectionEvent> emittedEvents = <BleConnectionEvent>[];

      // Listen to the stream
      final subscription = stream.listen(emittedEvents.add);

      // Wait for initial state emission
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Verify initial state is disconnected
      expect(emittedEvents.length, 1);
      expect(emittedEvents[0].state, BleConnectionState.disconnected);

      // Simulate external connection (not initiated by us)
      fakePlatform.simulateConnectionStateChange(
        deviceAddress,
        BleConnectionState.connected,
      );

      // Wait for state change to propagate
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Verify connected state was emitted
      expect(emittedEvents.length, 2);
      expect(emittedEvents[1].state, BleConnectionState.connected);

      // Simulate disconnection
      fakePlatform.simulateConnectionStateChange(
        deviceAddress,
        BleConnectionState.disconnected,
      );

      // Wait for state change to propagate
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Verify disconnected state was emitted
      expect(emittedEvents.length, 3);
      expect(emittedEvents[2].state, BleConnectionState.disconnected);

      // Clean up
      await subscription.cancel();
    });

    test('should work independently from connect()', () async {
      const String deviceAddress = 'AA:BB:CC:DD:EE:FF';

      // Set up passive monitoring first
      final Stream<BleConnectionEvent> observeStream =
          await splendidBle.observeConnectionState(
        deviceAddress: deviceAddress,
      );

      final List<BleConnectionState> observedStates = <BleConnectionState>[];
      final subscription1 = observeStream.listen(
        (BleConnectionEvent event) => observedStates.add(event.state),
      );

      // Wait for initial state
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Now call connect()
      final Stream<BleConnectionEvent> connectStream =
          await splendidBle.connect(
        deviceAddress: deviceAddress,
      );

      final List<BleConnectionState> connectStates = <BleConnectionState>[];
      final subscription2 = connectStream
          .listen((BleConnectionEvent event) => connectStates.add(event.state));

      // Wait for connection
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Both streams should have received the connected state
      expect(
        observedStates.contains(BleConnectionState.connected),
        true,
        reason: 'Observe stream should receive connected state',
      );
      expect(
        connectStates.contains(BleConnectionState.connected),
        true,
        reason: 'Connect stream should receive connected state',
      );

      // Clean up
      await subscription1.cancel();
      await subscription2.cancel();
    });

    test('should monitor multiple devices simultaneously', () async {
      const List<String> deviceAddresses = <String>[
        'AA:BB:CC:DD:EE:01',
        'AA:BB:CC:DD:EE:02',
        'AA:BB:CC:DD:EE:03',
      ];

      final Map<String, List<BleConnectionState>> statesByDevice =
          <String, List<BleConnectionState>>{};
      final List<dynamic> subscriptions = <dynamic>[];

      // Set up monitoring for all devices
      for (final String deviceAddress in deviceAddresses) {
        final Stream<BleConnectionEvent> stream =
            await splendidBle.observeConnectionState(
          deviceAddress: deviceAddress,
        );

        statesByDevice[deviceAddress] = <BleConnectionState>[];

        final subscription = stream.listen((BleConnectionEvent event) {
          statesByDevice[deviceAddress]!.add(event.state);
        });

        subscriptions.add(subscription);
      }

      // Wait for initial states
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Simulate connections for each device
      for (final String deviceAddress in deviceAddresses) {
        fakePlatform.simulateConnectionStateChange(
          deviceAddress,
          BleConnectionState.connected,
        );
      }

      // Wait for state changes
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Verify all devices received their connection state changes
      for (final String deviceAddress in deviceAddresses) {
        expect(
          statesByDevice[deviceAddress]!.contains(BleConnectionState.connected),
          true,
          reason: 'Device $deviceAddress should have received connected state',
        );
      }

      // Clean up
      for (final dynamic subscription in subscriptions) {
        // Ignore the dynamic call for testing purposes
        // ignore: avoid_dynamic_calls
        await subscription.cancel();
      }
    });

    test(
        'should receive same updates as connect() when both are used on same device',
        () async {
      const String deviceAddress = 'AA:BB:CC:DD:EE:FF';

      // Set up both monitoring and active connection
      final Stream<BleConnectionEvent> observeStream =
          await splendidBle.observeConnectionState(
        deviceAddress: deviceAddress,
      );

      final Stream<BleConnectionEvent> connectStream =
          await splendidBle.connect(
        deviceAddress: deviceAddress,
      );

      final List<BleConnectionState> observedStates = <BleConnectionState>[];
      final List<BleConnectionState> connectStates = <BleConnectionState>[];

      final subscription1 = observeStream.listen(
        (BleConnectionEvent event) => observedStates.add(event.state),
      );

      final subscription2 = connectStream.listen(
        (BleConnectionEvent event) => connectStates.add(event.state),
      );

      // Wait for all events to propagate
      await Future<void>.delayed(const Duration(milliseconds: 150));

      // Both should have received the same states (though possibly in different order)
      expect(
        observedStates.isNotEmpty,
        true,
        reason: 'Observe stream should have received states',
      );
      expect(
        connectStates.isNotEmpty,
        true,
        reason: 'Connect stream should have received states',
      );

      // Both should include connected state
      expect(observedStates.contains(BleConnectionState.connected), true);
      expect(connectStates.contains(BleConnectionState.connected), true);

      // Clean up
      await subscription1.cancel();
      await subscription2.cancel();
    });
  });
}
