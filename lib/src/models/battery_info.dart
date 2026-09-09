import '../enums/battery_status.dart';
import '../utils/safe_parser.dart';
import '../utils/validators.dart';

/// Battery state and diagnostics.
class BatteryInfo {
  /// Remaining charge percentage (0.0 to 100.0).
  final double? levelPercent;

  /// Charging state.
  final BatteryStatus status;

  /// Indicates whether the battery is currently plugged in and charging.
  final bool? isCharging;

  /// Health status description (e.g. "Good", "Overheat", "Dead").
  final String? health;

  /// Temperature in degrees Celsius.
  final double? temperatureCelsius;

  /// Voltage in Volts.
  final double? voltageVolts;

  /// Electric current in milliamperes (mA). Negative when discharging.
  final double? currentMilliAmperes;

  /// Nominal or current capacity in mAh.
  final int? capacityMilliAmpereHours;

  const BatteryInfo({
    this.levelPercent,
    this.status = BatteryStatus.unknown,
    this.isCharging,
    this.health,
    this.temperatureCelsius,
    this.voltageVolts,
    this.currentMilliAmperes,
    this.capacityMilliAmpereHours,
  });

  /// Creates a [BatteryInfo] from a native Map response.
  factory BatteryInfo.fromMap(Map<String, dynamic> map) {
    final statusStr = SafeParser.parseString(map['status']);
    final isChargingBool = SafeParser.parseBool(map['isCharging']);
    final parsedStatus = BatteryStatusX.fromString(statusStr);

    return BatteryInfo(
      levelPercent: Validators.clampPercentage(SafeParser.parseDouble(map['levelPercent'])),
      status: parsedStatus != BatteryStatus.unknown
          ? parsedStatus
          : (isChargingBool == true
              ? BatteryStatus.charging
              : (isChargingBool == false ? BatteryStatus.discharging : BatteryStatus.unknown)),
      isCharging: isChargingBool ?? (parsedStatus == BatteryStatus.charging),
      health: SafeParser.parseString(map['health']),
      temperatureCelsius: SafeParser.parseDouble(map['temperatureCelsius']),
      voltageVolts: SafeParser.parseDouble(map['voltageVolts']),
      currentMilliAmperes: SafeParser.parseDouble(map['currentMilliAmperes']),
      capacityMilliAmpereHours: Validators.validateNonNegativeInt(SafeParser.parseInt(map['capacityMilliAmpereHours'])),
    );
  }

  /// Converts this model to a Map representation.
  Map<String, dynamic> toMap() {
    return {
      'levelPercent': levelPercent,
      'status': status.name,
      'isCharging': isCharging,
      'health': health,
      'temperatureCelsius': temperatureCelsius,
      'voltageVolts': voltageVolts,
      'currentMilliAmperes': currentMilliAmperes,
      'capacityMilliAmpereHours': capacityMilliAmpereHours,
    };
  }

  BatteryInfo copyWith({
    double? levelPercent,
    BatteryStatus? status,
    bool? isCharging,
    String? health,
    double? temperatureCelsius,
    double? voltageVolts,
    double? currentMilliAmperes,
    int? capacityMilliAmpereHours,
  }) {
    return BatteryInfo(
      levelPercent: levelPercent ?? this.levelPercent,
      status: status ?? this.status,
      isCharging: isCharging ?? this.isCharging,
      health: health ?? this.health,
      temperatureCelsius: temperatureCelsius ?? this.temperatureCelsius,
      voltageVolts: voltageVolts ?? this.voltageVolts,
      currentMilliAmperes: currentMilliAmperes ?? this.currentMilliAmperes,
      capacityMilliAmpereHours: capacityMilliAmpereHours ?? this.capacityMilliAmpereHours,
    );
  }

  @override
  String toString() => 'BatteryInfo(level: $levelPercent%, charging: $isCharging, status: ${status.name})';
}
