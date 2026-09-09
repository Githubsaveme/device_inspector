/// Battery charging status.
enum BatteryStatus {
  charging,
  discharging,
  full,
  notCharging,
  unknown,
}

/// Extension helpers for [BatteryStatus].
extension BatteryStatusX on BatteryStatus {
  /// Parses [BatteryStatus] from string representation.
  static BatteryStatus fromString(String? value) {
    if (value == null) return BatteryStatus.unknown;
    switch (value.toLowerCase().trim()) {
      case 'charging':
        return BatteryStatus.charging;
      case 'discharging':
        return BatteryStatus.discharging;
      case 'full':
        return BatteryStatus.full;
      case 'notcharging':
      case 'not_charging':
        return BatteryStatus.notCharging;
      default:
        return BatteryStatus.unknown;
    }
  }
}
