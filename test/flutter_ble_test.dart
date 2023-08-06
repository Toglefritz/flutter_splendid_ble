import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ble/flutter_ble.dart';
import 'package:flutter_ble/flutter_ble_platform_interface.dart';
import 'package:flutter_ble/flutter_ble_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterBlePlatform
    with MockPlatformInterfaceMixin
    implements FlutterBlePlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FlutterBlePlatform initialPlatform = FlutterBlePlatform.instance;

  test('$MethodChannelFlutterBle is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterBle>());
  });

  test('getPlatformVersion', () async {
    FlutterBle flutterBlePlugin = FlutterBle();
    MockFlutterBlePlatform fakePlatform = MockFlutterBlePlatform();
    FlutterBlePlatform.instance = fakePlatform;

    expect(await flutterBlePlugin.getPlatformVersion(), '42');
  });
}
