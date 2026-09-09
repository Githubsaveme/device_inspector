/// Storage volume type.
enum StorageType {
  internal,
  external,
  removable,
  network,
  unknown,
}

/// Extension helpers for [StorageType].
extension StorageTypeX on StorageType {
  /// Parses [StorageType] from string representation.
  static StorageType fromString(String? value) {
    if (value == null) return StorageType.unknown;
    switch (value.toLowerCase().trim()) {
      case 'internal':
        return StorageType.internal;
      case 'external':
        return StorageType.external;
      case 'removable':
        return StorageType.removable;
      case 'network':
        return StorageType.network;
      default:
        return StorageType.unknown;
    }
  }
}
