import '../enums/storage_type.dart';
import '../utils/safe_parser.dart';
import '../utils/validators.dart';

/// File system storage volume information.
class StorageInfo {
  /// Mounting path or root directory (e.g. "/", "C:\", "/storage/emulated/0").
  final String? path;

  /// Display name or label of the storage volume.
  final String? name;

  /// Total capacity in bytes.
  final int? totalBytes;

  /// Used capacity in bytes.
  final int? usedBytes;

  /// Available/free capacity in bytes.
  final int? freeBytes;

  /// File system type (e.g., "ext4", "apfs", "NTFS", "FAT32").
  final String? fileSystem;

  /// Storage classification type.
  final StorageType type;

  const StorageInfo({
    this.path,
    this.name,
    this.totalBytes,
    this.usedBytes,
    this.freeBytes,
    this.fileSystem,
    this.type = StorageType.unknown,
  });

  /// Creates a [StorageInfo] from a native Map response.
  factory StorageInfo.fromMap(Map<String, dynamic> map) {
    final typeStr = SafeParser.parseString(map['type']);
    final total = Validators.validateNonNegativeInt(SafeParser.parseInt(map['totalBytes']));
    final free = Validators.validateNonNegativeInt(SafeParser.parseInt(map['freeBytes']));
    final used = Validators.validateNonNegativeInt(SafeParser.parseInt(map['usedBytes'])) ??
        (total != null && free != null ? total - free : null);

    return StorageInfo(
      path: SafeParser.parseString(map['path']),
      name: SafeParser.parseString(map['name']),
      totalBytes: total,
      usedBytes: used,
      freeBytes: free,
      fileSystem: SafeParser.parseString(map['fileSystem']),
      type: StorageTypeX.fromString(typeStr),
    );
  }

  /// Converts this model to a Map representation.
  Map<String, dynamic> toMap() {
    return {
      'path': path,
      'name': name,
      'totalBytes': totalBytes,
      'usedBytes': usedBytes,
      'freeBytes': freeBytes,
      'fileSystem': fileSystem,
      'type': type.name,
    };
  }

  StorageInfo copyWith({
    String? path,
    String? name,
    int? totalBytes,
    int? usedBytes,
    int? freeBytes,
    String? fileSystem,
    StorageType? type,
  }) {
    return StorageInfo(
      path: path ?? this.path,
      name: name ?? this.name,
      totalBytes: totalBytes ?? this.totalBytes,
      usedBytes: usedBytes ?? this.usedBytes,
      freeBytes: freeBytes ?? this.freeBytes,
      fileSystem: fileSystem ?? this.fileSystem,
      type: type ?? this.type,
    );
  }

  @override
  String toString() => 'StorageInfo(path: $path, total: $totalBytes, free: $freeBytes)';
}
