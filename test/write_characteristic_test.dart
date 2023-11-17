import 'package:flutter/services.dart';
import 'package:flutter_splendid_ble/flutter_splendid_ble_method_channel.dart';
import 'package:flutter_splendid_ble/models/ble_characteristic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('flutter_splendid_ble');
  final MethodChannelFlutterSplendidBle methodChannelFlutterBle =
      MethodChannelFlutterSplendidBle();

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

  test('Test writeCharacteristic method with exception', () async {
    final characteristic = BleCharacteristic(
      address: '00:00:00:00:00:01',
      uuid: '',
      properties: [],
      permissions: [],
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'writeCharacteristic') {
        throw PlatformException(
          code: 'ERROR',
          message: 'Error writing characteristic',
        );
      }
      return null;
    });

    expect(
      () async {
        await methodChannelFlutterBle.writeCharacteristic(
          characteristic: characteristic,
          value: 'test_value',
        );
      },
      throwsA(isA<PlatformException>()),
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
}
