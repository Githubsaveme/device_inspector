#include "device_inspector_plugin.h"

#include <flutter/method_call.h>
#include <flutter/method_result_functions.h>
#include <flutter/standard_method_codec.h>
#include <gtest/gtest.h>

#include <memory>
#include <string>
#include <variant>

namespace device_inspector {
namespace test {

namespace {

using flutter::EncodableValue;
using flutter::MethodCall;
using flutter::MethodResultFunctions;

}  // namespace

TEST(DeviceInspectorPlugin, GetSystemInfo) {
  DeviceInspectorPlugin plugin;
  EncodableValue result_value;
  plugin.HandleMethodCall(
      MethodCall("getSystemInfo", std::make_unique<EncodableValue>()),
      std::make_unique<MethodResultFunctions<>>(
          [&result_value](const EncodableValue* result) {
            result_value = *result;
          },
          nullptr, nullptr));

  EXPECT_TRUE(std::holds_alternative<flutter::EncodableMap>(result_value));
}

}  // namespace test
}  // namespace device_inspector
