import 'package:flutter_test/flutter_test.dart';
import 'package:device_inspector/device_inspector.dart';
import 'package:device_inspector/device_inspector_platform_interface.dart';
import 'package:device_inspector/device_inspector_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockDeviceInspectorPlatform
    with MockPlatformInterfaceMixin
    implements DeviceInspectorPlatform {
  @override
  Future<SystemInfo> getSystemInfo() async {
    return const SystemInfo(
      cpu: CpuInfo(name: 'Mock CPU', usagePercent: 15.0),
      memory: MemoryInfo(totalBytes: 8000000000, usagePercent: 40.0),
      capabilities: DeviceCapabilities(cpuInfo: true, memoryInfo: true),
    );
  }

  @override
  Future<CpuInfo> getCpuInfo() async => const CpuInfo(name: 'Mock CPU');

  @override
  Future<MemoryInfo> getMemoryInfo() async => const MemoryInfo(totalBytes: 8000000000);

  @override
  Future<GpuInfo> getGpuInfo() async => const GpuInfo(name: 'Mock GPU');

  @override
  Future<List<StorageInfo>> getStorageInfo() async => const [StorageInfo(path: '/', totalBytes: 100000000)];

  @override
  Future<BatteryInfo> getBatteryInfo() async => const BatteryInfo(levelPercent: 100.0, status: BatteryStatus.full);

  @override
  Future<DeviceInfo> getDeviceInfo() async => const DeviceInfo(model: 'Mock Device');

  @override
  Future<OsInfo> getOsInfo() async => const OsInfo(name: 'Mock OS', version: '1.0');

  @override
  Future<List<NetworkInfo>> getNetworkInfo() async => const [NetworkInfo(interfaceName: 'wlan0')];

  @override
  Future<List<SensorInfo>> getSensors() async => const [SensorInfo(type: SensorType.accelerometer, isAvailable: true)];

  @override
  Future<DeviceCapabilities> getCapabilities() async => const DeviceCapabilities(cpuInfo: true);

  @override
  Future<SystemMetrics> getSystemMetrics() async => SystemMetrics(
        timestamp: DateTime.now(),
        cpuUsagePercent: 15.0,
        memoryUsagePercent: 40.0,
      );

  @override
  Stream<SystemMetrics> watchMetrics({Duration interval = const Duration(seconds: 1)}) {
    return Stream.value(
      SystemMetrics(
        timestamp: DateTime.now(),
        cpuUsagePercent: 15.0,
      ),
    );
  }
}

void main() {
  final DeviceInspectorPlatform initialPlatform = DeviceInspectorPlatform.instance;

  test('$MethodChannelDeviceInspector is default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelDeviceInspector>());
  });

  test('DeviceInspector public facade calls platform instance', () async {
    final mock = MockDeviceInspectorPlatform();
    DeviceInspectorPlatform.instance = mock;

    final info = await DeviceInspector.getInfo();
    expect(info.cpu?.name, equals('Mock CPU'));

    final cpu = await DeviceInspector.getCpuInfo();
    expect(cpu.name, equals('Mock CPU'));

    final mem = await DeviceInspector.getMemoryInfo();
    expect(mem.totalBytes, equals(8000000000));

    final battery = await DeviceInspector.getBatteryInfo();
    expect(battery.levelPercent, equals(100.0));

    final caps = await DeviceInspector.getCapabilities();
    expect(caps.cpuInfo, isTrue);

    final metrics = await DeviceInspector.getSystemMetrics();
    expect(metrics.cpuUsagePercent, equals(15.0));

    final streamValue = await DeviceInspector.watchMetrics().first;
    expect(streamValue.cpuUsagePercent, equals(15.0));
  });
}
