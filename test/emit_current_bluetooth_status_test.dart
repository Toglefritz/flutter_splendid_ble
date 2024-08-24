import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_splendid_ble/central/central_method_channel.dart';
import 'package:flutter_splendid_ble/shared/models/bluetooth_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('flutter_splendid_ble_central');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'emitCurrentBluetoothStatus') {
        return null;
      }
      return null;
    });
  });

  test('emitCurrentBluetoothStatus emits correct BluetoothStatus', () async {
    final CentralMethodChannel methodChannelFlutterBle = CentralMethodChannel();

    // Create a list to hold emitted statuses
    final List<BluetoothStatus> emittedStatuses = <BluetoothStatus>[];

    final Stream<BluetoothStatus> statusStream =
        methodChannelFlutterBle.emitCurrentBluetoothStatus();

    // Listen to the stream and add emitted statuses to the list
    final StreamSubscription<BluetoothStatus> subscription =
        statusStream.listen(emittedStatuses.add);

    // Trigger the platform side to emit BluetoothStatus.enabled
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
      channel.name,
      const StandardMethodCodec()
          .encodeMethodCall(const MethodCall('adapterStateUpdated', 'enabled')),
      (ByteData? data) {},
    );

    // After a delay, change the emitted status to BluetoothStatus.disabled
    Future.delayed(const Duration(milliseconds: 100), () {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
        channel.name,
        const StandardMethodCodec().encodeMethodCall(
            const MethodCall('adapterStateUpdated', 'disabled'),),
        (ByteData? data) {},
      );
    });

    // After a delay, verify the emitted statuses
    await Future.delayed(const Duration(milliseconds: 200), () {
      expect(
          emittedStatuses, [BluetoothStatus.enabled, BluetoothStatus.disabled],);
      subscription.cancel();
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      channel,
      null,
    );
  });
}
