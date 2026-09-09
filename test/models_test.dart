import 'package:flutter_test/flutter_test.dart';
import 'package:device_inspector/device_inspector.dart';

void main() {
  group('Model Serialization Tests', () {
    test('CpuInfo.fromMap & toMap', () {
      final map = {
        'name': 'Intel Core i7',
        'vendor': 'GenuineIntel',
        'architecture': 'x86_64',
        'physicalCores': 8,
        'logicalCores': 16,
        'is64Bit': true,
        'features': ['avx2', 'sse4_2'],
        'currentFrequencyMHz': 3200.0,
        'usagePercent': 25.5,
        'cores': [
          {
            'id': 0,
            'usagePercent': 30.0,
            'currentFrequencyMHz': 3200.0,
          }
        ]
      };

      final cpu = CpuInfo.fromMap(map);
      expect(cpu.name, equals('Intel Core i7'));
      expect(cpu.architecture, equals(CpuArchitecture.x86_64));
      expect(cpu.physicalCores, equals(8));
      expect(cpu.usagePercent, equals(25.5));
      expect(cpu.cores.length, equals(1));
      expect(cpu.cores.first.id, equals(0));

      final serialized = cpu.toMap();
      expect(serialized['name'], equals('Intel Core i7'));
      expect(serialized['architecture'], equals('x86_64'));
    });

    test('MemoryInfo.fromMap & toMap', () {
      final map = {
        'totalBytes': 16000000000,
        'usedBytes': 8000000000,
        'availableBytes': 8000000000,
        'usagePercent': 50.0,
      };

      final mem = MemoryInfo.fromMap(map);
      expect(mem.totalBytes, equals(16000000000));
      expect(mem.usagePercent, equals(50.0));

      final serialized = mem.toMap();
      expect(serialized['totalBytes'], equals(16000000000));
    });

    test('BatteryInfo.fromMap handles state mapping', () {
      final map = {
        'levelPercent': 85.0,
        'status': 'charging',
        'isCharging': true,
        'health': 'Good',
        'temperatureCelsius': 32.5,
      };

      final battery = BatteryInfo.fromMap(map);
      expect(battery.levelPercent, equals(85.0));
      expect(battery.status, equals(BatteryStatus.charging));
      expect(battery.isCharging, isTrue);
      expect(battery.temperatureCelsius, equals(32.5));
    });

    test('SystemInfo.fromMap aggregates all components', () {
      final map = {
        'cpu': {'name': 'Apple M1'},
        'memory': {'totalBytes': 17179869184},
        'battery': {'levelPercent': 90.0},
        'storage': [
          {'path': '/', 'totalBytes': 500000000000}
        ],
        'capabilities': {'cpuInfo': true, 'gpuInfo': true}
      };

      final sys = SystemInfo.fromMap(map);
      expect(sys.cpu?.name, equals('Apple M1'));
      expect(sys.memory?.totalBytes, equals(17179869184));
      expect(sys.battery?.levelPercent, equals(90.0));
      expect(sys.storage.length, equals(1));
      expect(sys.capabilities?.cpuInfo, isTrue);
    });

    test('DeviceInspectorException formats correctly', () {
      final ex = DeviceInspectorException(
        DeviceErrorCode.unsupportedFeature,
        'GPU monitoring unavailable on this hardware',
      );

      expect(ex.code, equals(DeviceErrorCode.unsupportedFeature));
      expect(ex.toString(), contains('unsupportedFeature'));
    });
  });
}
