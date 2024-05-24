import 'package:flutter/services.dart';
import 'package:flutter_splendid_ble/central/central_method_channel.dart';
import 'package:flutter_splendid_ble/central/models/ble_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('flutter_splendid_ble_central');
  final CentralMethodChannel methodChannelFlutterBle = CentralMethodChannel();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      // Mock your native function if needed
      if (methodCall.method == 'discoverServices') {
        return 'success';
      }
      return null;
    });
  });

  test('Test discoverServices method', () async {
    final Stream<List<BleService>> serviceStream =
        methodChannelFlutterBle.discoverServices('00:00:00:00:00:01');
    final List<List<BleService>> emittedServices = [];

    // Listen to the emitted services
    serviceStream.listen((serviceList) {
      emittedServices.add(serviceList);
    });

    // Simulate services being discovered from the platform side
    final Map<String, List<Map>> fakeServices = {
      'service1_uuid': [
        {
          'address': '00:00:00:00:00:01',
          'uuid': 'char1',
          'properties': 0,
          'permissions': 0,
        },
        {
          'address': '00:00:00:00:00:01',
          'uuid': 'char2',
          'properties': 0,
          'permissions': 0,
        },
      ],
      'service2_uuid': [
        {
          'address': '00:00:00:00:00:01',
          'uuid': 'char3',
          'properties': 0,
          'permissions': 0,
        },
        {
          'address': '00:00:00:00:00:01',
          'uuid': 'char4',
          'properties': 0,
          'permissions': 0,
        },
      ],
    };

    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
      channel.name,
      channel.codec.encodeMethodCall(
          MethodCall('bleServicesDiscovered_00:00:00:00:00:01', fakeServices)),
      (ByteData? data) {},
    );

    // Validate the emitted services based on the fakeServices map.
    expect(emittedServices, isNotEmpty);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
}
