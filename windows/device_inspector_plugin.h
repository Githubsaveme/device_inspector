#ifndef FLUTTER_PLUGIN_DEVICE_INSPECTOR_PLUGIN_H_
#define FLUTTER_PLUGIN_DEVICE_INSPECTOR_PLUGIN_H_

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif

#include <winsock2.h>
#include <ws2tcpip.h>
#include <windows.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace device_inspector {

class DeviceInspectorPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  DeviceInspectorPlugin();

  virtual ~DeviceInspectorPlugin();

  // Disallow copy and assign.
  DeviceInspectorPlugin(const DeviceInspectorPlugin&) = delete;
  DeviceInspectorPlugin& operator=(const DeviceInspectorPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace device_inspector

#endif  // FLUTTER_PLUGIN_DEVICE_INSPECTOR_PLUGIN_H_
