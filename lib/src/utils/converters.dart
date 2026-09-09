import 'dart:math' as math;

/// Formatting and conversion utilities for units.
class Converters {
  const Converters._();

  /// Converts bytes to human-readable string (e.g., 1.5 GB).
  static String formatBytes(int? bytes, {int decimals = 2}) {
    if (bytes == null || bytes < 0) return 'N/A';
    if (bytes == 0) return '0 B';

    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];
    final i = (math.log(bytes) / math.log(1024)).floor();
    final clampedIdx = i.clamp(0, suffixes.length - 1);
    final value = bytes / math.pow(1024, clampedIdx);
    return '${value.toStringAsFixed(decimals)} ${suffixes[clampedIdx]}';
  }

  /// Converts MHz frequency to formatted GHz or MHz string.
  static String formatFrequency(double? mhz, {int decimals = 2}) {
    if (mhz == null || mhz <= 0) return 'N/A';
    if (mhz >= 1000) {
      return '${(mhz / 1000.0).toStringAsFixed(decimals)} GHz';
    }
    return '${mhz.toStringAsFixed(0)} MHz';
  }

  /// Formats percentage value.
  static String formatPercentage(double? percent, {int decimals = 1}) {
    if (percent == null || percent.isNaN) return 'N/A';
    return '${percent.clamp(0.0, 100.0).toStringAsFixed(decimals)}%';
  }

  /// Formats temperature in Celsius with optional conversion.
  static String formatTemperature(double? celsius, {bool useFahrenheit = false}) {
    if (celsius == null) return 'N/A';
    if (useFahrenheit) {
      final fahrenheit = (celsius * 9 / 5) + 32;
      return '${fahrenheit.toStringAsFixed(1)} °F';
    }
    return '${celsius.toStringAsFixed(1)} °C';
  }

  /// Formats duration into standard d, h, m, s string.
  static String formatUptime(int? uptimeSeconds) {
    if (uptimeSeconds == null || uptimeSeconds < 0) return 'N/A';
    final duration = Duration(seconds: uptimeSeconds);
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    final parts = <String>[];
    if (days > 0) parts.add('${days}d');
    if (hours > 0 || days > 0) parts.add('${hours}h');
    if (minutes > 0 || hours > 0 || days > 0) parts.add('${minutes}m');
    parts.add('${seconds}s');

    return parts.join(' ');
  }
}
