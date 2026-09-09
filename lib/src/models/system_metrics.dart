import '../utils/safe_parser.dart';
import '../utils/validators.dart';

/// Periodic dynamic system performance metrics snapshot.
class SystemMetrics {
  /// Timestamp of metric capture.
  final DateTime timestamp;

  /// Overall CPU utilization percentage (0.0 to 100.0).
  final double? cpuUsagePercent;

  /// Per-core CPU utilization percentages.
  final List<double> perCoreCpuUsagePercent;

  /// Memory usage percentage (0.0 to 100.0).
  final double? memoryUsagePercent;

  /// Available memory in bytes.
  final int? availableMemoryBytes;

  /// Current battery level percentage (0.0 to 100.0).
  final double? batteryLevelPercent;

  /// Whether battery is currently charging.
  final bool? isCharging;

  /// Available free primary storage in bytes.
  final int? storageFreeBytes;

  /// Network bytes received per second.
  final double? networkRxBytesPerSecond;

  /// Network bytes transmitted per second.
  final double? networkTxBytesPerSecond;

  const SystemMetrics({
    required this.timestamp,
    this.cpuUsagePercent,
    this.perCoreCpuUsagePercent = const [],
    this.memoryUsagePercent,
    this.availableMemoryBytes,
    this.batteryLevelPercent,
    this.isCharging,
    this.storageFreeBytes,
    this.networkRxBytesPerSecond,
    this.networkTxBytesPerSecond,
  });

  /// Creates a [SystemMetrics] from a native Map response.
  factory SystemMetrics.fromMap(Map<String, dynamic> map) {
    final rawTimestamp = SafeParser.parseInt(map['timestamp']);
    final dt = rawTimestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(rawTimestamp)
        : DateTime.now();

    final perCoreList = <double>[];
    if (map['perCoreCpuUsagePercent'] is List) {
      for (final val in (map['perCoreCpuUsagePercent'] as List)) {
        final parsed = Validators.clampPercentage(SafeParser.parseDouble(val));
        if (parsed != null) perCoreList.add(parsed);
      }
    }

    return SystemMetrics(
      timestamp: dt,
      cpuUsagePercent: Validators.clampPercentage(SafeParser.parseDouble(map['cpuUsagePercent'])),
      perCoreCpuUsagePercent: List.unmodifiable(perCoreList),
      memoryUsagePercent: Validators.clampPercentage(SafeParser.parseDouble(map['memoryUsagePercent'])),
      availableMemoryBytes: Validators.validateNonNegativeInt(SafeParser.parseInt(map['availableMemoryBytes'])),
      batteryLevelPercent: Validators.clampPercentage(SafeParser.parseDouble(map['batteryLevelPercent'])),
      isCharging: SafeParser.parseBool(map['isCharging']),
      storageFreeBytes: Validators.validateNonNegativeInt(SafeParser.parseInt(map['storageFreeBytes'])),
      networkRxBytesPerSecond: SafeParser.parseDouble(map['networkRxBytesPerSecond']),
      networkTxBytesPerSecond: SafeParser.parseDouble(map['networkTxBytesPerSecond']),
    );
  }

  /// Converts this model to a Map representation.
  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.millisecondsSinceEpoch,
      'cpuUsagePercent': cpuUsagePercent,
      'perCoreCpuUsagePercent': perCoreCpuUsagePercent,
      'memoryUsagePercent': memoryUsagePercent,
      'availableMemoryBytes': availableMemoryBytes,
      'batteryLevelPercent': batteryLevelPercent,
      'isCharging': isCharging,
      'storageFreeBytes': storageFreeBytes,
      'networkRxBytesPerSecond': networkRxBytesPerSecond,
      'networkTxBytesPerSecond': networkTxBytesPerSecond,
    };
  }

  @override
  String toString() => 'SystemMetrics(cpu: $cpuUsagePercent%, ram: $memoryUsagePercent%, battery: $batteryLevelPercent%)';
}
