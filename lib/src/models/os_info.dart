import '../utils/safe_parser.dart';

/// Operating system specification details.
class OsInfo {
  /// Operating system name (e.g., "Android", "iOS", "macOS", "Windows", "Linux").
  final String? name;

  /// Operating system release version (e.g. "14.0", "11.0.1", "22H2").
  final String? version;

  /// OS build identifier or release number.
  final String? buildNumber;

  /// Operating system kernel version string.
  final String? kernelVersion;

  /// Architecture name (e.g., "x86_64", "arm64").
  final String? architecture;

  /// System network hostname.
  final String? hostName;

  /// Indicates if the OS kernel/userland is 64-bit.
  final bool? is64Bit;

  const OsInfo({
    this.name,
    this.version,
    this.buildNumber,
    this.kernelVersion,
    this.architecture,
    this.hostName,
    this.is64Bit,
  });

  /// Creates an [OsInfo] from a native Map response.
  factory OsInfo.fromMap(Map<String, dynamic> map) {
    return OsInfo(
      name: SafeParser.parseString(map['name']),
      version: SafeParser.parseString(map['version']),
      buildNumber: SafeParser.parseString(map['buildNumber']),
      kernelVersion: SafeParser.parseString(map['kernelVersion']),
      architecture: SafeParser.parseString(map['architecture']),
      hostName: SafeParser.parseString(map['hostName']),
      is64Bit: SafeParser.parseBool(map['is64Bit']),
    );
  }

  /// Converts this model to a Map representation.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'version': version,
      'buildNumber': buildNumber,
      'kernelVersion': kernelVersion,
      'architecture': architecture,
      'hostName': hostName,
      'is64Bit': is64Bit,
    };
  }

  OsInfo copyWith({
    String? name,
    String? version,
    String? buildNumber,
    String? kernelVersion,
    String? architecture,
    String? hostName,
    bool? is64Bit,
  }) {
    return OsInfo(
      name: name ?? this.name,
      version: version ?? this.version,
      buildNumber: buildNumber ?? this.buildNumber,
      kernelVersion: kernelVersion ?? this.kernelVersion,
      architecture: architecture ?? this.architecture,
      hostName: hostName ?? this.hostName,
      is64Bit: is64Bit ?? this.is64Bit,
    );
  }

  @override
  String toString() => 'OsInfo(name: $name, version: $version, kernel: $kernelVersion)';
}
