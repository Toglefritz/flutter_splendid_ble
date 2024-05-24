import 'package:flutter/services.dart';
import 'package:flutter_splendid_ble/central/central_method_channel.dart';
import 'package:flutter_splendid_ble/central/models/ble_characteristic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('flutter_splendid_ble_central');
  final CentralMethodChannel methodChannelFlutterBle = CentralMethodChannel();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'writeCharacteristic') {
        return null; // Return null to simulate a successful operation
      }
      return null;
    });
  });

  test('Test writeCharacteristic method with success', () async {
    final characteristic = BleCharacteristic(
      address: '00:00:00:00:00:01',
      uuid: '',
      properties: [],
      permissions: [],
    );

    await methodChannelFlutterBle.writeCharacteristic(
      characteristic: characteristic,
      value: 'some_value',
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
}
