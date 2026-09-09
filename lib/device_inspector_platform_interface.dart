import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'device_inspector_method_channel.dart';
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

abstract class DeviceInspectorPlatform extends PlatformInterface {
  /// Constructs a DeviceInspectorPlatform.
  DeviceInspectorPlatform() : super(token: _token);

  static final Object _token = Object();

  static DeviceInspectorPlatform _instance = MethodChannelDeviceInspector();

  /// The default instance of [DeviceInspectorPlatform] to use.
  static DeviceInspectorPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [DeviceInspectorPlatform].
  static set instance(DeviceInspectorPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<SystemInfo> getSystemInfo() {
    throw UnimplementedError('getSystemInfo() has not been implemented.');
  }

  Future<CpuInfo> getCpuInfo() {
    throw UnimplementedError('getCpuInfo() has not been implemented.');
  }

  Future<MemoryInfo> getMemoryInfo() {
    throw UnimplementedError('getMemoryInfo() has not been implemented.');
  }

  Future<GpuInfo> getGpuInfo() {
    throw UnimplementedError('getGpuInfo() has not been implemented.');
  }

  Future<List<StorageInfo>> getStorageInfo() {
    throw UnimplementedError('getStorageInfo() has not been implemented.');
  }

  Future<BatteryInfo> getBatteryInfo() {
    throw UnimplementedError('getBatteryInfo() has not been implemented.');
  }

  Future<DeviceInfo> getDeviceInfo() {
    throw UnimplementedError('getDeviceInfo() has not been implemented.');
  }

  Future<OsInfo> getOsInfo() {
    throw UnimplementedError('getOsInfo() has not been implemented.');
  }

  Future<List<NetworkInfo>> getNetworkInfo() {
    throw UnimplementedError('getNetworkInfo() has not been implemented.');
  }

  Future<List<SensorInfo>> getSensors() {
    throw UnimplementedError('getSensors() has not been implemented.');
  }

  Future<DeviceCapabilities> getCapabilities() {
    throw UnimplementedError('getCapabilities() has not been implemented.');
  }

  Future<SystemMetrics> getSystemMetrics() {
    throw UnimplementedError('getSystemMetrics() has not been implemented.');
  }

  Stream<SystemMetrics> watchMetrics({Duration interval = const Duration(seconds: 1)}) {
    throw UnimplementedError('watchMetrics() has not been implemented.');
  }
}
