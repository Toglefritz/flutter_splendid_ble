#ifndef FLUTTER_PLUGIN_FLUTTER_SPLENDID_BLE_PLUGIN_H_
#define FLUTTER_PLUGIN_FLUTTER_SPLENDID_BLE_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace flutter_splendid_ble {

class FlutterSplendidBlePlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  FlutterSplendidBlePlugin();

  virtual ~FlutterSplendidBlePlugin();

  // Disallow copy and assign.
  FlutterSplendidBlePlugin(const FlutterSplendidBlePlugin&) = delete;
  FlutterSplendidBlePlugin& operator=(const FlutterSplendidBlePlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace flutter_splendid_ble

#endif  // FLUTTER_PLUGIN_FLUTTER_SPLENDID_BLE_PLUGIN_H_
