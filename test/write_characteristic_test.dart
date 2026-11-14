import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_splendid_ble/central/central_platform_interface.dart';
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
      value: utf8.encode('some_value'),
    );
  });

  test('writeBytes sends raw bytes above 0x7F unchanged', () async {
    MethodCall? received;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      received = call;
      return null;
    });
    final BleCharacteristic characteristic = BleCharacteristic(
      address: '00:00:00:00:00:01',
      uuid: '',
      properties: [],
      permissions: [],
    );
    CentralPlatformInterface.instance = methodChannelFlutterBle;

    await characteristic.writeBytes(bytes: <int>[0x01, 0xFF, 0x80]);

    expect(received?.method, 'writeCharacteristic');
    final Map<Object?, Object?> args =
        received!.arguments as Map<Object?, Object?>;
    expect(args['value'], isA<Uint8List>());
    expect(args['value'], <int>[0x01, 0xFF, 0x80]);
  });

  test('writeValue sends the UTF-8 encoding of the string', () async {
    MethodCall? received;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      received = call;
      return null;
    });
    final BleCharacteristic characteristic = BleCharacteristic(
      address: '00:00:00:00:00:01',
      uuid: '',
      properties: [],
      permissions: [],
    );
    CentralPlatformInterface.instance = methodChannelFlutterBle;

    await characteristic.writeValue(value: 'hi');

    final Map<Object?, Object?> args =
        received!.arguments as Map<Object?, Object?>;
    expect(args['value'], <int>[0x68, 0x69]);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
}
