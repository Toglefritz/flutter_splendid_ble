#include "include/flutter_splendid_ble/flutter_splendid_ble_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "flutter_splendid_ble_plugin.h"

void FlutterSplendidBlePluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  flutter_splendid_ble::FlutterSplendidBlePlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
