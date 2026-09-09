import '../utils/safe_parser.dart';
import '../utils/validators.dart';

/// System physical memory (RAM) and swap statistics.
class MemoryInfo {
  /// Total physical memory (RAM) in bytes.
  final int? totalBytes;

  /// Used physical memory in bytes.
  final int? usedBytes;

  /// Available physical memory for allocation in bytes.
  final int? availableBytes;

  /// Unallocated physical memory in bytes.
  final int? freeBytes;

  /// RAM usage percentage (0.0 to 100.0).
  final double? usagePercent;

  /// Total swap memory in bytes.
  final int? swapTotalBytes;

  /// Used swap memory in bytes.
  final int? swapUsedBytes;

  /// Free swap memory in bytes.
  final int? swapFreeBytes;

  const MemoryInfo({
    this.totalBytes,
    this.usedBytes,
    this.availableBytes,
    this.freeBytes,
    this.usagePercent,
    this.swapTotalBytes,
    this.swapUsedBytes,
    this.swapFreeBytes,
  });

  /// Creates a [MemoryInfo] from a native Map response.
  factory MemoryInfo.fromMap(Map<String, dynamic> map) {
    final total = Validators.validateNonNegativeInt(SafeParser.parseInt(map['totalBytes']));
    final used = Validators.validateNonNegativeInt(SafeParser.parseInt(map['usedBytes']));
    final avail = Validators.validateNonNegativeInt(SafeParser.parseInt(map['availableBytes']));
    final free = Validators.validateNonNegativeInt(SafeParser.parseInt(map['freeBytes']));

    double? usage = Validators.clampPercentage(SafeParser.parseDouble(map['usagePercent']));
    if (usage == null && total != null && total > 0) {
      if (used != null) {
        usage = (used / total) * 100.0;
      } else if (avail != null) {
        usage = ((total - avail) / total) * 100.0;
      }
    }

    return MemoryInfo(
      totalBytes: total,
      usedBytes: used ?? (total != null && avail != null ? total - avail : null),
      availableBytes: avail,
      freeBytes: free,
      usagePercent: Validators.clampPercentage(usage),
      swapTotalBytes: Validators.validateNonNegativeInt(SafeParser.parseInt(map['swapTotalBytes'])),
      swapUsedBytes: Validators.validateNonNegativeInt(SafeParser.parseInt(map['swapUsedBytes'])),
      swapFreeBytes: Validators.validateNonNegativeInt(SafeParser.parseInt(map['swapFreeBytes'])),
    );
  }

  /// Converts this model to a Map representation.
  Map<String, dynamic> toMap() {
    return {
      'totalBytes': totalBytes,
      'usedBytes': usedBytes,
      'availableBytes': availableBytes,
      'freeBytes': freeBytes,
      'usagePercent': usagePercent,
      'swapTotalBytes': swapTotalBytes,
      'swapUsedBytes': swapUsedBytes,
      'swapFreeBytes': swapFreeBytes,
    };
  }

  MemoryInfo copyWith({
    int? totalBytes,
    int? usedBytes,
    int? availableBytes,
    int? freeBytes,
    double? usagePercent,
    int? swapTotalBytes,
    int? swapUsedBytes,
    int? swapFreeBytes,
  }) {
    return MemoryInfo(
      totalBytes: totalBytes ?? this.totalBytes,
      usedBytes: usedBytes ?? this.usedBytes,
      availableBytes: availableBytes ?? this.availableBytes,
      freeBytes: freeBytes ?? this.freeBytes,
      usagePercent: usagePercent ?? this.usagePercent,
      swapTotalBytes: swapTotalBytes ?? this.swapTotalBytes,
      swapUsedBytes: swapUsedBytes ?? this.swapUsedBytes,
      swapFreeBytes: swapFreeBytes ?? this.swapFreeBytes,
    );
  }

  @override
  String toString() => 'MemoryInfo(total: $totalBytes, used: $usedBytes, usage: $usagePercent%)';
}
