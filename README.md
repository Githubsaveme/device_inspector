# device_inspector

A production-grade, cross-platform Flutter hardware and system diagnostics plugin.

`device_inspector` provides detailed **CPU, Memory, GPU, Battery, Storage, Network, Sensor, Device, OS information, and Live Performance Streaming** across **Android, iOS, Windows, Linux, and macOS**.

---

## 📸 Screenshots

### Desktop & Mobile Example Dashboard

| Windows Desktop Dashboard | Windows RAM Diagnostics |
| :---: | :---: |
| ![Windows Desktop Dashboard](
<img width="1920" height="1027" alt="Screenshot 2026-09-10 025551" src="https://github.com/user-attachments/assets/1d5fca80-99eb-4f39-90f4-c82b1c6bf0eb" />
) | ![Windows RAM Diagnostics](<img width="1916" height="1026" alt="Screenshot 2026-09-10 025505" src="https://github.com/user-attachments/assets/cee2fad4-1c93-4055-9b95-3b625a54e9f6" />
) |

| Mobile Dashboard (Android) | Mobile RAM Diagnostics |
| :---: | :---: |
| ![Mobile Dashboard](<img width="720" height="1280" alt="image" src="https://github.com/user-attachments/assets/9e556ab1-b44c-4081-a00e-f0f850a62604" />
) | ![Mobile RAM Diagnostics](<img width="720" height="1280" alt="image" src="https://github.com/user-attachments/assets/7add64cc-8ea4-4eb0-b0c3-d5893864ec0d" />
) |

---

## Features

- ⚡ **CPU Diagnostics**: Vendor, architecture, physical/logical core count, instruction flags, cache sizes, frequency, overall and per-core utilization %.
- 🧠 **Memory (RAM) Diagnostics**: Total, used, available, free physical memory and swap statistics.
- 🎮 **GPU Diagnostics**: Model name, renderer, vendor, driver version, VRAM capacity, graphics APIs (Vulkan, Metal, DirectX, OpenGL).
- 🔋 **Battery State**: Level %, status (charging/discharging/full), health, temperature, voltage, current (mA), and capacity (mAh).
- 💾 **Storage Volumes**: Volume names, paths, filesystem types, total, used, free space across internal/external drives.
- 🌐 **Network Interfaces**: Active interfaces (Wi-Fi, Ethernet, Cellular, VPN), IPv4/IPv6 addresses, status, and MAC addresses.
- 📡 **Hardware Sensors**: Sensor list, type classification, vendor, resolution, power consumption, availability state.
- 📱 **Device & OS Specs**: Manufacturer, model, user device name, kernel version, build number, and uptime.
- 📈 **Live Monitoring (`watchMetrics`)**: Cancelable stream for real-time CPU, RAM, battery, and storage metrics without blocking the UI thread.
- 🛡️ **Safe & Fault-Tolerant**: Safe null handling, capability detection, structured exception model (`DeviceInspectorException`).

---

## Platform Support

| Feature | Android | iOS | Windows | Linux | macOS |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **CPU Specs** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **CPU Usage %** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Per-Core Usage** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Memory (RAM)** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **GPU Info** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Storage Info** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Battery Info** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Network Info** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Sensors** | ✅ | ✅ | N/A | N/A | N/A |
| **Capabilities** | ✅ | ✅ | ✅ | ✅ | ✅ |

---

## Getting Started

Add `device_inspector` to your `pubspec.yaml`:

```yaml
dependencies:
  device_inspector: ^0.0.1
```

Import in Dart code:

```dart
import 'package:device_inspector/device_inspector.dart';
```

---

## Usage Examples

### 1. Retrieve Complete System Information

```dart
final info = await DeviceInspector.getInfo();

print('CPU: ${info.cpu?.name}');
print('Architecture: ${info.cpu?.architecture?.name}');
print('RAM Total: ${Converters.formatBytes(info.memory?.totalBytes)}');
print('Battery: ${info.battery?.levelPercent}%');
```

### 2. Retrieve Specific Hardware Metrics

```dart
// CPU Information
final cpu = await DeviceInspector.getCpuInfo();
print('Logical Cores: ${cpu.logicalCores}');
print('CPU Usage: ${cpu.usagePercent}%');

// Memory Information
final memory = await DeviceInspector.getMemoryInfo();
print('RAM Used: ${Converters.formatBytes(memory.usedBytes)}');

// Storage Volumes
final storageList = await DeviceInspector.getStorageInfo();
for (final volume in storageList) {
  print('${volume.name}: ${Converters.formatBytes(volume.freeBytes)} free');
}

// Battery Info
final battery = await DeviceInspector.getBatteryInfo();
print('Battery Charging: ${battery.isCharging}');
```

### 3. Real-Time Performance Monitoring (`watchMetrics`)

```dart
final subscription = DeviceInspector.watchMetrics(
  interval: const Duration(seconds: 1),
).listen((metrics) {
  print('Real-time CPU Usage: ${metrics.cpuUsagePercent}%');
  print('Real-time RAM Usage: ${metrics.memoryUsagePercent}%');
});

// Remember to cancel the subscription when done:
// subscription.cancel();
```

### 4. Platform Capability Detection

```dart
final capabilities = await DeviceInspector.getCapabilities();

if (capabilities.cpuFrequency) {
  print('CPU Frequency measurement supported!');
}
```

---

## Error Handling

`device_inspector` uses a structured exception model:

```dart
try {
  final cpu = await DeviceInspector.getCpuInfo();
} on DeviceInspectorException catch (e) {
  print('Error Code: ${e.code}');
  print('Message: ${e.message}');
}
```

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
