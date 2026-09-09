import '../utils/safe_parser.dart';
import '../utils/validators.dart';

/// Graphics Processing Unit (GPU) specifications.
class GpuInfo {
  /// GPU adapter or chipset name.
  final String? name;

  /// Vendor name (e.g., "NVIDIA", "AMD", "Intel", "Apple", "ARM", "Qualcomm").
  final String? vendor;

  /// Renderer description (e.g., "Mali-G78", "Apple M1", "ANGLE Direct3D11").
  final String? renderer;

  /// Installed GPU driver version.
  final String? driverVersion;

  /// Dedicated video RAM in bytes.
  final int? vramBytes;

  /// Supported graphics APIs (e.g. ["Vulkan 1.3", "OpenGL ES 3.2", "Metal 3"]).
  final List<String> graphicsApis;

  /// Indicates whether GPU is discrete (dedicated) or integrated.
  final bool? isDiscrete;

  const GpuInfo({
    this.name,
    this.vendor,
    this.renderer,
    this.driverVersion,
    this.vramBytes,
    this.graphicsApis = const [],
    this.isDiscrete,
  });

  /// Creates a [GpuInfo] from a native Map response.
  factory GpuInfo.fromMap(Map<String, dynamic> map) {
    return GpuInfo(
      name: SafeParser.parseString(map['name']),
      vendor: SafeParser.parseString(map['vendor']),
      renderer: SafeParser.parseString(map['renderer']),
      driverVersion: SafeParser.parseString(map['driverVersion']),
      vramBytes: Validators.validateNonNegativeInt(SafeParser.parseInt(map['vramBytes'])),
      graphicsApis: SafeParser.parseStringList(map['graphicsApis']),
      isDiscrete: SafeParser.parseBool(map['isDiscrete']),
    );
  }

  /// Converts this model to a Map representation.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'vendor': vendor,
      'renderer': renderer,
      'driverVersion': driverVersion,
      'vramBytes': vramBytes,
      'graphicsApis': graphicsApis,
      'isDiscrete': isDiscrete,
    };
  }

  GpuInfo copyWith({
    String? name,
    String? vendor,
    String? renderer,
    String? driverVersion,
    int? vramBytes,
    List<String>? graphicsApis,
    bool? isDiscrete,
  }) {
    return GpuInfo(
      name: name ?? this.name,
      vendor: vendor ?? this.vendor,
      renderer: renderer ?? this.renderer,
      driverVersion: driverVersion ?? this.driverVersion,
      vramBytes: vramBytes ?? this.vramBytes,
      graphicsApis: graphicsApis ?? this.graphicsApis,
      isDiscrete: isDiscrete ?? this.isDiscrete,
    );
  }

  @override
  String toString() => 'GpuInfo(name: $name, vendor: $vendor, vram: $vramBytes)';
}
