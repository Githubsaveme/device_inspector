import 'dart:async';

import 'device_inspector_platform_interface.dart';
import 'src/models/battery_info.dart';
import 'src/models/capabilities.dart';
import 'src/models/cpu_info.dart';
import 'src/models/device_info.dart';
import 'src/models/gpu_info.dart';
import 'src/models/memory_info.dart';
import 'src/models/network_info.dart';
import 'src/models/os_info.dart';
import 'src/models/sensor_info.dart';
import 'src/models/storage_info.dart';
import 'src/models/system_info.dart';
import 'src/models/system_metrics.dart';

export 'src/enums/battery_status.dart';
export 'src/enums/cpu_architecture.dart';
export 'src/enums/sensor_type.dart';
export 'src/enums/storage_type.dart';
export 'src/models/battery_info.dart';
export 'src/models/capabilities.dart';
export 'src/models/cpu_core_info.dart';
export 'src/models/cpu_info.dart';
export 'src/models/device_error.dart';
export 'src/models/device_info.dart';
export 'src/models/gpu_info.dart';
export 'src/models/memory_info.dart';
export 'src/models/network_info.dart';
export 'src/models/os_info.dart';
export 'src/models/sensor_info.dart';
export 'src/models/storage_info.dart';
export 'src/models/system_info.dart';
export 'src/models/system_metrics.dart';
export 'src/utils/converters.dart';
export 'src/utils/safe_parser.dart';
export 'src/utils/validators.dart';

/// Main public interface for retrieving hardware, system, and live diagnostic information.
class DeviceInspector {
  const DeviceInspector._();

  /// Retrieves complete aggregated system information.
  static Future<SystemInfo> getInfo() {
    return DeviceInspectorPlatform.instance.getSystemInfo();
  }

  /// Retrieves CPU hardware specs and current performance state.
  static Future<CpuInfo> getCpuInfo() {
    return DeviceInspectorPlatform.instance.getCpuInfo();
  }

  /// Retrieves physical RAM and swap memory usage details.
  static Future<MemoryInfo> getMemoryInfo() {
    return DeviceInspectorPlatform.instance.getMemoryInfo();
  }

  /// Retrieves GPU hardware specs and graphics API support details.
  static Future<GpuInfo> getGpuInfo() {
    return DeviceInspectorPlatform.instance.getGpuInfo();
  }

  /// Retrieves details for all available storage volumes/drives.
  static Future<List<StorageInfo>> getStorageInfo() {
    return DeviceInspectorPlatform.instance.getStorageInfo();
  }

  /// Retrieves battery status, charge level, and power metrics.
  static Future<BatteryInfo> getBatteryInfo() {
    return DeviceInspectorPlatform.instance.getBatteryInfo();
  }

  /// Retrieves device model, manufacturer, hardware info, and uptime.
  static Future<DeviceInfo> getDeviceInfo() {
    return DeviceInspectorPlatform.instance.getDeviceInfo();
  }

  /// Retrieves OS release version, build number, and kernel specs.
  static Future<OsInfo> getOsInfo() {
    return DeviceInspectorPlatform.instance.getOsInfo();
  }

  /// Retrieves active network interfaces and IP configurations.
  static Future<List<NetworkInfo>> getNetworkInfo() {
    return DeviceInspectorPlatform.instance.getNetworkInfo();
  }

  /// Retrieves list of supported physical sensors on the device.
  static Future<List<SensorInfo>> getSensors() {
    return DeviceInspectorPlatform.instance.getSensors();
  }

  /// Retrieves feature support capabilities of the current platform.
  static Future<DeviceCapabilities> getCapabilities() {
    return DeviceInspectorPlatform.instance.getCapabilities();
  }

  /// Captures a single dynamic system metrics snapshot.
  static Future<SystemMetrics> getSystemMetrics() {
    return DeviceInspectorPlatform.instance.getSystemMetrics();
  }

  /// Continuously streams dynamic system metrics at the specified [interval].
  static Stream<SystemMetrics> watchMetrics({
    Duration interval = const Duration(seconds: 1),
  }) {
    return DeviceInspectorPlatform.instance.watchMetrics(interval: interval);
  }
}
