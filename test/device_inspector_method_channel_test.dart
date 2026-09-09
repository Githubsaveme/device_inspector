import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:device_inspector/device_inspector_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final MethodChannelDeviceInspector platform = MethodChannelDeviceInspector();
  const MethodChannel channel = MethodChannel('device_inspector');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'getCpuInfo':
              return {'name': 'Test CPU', 'physicalCores': 4};
            case 'getMemoryInfo':
              return {'totalBytes': 16000000000, 'usagePercent': 30.0};
            case 'getGpuInfo':
              return {'name': 'Test GPU'};
            case 'getStorageInfo':
              return [
                {'path': '/', 'totalBytes': 500000000000}
              ];
            case 'getBatteryInfo':
              return {'levelPercent': 75.0, 'status': 'discharging'};
            case 'getDeviceInfo':
              return {'model': 'Test Model'};
            case 'getOsInfo':
              return {'name': 'Test OS'};
            case 'getNetworkInfo':
              return [
                {'interfaceName': 'eth0'}
              ];
            case 'getSensors':
              return [
                {'type': 'accelerometer', 'isAvailable': true}
              ];
            case 'getCapabilities':
              return {'cpuInfo': true, 'gpuInfo': true};
            case 'getSystemMetrics':
              return {'timestamp': 1600000000000, 'cpuUsagePercent': 20.0};
            case 'getSystemInfo':
              return {
                'cpu': {'name': 'Test CPU'},
                'memory': {'totalBytes': 16000000000},
              };
            default:
              return null;
          }
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('MethodChannelDeviceInspector queries method channel successfully', () async {
    final cpu = await platform.getCpuInfo();
    expect(cpu.name, equals('Test CPU'));
    expect(cpu.physicalCores, equals(4));

    final mem = await platform.getMemoryInfo();
    expect(mem.totalBytes, equals(16000000000));
    expect(mem.usagePercent, equals(30.0));

    final gpu = await platform.getGpuInfo();
    expect(gpu.name, equals('Test GPU'));

    final storage = await platform.getStorageInfo();
    expect(storage.length, equals(1));
    expect(storage.first.path, equals('/'));

    final battery = await platform.getBatteryInfo();
    expect(battery.levelPercent, equals(75.0));

    final sys = await platform.getSystemInfo();
    expect(sys.cpu?.name, equals('Test CPU'));
  });
}
