import '../enums/cpu_architecture.dart';
import '../utils/safe_parser.dart';
import '../utils/validators.dart';
import 'cpu_core_info.dart';

/// Processor specifications and runtime performance metrics.
class CpuInfo {
  /// Processor brand or model name (e.g. "Intel(R) Core(TM) i7-10700K").
  final String? name;

  /// CPU vendor (e.g., "GenuineIntel", "AuthenticAMD", "Apple", "Qualcomm").
  final String? vendor;

  /// CPU instruction set architecture.
  final CpuArchitecture? architecture;

  /// Number of physical CPU cores.
  final int? physicalCores;

  /// Number of logical CPU cores / threads.
  final int? logicalCores;

  /// Indicates whether the processor is 64-bit capable.
  final bool? is64Bit;

  /// CPU hardware feature flags / extensions (e.g., "neon", "avx2", "sse4_2").
  final List<String> features;

  /// Level 1 cache size in bytes.
  final int? l1CacheBytes;

  /// Level 2 cache size in bytes.
  final int? l2CacheBytes;

  /// Level 3 cache size in bytes.
  final int? l3CacheBytes;

  /// Current overall CPU clock frequency in MHz.
  final double? currentFrequencyMHz;

  /// Minimum CPU clock frequency in MHz.
  final double? minFrequencyMHz;

  /// Maximum CPU clock frequency in MHz.
  final double? maxFrequencyMHz;

  /// Overall CPU usage percentage (0.0 to 100.0).
  final double? usagePercent;

  /// Individual core information and metrics.
  final List<CpuCoreInfo> cores;

  const CpuInfo({
    this.name,
    this.vendor,
    this.architecture,
    this.physicalCores,
    this.logicalCores,
    this.is64Bit,
    this.features = const [],
    this.l1CacheBytes,
    this.l2CacheBytes,
    this.l3CacheBytes,
    this.currentFrequencyMHz,
    this.minFrequencyMHz,
    this.maxFrequencyMHz,
    this.usagePercent,
    this.cores = const [],
  });

  /// Creates a [CpuInfo] from a native Map response.
  factory CpuInfo.fromMap(Map<String, dynamic> map) {
    final archString = SafeParser.parseString(map['architecture']);
    final arch = archString != null
        ? CpuArchitectureX.fromString(archString)
        : null;

    final coresList = SafeParser.parseList<CpuCoreInfo>(
      map['cores'],
      (coreMap) => CpuCoreInfo.fromMap(coreMap),
    );

    return CpuInfo(
      name: SafeParser.parseString(map['name']),
      vendor: SafeParser.parseString(map['vendor']),
      architecture: arch,
      physicalCores: Validators.validateNonNegativeInt(SafeParser.parseInt(map['physicalCores'])),
      logicalCores: Validators.validateNonNegativeInt(SafeParser.parseInt(map['logicalCores'])),
      is64Bit: SafeParser.parseBool(map['is64Bit']),
      features: SafeParser.parseStringList(map['features']),
      l1CacheBytes: Validators.validateNonNegativeInt(SafeParser.parseInt(map['l1CacheBytes'])),
      l2CacheBytes: Validators.validateNonNegativeInt(SafeParser.parseInt(map['l2CacheBytes'])),
      l3CacheBytes: Validators.validateNonNegativeInt(SafeParser.parseInt(map['l3CacheBytes'])),
      currentFrequencyMHz: Validators.validateFrequency(SafeParser.parseDouble(map['currentFrequencyMHz'])),
      minFrequencyMHz: Validators.validateFrequency(SafeParser.parseDouble(map['minFrequencyMHz'])),
      maxFrequencyMHz: Validators.validateFrequency(SafeParser.parseDouble(map['maxFrequencyMHz'])),
      usagePercent: Validators.clampPercentage(SafeParser.parseDouble(map['usagePercent'])),
      cores: coresList,
    );
  }

  /// Converts this model to a Map representation.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'vendor': vendor,
      'architecture': architecture?.name,
      'physicalCores': physicalCores,
      'logicalCores': logicalCores,
      'is64Bit': is64Bit,
      'features': features,
      'l1CacheBytes': l1CacheBytes,
      'l2CacheBytes': l2CacheBytes,
      'l3CacheBytes': l3CacheBytes,
      'currentFrequencyMHz': currentFrequencyMHz,
      'minFrequencyMHz': minFrequencyMHz,
      'maxFrequencyMHz': maxFrequencyMHz,
      'usagePercent': usagePercent,
      'cores': cores.map((c) => c.toMap()).toList(),
    };
  }

  CpuInfo copyWith({
    String? name,
    String? vendor,
    CpuArchitecture? architecture,
    int? physicalCores,
    int? logicalCores,
    bool? is64Bit,
    List<String>? features,
    int? l1CacheBytes,
    int? l2CacheBytes,
    int? l3CacheBytes,
    double? currentFrequencyMHz,
    double? minFrequencyMHz,
    double? maxFrequencyMHz,
    double? usagePercent,
    List<CpuCoreInfo>? cores,
  }) {
    return CpuInfo(
      name: name ?? this.name,
      vendor: vendor ?? this.vendor,
      architecture: architecture ?? this.architecture,
      physicalCores: physicalCores ?? this.physicalCores,
      logicalCores: logicalCores ?? this.logicalCores,
      is64Bit: is64Bit ?? this.is64Bit,
      features: features ?? this.features,
      l1CacheBytes: l1CacheBytes ?? this.l1CacheBytes,
      l2CacheBytes: l2CacheBytes ?? this.l2CacheBytes,
      l3CacheBytes: l3CacheBytes ?? this.l3CacheBytes,
      currentFrequencyMHz: currentFrequencyMHz ?? this.currentFrequencyMHz,
      minFrequencyMHz: minFrequencyMHz ?? this.minFrequencyMHz,
      maxFrequencyMHz: maxFrequencyMHz ?? this.maxFrequencyMHz,
      usagePercent: usagePercent ?? this.usagePercent,
      cores: cores ?? this.cores,
    );
  }

  @override
  String toString() => 'CpuInfo(name: $name, cores: $physicalCores/$logicalCores, usage: $usagePercent%)';
}
