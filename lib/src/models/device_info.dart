import '../utils/safe_parser.dart';
import '../utils/validators.dart';

/// Device hardware metadata and state.
class DeviceInfo {
  /// Device manufacturer (e.g. "Google", "Samsung", "Apple Inc.", "Dell").
  final String? manufacturer;

  /// Hardware model identifier (e.g., "Pixel 7 Pro", "iPhone14,2", "MacBookPro18,1").
  final String? model;

  /// User-defined device name (e.g. "John's MacBook Pro").
  final String? deviceName;

  /// Network host name.
  final String? hostName;

  /// Architecture name (e.g., "arm64", "x86_64").
  final String? architecture;

  /// Operating system name.
  final String? osName;

  /// Operating system version.
  final String? osVersion;

  /// Operating system kernel version.
  final String? kernelVersion;

  /// Operating system build number.
  final String? buildNumber;

  /// System uptime in seconds.
  final int? uptimeSeconds;

  const DeviceInfo({
    this.manufacturer,
    this.model,
    this.deviceName,
    this.hostName,
    this.architecture,
    this.osName,
    this.osVersion,
    this.kernelVersion,
    this.buildNumber,
    this.uptimeSeconds,
  });

  /// Creates a [DeviceInfo] from a native Map response.
  factory DeviceInfo.fromMap(Map<String, dynamic> map) {
    return DeviceInfo(
      manufacturer: SafeParser.parseString(map['manufacturer']),
      model: SafeParser.parseString(map['model']),
      deviceName: SafeParser.parseString(map['deviceName']),
      hostName: SafeParser.parseString(map['hostName']),
      architecture: SafeParser.parseString(map['architecture']),
      osName: SafeParser.parseString(map['osName']),
      osVersion: SafeParser.parseString(map['osVersion']),
      kernelVersion: SafeParser.parseString(map['kernelVersion']),
      buildNumber: SafeParser.parseString(map['buildNumber']),
      uptimeSeconds: Validators.validateNonNegativeInt(SafeParser.parseInt(map['uptimeSeconds'])),
    );
  }

  /// Converts this model to a Map representation.
  Map<String, dynamic> toMap() {
    return {
      'manufacturer': manufacturer,
      'model': model,
      'deviceName': deviceName,
      'hostName': hostName,
      'architecture': architecture,
      'osName': osName,
      'osVersion': osVersion,
      'kernelVersion': kernelVersion,
      'buildNumber': buildNumber,
      'uptimeSeconds': uptimeSeconds,
    };
  }

  DeviceInfo copyWith({
    String? manufacturer,
    String? model,
    String? deviceName,
    String? hostName,
    String? architecture,
    String? osName,
    String? osVersion,
    String? kernelVersion,
    String? buildNumber,
    int? uptimeSeconds,
  }) {
    return DeviceInfo(
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      deviceName: deviceName ?? this.deviceName,
      hostName: hostName ?? this.hostName,
      architecture: architecture ?? this.architecture,
      osName: osName ?? this.osName,
      osVersion: osVersion ?? this.osVersion,
      kernelVersion: kernelVersion ?? this.kernelVersion,
      buildNumber: buildNumber ?? this.buildNumber,
      uptimeSeconds: uptimeSeconds ?? this.uptimeSeconds,
    );
  }

  @override
  String toString() => 'DeviceInfo(manufacturer: $manufacturer, model: $model, uptime: ${uptimeSeconds}s)';
}
