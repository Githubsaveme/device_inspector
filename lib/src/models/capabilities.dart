import '../utils/safe_parser.dart';

/// Platform capability flags indicating which hardware metrics are supported.
class DeviceCapabilities {
  final bool cpuInfo;
  final bool cpuUsage;
  final bool cpuFrequency;
  final bool perCoreUsage;
  final bool gpuInfo;
  final bool memoryInfo;
  final bool storageInfo;
  final bool batteryInfo;
  final bool networkInfo;
  final bool sensorInfo;

  const DeviceCapabilities({
    this.cpuInfo = false,
    this.cpuUsage = false,
    this.cpuFrequency = false,
    this.perCoreUsage = false,
    this.gpuInfo = false,
    this.memoryInfo = false,
    this.storageInfo = false,
    this.batteryInfo = false,
    this.networkInfo = false,
    this.sensorInfo = false,
  });

  /// Creates a [DeviceCapabilities] from a native Map response.
  factory DeviceCapabilities.fromMap(Map<String, dynamic> map) {
    return DeviceCapabilities(
      cpuInfo: SafeParser.parseBool(map['cpuInfo']) ?? false,
      cpuUsage: SafeParser.parseBool(map['cpuUsage']) ?? false,
      cpuFrequency: SafeParser.parseBool(map['cpuFrequency']) ?? false,
      perCoreUsage: SafeParser.parseBool(map['perCoreUsage']) ?? false,
      gpuInfo: SafeParser.parseBool(map['gpuInfo']) ?? false,
      memoryInfo: SafeParser.parseBool(map['memoryInfo']) ?? false,
      storageInfo: SafeParser.parseBool(map['storageInfo']) ?? false,
      batteryInfo: SafeParser.parseBool(map['batteryInfo']) ?? false,
      networkInfo: SafeParser.parseBool(map['networkInfo']) ?? false,
      sensorInfo: SafeParser.parseBool(map['sensorInfo']) ?? false,
    );
  }

  /// Converts this model to a Map representation.
  Map<String, dynamic> toMap() {
    return {
      'cpuInfo': cpuInfo,
      'cpuUsage': cpuUsage,
      'cpuFrequency': cpuFrequency,
      'perCoreUsage': perCoreUsage,
      'gpuInfo': gpuInfo,
      'memoryInfo': memoryInfo,
      'storageInfo': storageInfo,
      'batteryInfo': batteryInfo,
      'networkInfo': networkInfo,
      'sensorInfo': sensorInfo,
    };
  }

  @override
  String toString() {
    return 'DeviceCapabilities(cpu: $cpuInfo, usage: $cpuUsage, gpu: $gpuInfo, ram: $memoryInfo, storage: $storageInfo, battery: $batteryInfo)';
  }
}
