#include "device_inspector_plugin.h"

#include "include/device_inspector/device_inspector_plugin_c_api.h"
#include <flutter/plugin_registrar_windows.h>

void DeviceInspectorPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  device_inspector::DeviceInspectorPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
