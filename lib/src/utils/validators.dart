/// Input validation helpers for system metrics and values.
class Validators {
  const Validators._();

  /// Clamps percentage to range 0.0 - 100.0 if not null.
  static double? clampPercentage(double? percentage) {
    if (percentage == null || percentage.isNaN) return null;
    return percentage.clamp(0.0, 100.0);
  }

  /// Ensures a non-negative byte/count value.
  static int? validateNonNegativeInt(int? value) {
    if (value == null || value < 0) return null;
    return value;
  }

  /// Ensures a non-negative frequency in MHz.
  static double? validateFrequency(double? mhz) {
    if (mhz == null || mhz < 0 || mhz.isNaN) return null;
    return mhz;
  }
}
