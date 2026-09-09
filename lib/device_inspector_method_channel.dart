import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'device_inspector_platform_interface.dart';
import 'src/models/battery_info.dart';
import 'src/models/capabilities.dart';
import 'src/models/cpu_info.dart';
import 'src/models/device_error.dart';
import 'src/models/device_info.dart';
import 'src/models/gpu_info.dart';
import 'src/models/memory_info.dart';
import 'src/models/network_info.dart';
import 'src/models/os_info.dart';
import 'src/models/sensor_info.dart';
import 'src/models/storage_info.dart';
import 'src/models/system_info.dart';
import 'src/models/system_metrics.dart';
import 'src/utils/safe_parser.dart';

/// An implementation of [DeviceInspectorPlatform] that uses method channels.
class MethodChannelDeviceInspector extends DeviceInspectorPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('device_inspector');

  @override
  Future<SystemInfo> getSystemInfo() async {
    try {
      final Map<dynamic, dynamic>? res = await methodChannel.invokeMethod('getSystemInfo');
      if (res == null) return const SystemInfo();
      return SystemInfo.fromMap(res.cast<String, dynamic>());
    } on PlatformException catch (e) {
      throw DeviceInspectorException(
        _mapErrorCode(e.code),
        e.message ?? 'Failed to get system info',
        cause: e,
      );
    } catch (e) {
      throw DeviceInspectorException(
        DeviceErrorCode.unknown,
        'Unexpected error getting system info: $e',
        cause: e,
      );
    }
  }

  @override
  Future<CpuInfo> getCpuInfo() async {
    try {
      final Map<dynamic, dynamic>? res = await methodChannel.invokeMethod('getCpuInfo');
      if (res == null) return const CpuInfo();
      return CpuInfo.fromMap(res.cast<String, dynamic>());
    } on PlatformException catch (e) {
      throw DeviceInspectorException(_mapErrorCode(e.code), e.message ?? 'Failed to get CPU info', cause: e);
    } catch (e) {
      return const CpuInfo();
    }
  }

  @override
  Future<MemoryInfo> getMemoryInfo() async {
    try {
      final Map<dynamic, dynamic>? res = await methodChannel.invokeMethod('getMemoryInfo');
      if (res == null) return const MemoryInfo();
      return MemoryInfo.fromMap(res.cast<String, dynamic>());
    } on PlatformException catch (e) {
      throw DeviceInspectorException(_mapErrorCode(e.code), e.message ?? 'Failed to get memory info', cause: e);
    } catch (e) {
      return const MemoryInfo();
    }
  }

  @override
  Future<GpuInfo> getGpuInfo() async {
    try {
      final Map<dynamic, dynamic>? res = await methodChannel.invokeMethod('getGpuInfo');
      if (res == null) return const GpuInfo();
      return GpuInfo.fromMap(res.cast<String, dynamic>());
    } on PlatformException catch (e) {
      throw DeviceInspectorException(_mapErrorCode(e.code), e.message ?? 'Failed to get GPU info', cause: e);
    } catch (e) {
      return const GpuInfo();
    }
  }

  @override
  Future<List<StorageInfo>> getStorageInfo() async {
    try {
      final List<dynamic>? res = await methodChannel.invokeListMethod('getStorageInfo');
      return SafeParser.parseList<StorageInfo>(res, (m) => StorageInfo.fromMap(m));
    } on PlatformException catch (e) {
      throw DeviceInspectorException(_mapErrorCode(e.code), e.message ?? 'Failed to get storage info', cause: e);
    } catch (e) {
      return const [];
    }
  }

  @override
  Future<BatteryInfo> getBatteryInfo() async {
    try {
      final Map<dynamic, dynamic>? res = await methodChannel.invokeMethod('getBatteryInfo');
      if (res == null) return const BatteryInfo();
      return BatteryInfo.fromMap(res.cast<String, dynamic>());
    } on PlatformException catch (e) {
      throw DeviceInspectorException(_mapErrorCode(e.code), e.message ?? 'Failed to get battery info', cause: e);
    } catch (e) {
      return const BatteryInfo();
    }
  }

  @override
  Future<DeviceInfo> getDeviceInfo() async {
    try {
      final Map<dynamic, dynamic>? res = await methodChannel.invokeMethod('getDeviceInfo');
      if (res == null) return const DeviceInfo();
      return DeviceInfo.fromMap(res.cast<String, dynamic>());
    } on PlatformException catch (e) {
      throw DeviceInspectorException(_mapErrorCode(e.code), e.message ?? 'Failed to get device info', cause: e);
    } catch (e) {
      return const DeviceInfo();
    }
  }

  @override
  Future<OsInfo> getOsInfo() async {
    try {
      final Map<dynamic, dynamic>? res = await methodChannel.invokeMethod('getOsInfo');
      if (res == null) return const OsInfo();
      return OsInfo.fromMap(res.cast<String, dynamic>());
    } on PlatformException catch (e) {
      throw DeviceInspectorException(_mapErrorCode(e.code), e.message ?? 'Failed to get OS info', cause: e);
    } catch (e) {
      return const OsInfo();
    }
  }

  @override
  Future<List<NetworkInfo>> getNetworkInfo() async {
    try {
      final List<dynamic>? res = await methodChannel.invokeListMethod('getNetworkInfo');
      return SafeParser.parseList<NetworkInfo>(res, (m) => NetworkInfo.fromMap(m));
    } on PlatformException catch (e) {
      throw DeviceInspectorException(_mapErrorCode(e.code), e.message ?? 'Failed to get network info', cause: e);
    } catch (e) {
      return const [];
    }
  }

  @override
  Future<List<SensorInfo>> getSensors() async {
    try {
      final List<dynamic>? res = await methodChannel.invokeListMethod('getSensors');
      return SafeParser.parseList<SensorInfo>(res, (m) => SensorInfo.fromMap(m));
    } on PlatformException catch (e) {
      throw DeviceInspectorException(_mapErrorCode(e.code), e.message ?? 'Failed to get sensors', cause: e);
    } catch (e) {
      return const [];
    }
  }

  @override
  Future<DeviceCapabilities> getCapabilities() async {
    try {
      final Map<dynamic, dynamic>? res = await methodChannel.invokeMethod('getCapabilities');
      if (res == null) return const DeviceCapabilities();
      return DeviceCapabilities.fromMap(res.cast<String, dynamic>());
    } on PlatformException catch (e) {
      throw DeviceInspectorException(_mapErrorCode(e.code), e.message ?? 'Failed to get capabilities', cause: e);
    } catch (e) {
      return const DeviceCapabilities();
    }
  }

  @override
  Future<SystemMetrics> getSystemMetrics() async {
    try {
      final Map<dynamic, dynamic>? res = await methodChannel.invokeMethod('getSystemMetrics');
      if (res == null) return SystemMetrics(timestamp: DateTime.now());
      return SystemMetrics.fromMap(res.cast<String, dynamic>());
    } on PlatformException catch (e) {
      throw DeviceInspectorException(_mapErrorCode(e.code), e.message ?? 'Failed to get system metrics', cause: e);
    } catch (e) {
      return SystemMetrics(timestamp: DateTime.now());
    }
  }

  @override
  Stream<SystemMetrics> watchMetrics({Duration interval = const Duration(seconds: 1)}) {
    late StreamController<SystemMetrics> controller;
    Timer? timer;

    void tick() async {
      try {
        final metrics = await getSystemMetrics();
        if (!controller.isClosed) {
          controller.add(metrics);
        }
      } catch (e, st) {
        if (!controller.isClosed) {
          controller.addError(e, st);
        }
      }
    }

    controller = StreamController<SystemMetrics>.broadcast(
      onListen: () {
        tick(); // immediate first capture
        timer = Timer.periodic(interval, (_) => tick());
      },
      onCancel: () {
        timer?.cancel();
        timer = null;
      },
    );

    return controller.stream;
  }

  DeviceErrorCode _mapErrorCode(String code) {
    switch (code) {
      case 'UNSUPPORTED_PLATFORM':
        return DeviceErrorCode.unsupportedPlatform;
      case 'UNSUPPORTED_FEATURE':
        return DeviceErrorCode.unsupportedFeature;
      case 'PERMISSION_DENIED':
        return DeviceErrorCode.permissionDenied;
      case 'INITIALIZATION_FAILED':
        return DeviceErrorCode.initializationFailed;
      case 'INVALID_DATA':
        return DeviceErrorCode.invalidData;
      case 'UNAVAILABLE':
        return DeviceErrorCode.unavailable;
      case 'TIMEOUT':
        return DeviceErrorCode.timeout;
      default:
        return DeviceErrorCode.nativeError;
    }
  }
}
