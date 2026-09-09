//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <device_inspector/device_inspector_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) device_inspector_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "DeviceInspectorPlugin");
  device_inspector_plugin_register_with_registrar(device_inspector_registrar);
}
