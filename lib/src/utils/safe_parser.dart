/// Utility methods for safely parsing values from dynamic native responses without crashing.
class SafeParser {
  const SafeParser._();

  /// Safely parses an integer or returns null.
  static int? parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final trimmed = value.trim();
      final parsed = int.tryParse(trimmed);
      if (parsed != null) return parsed;
      final parsedDouble = double.tryParse(trimmed);
      if (parsedDouble != null) return parsedDouble.toInt();
    }
    return null;
  }

  /// Safely parses a double or returns null.
  static double? parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value.isNaN ? null : value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value.trim());
      if (parsed != null && !parsed.isNaN) return parsed;
    }
    return null;
  }

  /// Safely parses a boolean or returns null.
  static bool? parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      final lower = value.trim().toLowerCase();
      if (lower == 'true' || lower == '1' || lower == 'yes') return true;
      if (lower == 'false' || lower == '0' || lower == 'no') return false;
    }
    return null;
  }

  /// Safely parses a string or returns null.
  static String? parseString(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    final str = value.toString().trim();
    return str.isEmpty ? null : str;
  }

  /// Safely parses a List of Strings.
  static List<String> parseStringList(dynamic value) {
    if (value == null) return const [];
    if (value is List) {
      return value
          .map((e) => parseString(e))
          .whereType<String>()
          .toList(growable: false);
    }
    if (value is String) {
      return value
          .split(RegExp(r'[\s,]+'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false);
    }
    return const [];
  }

  /// Safely parses a List of items using a mapper.
  static List<T> parseList<T>(dynamic value, T Function(Map<String, dynamic>) mapper) {
    if (value == null || value is! List) return const [];
    final list = <T>[];
    for (final item in value) {
      if (item is Map) {
        try {
          final map = item.cast<String, dynamic>();
          list.add(mapper(map));
        } catch (_) {
          // Ignore malformed list items gracefully
        }
      }
    }
    return List.unmodifiable(list);
  }
}
