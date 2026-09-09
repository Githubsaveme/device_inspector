import '../utils/safe_parser.dart';
import 'battery_info.dart';
import 'capabilities.dart';
import 'cpu_info.dart';
import 'device_info.dart';
import 'gpu_info.dart';
import 'memory_info.dart';
import 'network_info.dart';
import 'os_info.dart';
import 'sensor_info.dart';
import 'storage_info.dart';

/// Aggregated system specifications and metrics snapshot.
class SystemInfo {
  /// Processor hardware details.
  final CpuInfo? cpu;

  /// RAM and swap memory status.
  final MemoryInfo? memory;

  /// Graphics processing unit details.
  final GpuInfo? gpu;

  /// Storage volumes list.
  final List<StorageInfo> storage;

  /// Battery status and capacity.
  final BatteryInfo? battery;

  /// Hardware device metadata.
  final DeviceInfo? device;

  /// Operating system details.
  final OsInfo? os;

  /// Active network interfaces list.
  final List<NetworkInfo> network;

  /// Hardware sensors list.
  final List<SensorInfo> sensors;

  /// Feature capability support flags.
  final DeviceCapabilities? capabilities;

  const SystemInfo({
    this.cpu,
    this.memory,
    this.gpu,
    this.storage = const [],
    this.battery,
    this.device,
    this.os,
    this.network = const [],
    this.sensors = const [],
    this.capabilities,
  });

  /// Creates a [SystemInfo] from a native Map response.
  factory SystemInfo.fromMap(Map<String, dynamic> map) {
    return SystemInfo(
      cpu: map['cpu'] is Map ? CpuInfo.fromMap((map['cpu'] as Map).cast<String, dynamic>()) : null,
      memory: map['memory'] is Map ? MemoryInfo.fromMap((map['memory'] as Map).cast<String, dynamic>()) : null,
      gpu: map['gpu'] is Map ? GpuInfo.fromMap((map['gpu'] as Map).cast<String, dynamic>()) : null,
      storage: SafeParser.parseList<StorageInfo>(map['storage'], (m) => StorageInfo.fromMap(m)),
      battery: map['battery'] is Map ? BatteryInfo.fromMap((map['battery'] as Map).cast<String, dynamic>()) : null,
      device: map['device'] is Map ? DeviceInfo.fromMap((map['device'] as Map).cast<String, dynamic>()) : null,
      os: map['os'] is Map ? OsInfo.fromMap((map['os'] as Map).cast<String, dynamic>()) : null,
      network: SafeParser.parseList<NetworkInfo>(map['network'], (m) => NetworkInfo.fromMap(m)),
      sensors: SafeParser.parseList<SensorInfo>(map['sensors'], (m) => SensorInfo.fromMap(m)),
      capabilities: map['capabilities'] is Map
          ? DeviceCapabilities.fromMap((map['capabilities'] as Map).cast<String, dynamic>())
          : null,
    );
  }

  /// Converts this model to a Map representation.
  Map<String, dynamic> toMap() {
    return {
      'cpu': cpu?.toMap(),
      'memory': memory?.toMap(),
      'gpu': gpu?.toMap(),
      'storage': storage.map((s) => s.toMap()).toList(),
      'battery': battery?.toMap(),
      'device': device?.toMap(),
      'os': os?.toMap(),
      'network': network.map((n) => n.toMap()).toList(),
      'sensors': sensors.map((s) => s.toMap()).toList(),
      'capabilities': capabilities?.toMap(),
    };
  }

  @override
  String toString() {
    return 'SystemInfo(cpu: ${cpu?.name}, memory: ${memory?.totalBytes}, device: ${device?.model})';
  }
}
