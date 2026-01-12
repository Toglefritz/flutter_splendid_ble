import 'package:flutter_splendid_ble/central/fake_central_method_channel.dart';
import 'package:flutter_splendid_ble/central/models/ble_connection_state.dart';
import 'package:flutter_splendid_ble/central/splendid_ble_central.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for the observeConnectionState functionality.
///
/// This test suite verifies that passive connection state monitoring works correctly,
/// allowing observation of connection state changes without initiating a connection.
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
      final Stream<BleConnectionState> stream =
          await splendidBle.observeConnectionState(
        deviceAddress: deviceAddress,
      );

      // Create a list to collect emitted states
      final List<BleConnectionState> emittedStates = <BleConnectionState>[];

      // Listen to the stream
      final subscription = stream.listen(emittedStates.add);

      // Wait for initial state emission
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Verify initial state is disconnected
      expect(emittedStates.length, 1);
      expect(emittedStates[0], BleConnectionState.disconnected);

      // Simulate external connection (not initiated by us)
      fakePlatform.simulateConnectionStateChange(
        deviceAddress,
        BleConnectionState.connected,
      );

      // Wait for state change to propagate
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Verify connected state was emitted
      expect(emittedStates.length, 2);
      expect(emittedStates[1], BleConnectionState.connected);

      // Simulate disconnection
      fakePlatform.simulateConnectionStateChange(
        deviceAddress,
        BleConnectionState.disconnected,
      );

      // Wait for state change to propagate
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Verify disconnected state was emitted
      expect(emittedStates.length, 3);
      expect(emittedStates[2], BleConnectionState.disconnected);

      // Clean up
      await subscription.cancel();
    });

    test('should work independently from connect()', () async {
      const String deviceAddress = 'AA:BB:CC:DD:EE:FF';

      // Set up passive monitoring first
      final Stream<BleConnectionState> observeStream =
          await splendidBle.observeConnectionState(
        deviceAddress: deviceAddress,
      );

      final List<BleConnectionState> observedStates = <BleConnectionState>[];
      final subscription1 = observeStream.listen(observedStates.add);

      // Wait for initial state
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Now call connect()
      final Stream<BleConnectionState> connectStream =
          await splendidBle.connect(
        deviceAddress: deviceAddress,
      );

      final List<BleConnectionState> connectStates = <BleConnectionState>[];
      final subscription2 = connectStream.listen(connectStates.add);

      // Wait for connection
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Both streams should have received the connected state
      expect(
          observedStates.contains(BleConnectionState.connected), true,
          reason: 'Observe stream should receive connected state',);
      expect(
          connectStates.contains(BleConnectionState.connected), true,
          reason: 'Connect stream should receive connected state',);

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
        final Stream<BleConnectionState> stream =
            await splendidBle.observeConnectionState(
          deviceAddress: deviceAddress,
        );

        statesByDevice[deviceAddress] = <BleConnectionState>[];

        final subscription = stream.listen((BleConnectionState state) {
          statesByDevice[deviceAddress]!.add(state);
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
            statesByDevice[deviceAddress]!
                .contains(BleConnectionState.connected),
            true,
            reason: 'Device $deviceAddress should have received connected state',);
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
      final Stream<BleConnectionState> observeStream =
          await splendidBle.observeConnectionState(
        deviceAddress: deviceAddress,
      );

      final Stream<BleConnectionState> connectStream =
          await splendidBle.connect(
        deviceAddress: deviceAddress,
      );

      final List<BleConnectionState> observedStates = <BleConnectionState>[];
      final List<BleConnectionState> connectStates = <BleConnectionState>[];

      final subscription1 = observeStream.listen(observedStates.add);

      final subscription2 = connectStream.listen(connectStates.add);

      // Wait for all events to propagate
      await Future<void>.delayed(const Duration(milliseconds: 150));

      // Both should have received the same states (though possibly in different order)
      expect(observedStates.isNotEmpty, true,
          reason: 'Observe stream should have received states',);
      expect(connectStates.isNotEmpty, true,
          reason: 'Connect stream should have received states',);

      // Both should include connected state
      expect(observedStates.contains(BleConnectionState.connected), true);
      expect(connectStates.contains(BleConnectionState.connected), true);

      // Clean up
      await subscription1.cancel();
      await subscription2.cancel();
    });
  });
}
