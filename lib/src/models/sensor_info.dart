import '../enums/sensor_type.dart';
import '../utils/safe_parser.dart';

/// Physical hardware sensor availability and metadata.
class SensorInfo {
  /// Classification type of the sensor.
  final SensorType type;

  /// Sensor hardware model/name.
  final String? name;

  /// Sensor manufacturer or vendor.
  final String? vendor;

  /// Indicates whether the sensor is present and available on this device.
  final bool isAvailable;

  /// Power consumption in milliamperes (mA).
  final double? powerMilliAmperes;

  /// Sensor measurement resolution.
  final double? resolution;

  const SensorInfo({
    required this.type,
    this.name,
    this.vendor,
    this.isAvailable = false,
    this.powerMilliAmperes,
    this.resolution,
  });

  /// Creates a [SensorInfo] from a native Map response.
  factory SensorInfo.fromMap(Map<String, dynamic> map) {
    final typeStr = SafeParser.parseString(map['type']);
    return SensorInfo(
      type: SensorTypeX.fromString(typeStr),
      name: SafeParser.parseString(map['name']),
      vendor: SafeParser.parseString(map['vendor']),
      isAvailable: SafeParser.parseBool(map['isAvailable']) ?? false,
      powerMilliAmperes: SafeParser.parseDouble(map['powerMilliAmperes']),
      resolution: SafeParser.parseDouble(map['resolution']),
    );
  }

  /// Converts this model to a Map representation.
  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'name': name,
      'vendor': vendor,
      'isAvailable': isAvailable,
      'powerMilliAmperes': powerMilliAmperes,
      'resolution': resolution,
    };
  }

  SensorInfo copyWith({
    SensorType? type,
    String? name,
    String? vendor,
    bool? isAvailable,
    double? powerMilliAmperes,
    double? resolution,
  }) {
    return SensorInfo(
      type: type ?? this.type,
      name: name ?? this.name,
      vendor: vendor ?? this.vendor,
      isAvailable: isAvailable ?? this.isAvailable,
      powerMilliAmperes: powerMilliAmperes ?? this.powerMilliAmperes,
      resolution: resolution ?? this.resolution,
    );
  }

  @override
  String toString() => 'SensorInfo(type: ${type.name}, name: $name, available: $isAvailable)';
}
