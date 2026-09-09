/// Hardware sensor types.
enum SensorType {
  accelerometer,
  gyroscope,
  magnetometer,
  proximity,
  ambientLight,
  barometer,
  gravity,
  linearAcceleration,
  rotationVector,
  stepCounter,
  humidity,
  temperature,
  unknown,
}

/// Extension helpers for [SensorType].
extension SensorTypeX on SensorType {
  /// Parses [SensorType] from string representation.
  static SensorType fromString(String? value) {
    if (value == null) return SensorType.unknown;
    switch (value.toLowerCase().replaceAll('_', '').replaceAll('-', '').trim()) {
      case 'accelerometer':
        return SensorType.accelerometer;
      case 'gyroscope':
        return SensorType.gyroscope;
      case 'magnetometer':
        return SensorType.magnetometer;
      case 'proximity':
        return SensorType.proximity;
      case 'ambientlight':
      case 'light':
        return SensorType.ambientLight;
      case 'barometer':
      case 'pressure':
        return SensorType.barometer;
      case 'gravity':
        return SensorType.gravity;
      case 'linearacceleration':
        return SensorType.linearAcceleration;
      case 'rotationvector':
        return SensorType.rotationVector;
      case 'stepcounter':
        return SensorType.stepCounter;
      case 'humidity':
      case 'relativehumidity':
        return SensorType.humidity;
      case 'temperature':
      case 'ambienttemperature':
        return SensorType.temperature;
      default:
        return SensorType.unknown;
    }
  }
}
