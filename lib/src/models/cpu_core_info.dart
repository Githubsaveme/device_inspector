import '../utils/safe_parser.dart';
import '../utils/validators.dart';

/// Detailed metrics for a single CPU core.
class CpuCoreInfo {
  /// Core identifier/index (e.g., 0, 1, 2...).
  final int id;

  /// Current usage percentage (0.0 to 100.0).
  final double? usagePercent;

  /// Current clock frequency in MHz.
  final double? currentFrequencyMHz;

  /// Minimum clock frequency supported in MHz.
  final double? minFrequencyMHz;

  /// Maximum clock frequency supported in MHz.
  final double? maxFrequencyMHz;

  const CpuCoreInfo({
    required this.id,
    this.usagePercent,
    this.currentFrequencyMHz,
    this.minFrequencyMHz,
    this.maxFrequencyMHz,
  });

  /// Creates a [CpuCoreInfo] from a native Map response.
  factory CpuCoreInfo.fromMap(Map<String, dynamic> map) {
    return CpuCoreInfo(
      id: SafeParser.parseInt(map['id']) ?? 0,
      usagePercent: Validators.clampPercentage(SafeParser.parseDouble(map['usagePercent'])),
      currentFrequencyMHz: Validators.validateFrequency(SafeParser.parseDouble(map['currentFrequencyMHz'])),
      minFrequencyMHz: Validators.validateFrequency(SafeParser.parseDouble(map['minFrequencyMHz'])),
      maxFrequencyMHz: Validators.validateFrequency(SafeParser.parseDouble(map['maxFrequencyMHz'])),
    );
  }

  /// Converts this model to a Map representation.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'usagePercent': usagePercent,
      'currentFrequencyMHz': currentFrequencyMHz,
      'minFrequencyMHz': minFrequencyMHz,
      'maxFrequencyMHz': maxFrequencyMHz,
    };
  }

  CpuCoreInfo copyWith({
    int? id,
    double? usagePercent,
    double? currentFrequencyMHz,
    double? minFrequencyMHz,
    double? maxFrequencyMHz,
  }) {
    return CpuCoreInfo(
      id: id ?? this.id,
      usagePercent: usagePercent ?? this.usagePercent,
      currentFrequencyMHz: currentFrequencyMHz ?? this.currentFrequencyMHz,
      minFrequencyMHz: minFrequencyMHz ?? this.minFrequencyMHz,
      maxFrequencyMHz: maxFrequencyMHz ?? this.maxFrequencyMHz,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CpuCoreInfo &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          usagePercent == other.usagePercent &&
          currentFrequencyMHz == other.currentFrequencyMHz &&
          minFrequencyMHz == other.minFrequencyMHz &&
          maxFrequencyMHz == other.maxFrequencyMHz;

  @override
  int get hashCode =>
      id.hashCode ^
      usagePercent.hashCode ^
      currentFrequencyMHz.hashCode ^
      minFrequencyMHz.hashCode ^
      maxFrequencyMHz.hashCode;

  @override
  String toString() {
    return 'CpuCoreInfo(id: $id, usagePercent: $usagePercent, currentFreq: ${currentFrequencyMHz}MHz)';
  }
}
