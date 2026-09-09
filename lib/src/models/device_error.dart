/// Structured error codes for device_inspector operations.
enum DeviceErrorCode {
  unsupportedPlatform,
  unsupportedFeature,
  permissionDenied,
  nativeError,
  initializationFailed,
  invalidData,
  unavailable,
  timeout,
  unknown,
}

/// Structured exception thrown when a device inspection operation fails.
class DeviceInspectorException implements Exception {
  /// The error code categorization.
  final DeviceErrorCode code;

  /// Human-readable explanation of the error.
  final String message;

  /// Optional underlying cause or native exception string.
  final Object? cause;

  const DeviceInspectorException(
    this.code,
    this.message, {
    this.cause,
  });

  @override
  String toString() {
    if (cause != null) {
      return 'DeviceInspectorException([${code.name}]: $message, Cause: $cause)';
    }
    return 'DeviceInspectorException([${code.name}]: $message)';
  }
}
