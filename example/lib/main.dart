import 'dart:async';
import 'package:flutter/material.dart';
import 'package:device_inspector/device_inspector.dart';

void main() {
  runApp(const DeviceInspectorExampleApp());
}

class DeviceInspectorExampleApp extends StatelessWidget {
  const DeviceInspectorExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Device Inspector Example',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121218),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E1E2A),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: const MainInspectorScreen(),
    );
  }
}

class MainInspectorScreen extends StatefulWidget {
  const MainInspectorScreen({super.key});

  @override
  State<MainInspectorScreen> createState() => _MainInspectorScreenState();
}

class _MainInspectorScreenState extends State<MainInspectorScreen> {
  int _selectedIndex = 0;
  SystemInfo? _systemInfo;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchSystemInfo();
  }

  Future<void> _fetchSystemInfo() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final info = await DeviceInspector.getInfo();
      if (mounted) {
        setState(() {
          _systemInfo = info;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.developer_board, color: Colors.deepPurpleAccent),
            SizedBox(width: 12),
            Text('Device Inspector'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchSystemInfo,
            tooltip: 'Refresh System Info',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load hardware information',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _fetchSystemInfo,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        )
                      ],
                    ),
                  ),
                )
              : IndexedStack(
                  index: _selectedIndex,
                  children: [
                    DashboardTab(systemInfo: _systemInfo),
                    CpuTab(cpu: _systemInfo?.cpu),
                    MemoryTab(memory: _systemInfo?.memory),
                    GpuTab(gpu: _systemInfo?.gpu),
                    StorageTab(storage: _systemInfo?.storage ?? const []),
                    BatteryTab(battery: _systemInfo?.battery),
                    NetworkTab(network: _systemInfo?.network ?? const []),
                    SensorsTab(sensors: _systemInfo?.sensors ?? const []),
                    DeviceOsTab(device: _systemInfo?.device, os: _systemInfo?.os),
                    CapabilitiesTab(capabilities: _systemInfo?.capabilities),
                  ],
                ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.memory_outlined), selectedIcon: Icon(Icons.memory), label: 'CPU'),
          NavigationDestination(icon: Icon(Icons.storage_outlined), selectedIcon: Icon(Icons.storage), label: 'RAM'),
          NavigationDestination(icon: Icon(Icons.videogame_asset_outlined), selectedIcon: Icon(Icons.videogame_asset), label: 'GPU'),
          NavigationDestination(icon: Icon(Icons.sd_storage_outlined), selectedIcon: Icon(Icons.sd_storage), label: 'Storage'),
          NavigationDestination(icon: Icon(Icons.battery_charging_full_outlined), selectedIcon: Icon(Icons.battery_charging_full), label: 'Battery'),
          NavigationDestination(icon: Icon(Icons.wifi_outlined), selectedIcon: Icon(Icons.wifi), label: 'Network'),
          NavigationDestination(icon: Icon(Icons.sensors_outlined), selectedIcon: Icon(Icons.sensors), label: 'Sensors'),
          NavigationDestination(icon: Icon(Icons.devices_outlined), selectedIcon: Icon(Icons.devices), label: 'Device & OS'),
          NavigationDestination(icon: Icon(Icons.checklist_outlined), selectedIcon: Icon(Icons.checklist), label: 'Capabilities'),
        ],
      ),
    );
  }
}

/// 1. Dashboard Tab with Live Metrics Stream
class DashboardTab extends StatefulWidget {
  final SystemInfo? systemInfo;
  const DashboardTab({super.key, this.systemInfo});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  late Stream<SystemMetrics> _metricsStream;

  @override
  void initState() {
    super.initState();
    _metricsStream = DeviceInspector.watchMetrics(
      interval: const Duration(seconds: 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SystemMetrics>(
      stream: _metricsStream,
      builder: (context, snapshot) {
        final metrics = snapshot.data;
        final cpuUsage = metrics?.cpuUsagePercent ?? widget.systemInfo?.cpu?.usagePercent ?? 0.0;
        final ramUsage = metrics?.memoryUsagePercent ?? widget.systemInfo?.memory?.usagePercent ?? 0.0;
        final batteryLevel = metrics?.batteryLevelPercent ?? widget.systemInfo?.battery?.levelPercent ?? 0.0;
        final isCharging = metrics?.isCharging ?? widget.systemInfo?.battery?.isCharging ?? false;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: Colors.deepPurple.shade900.withValues(alpha: 0.4),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.systemInfo?.device?.model ?? 'System Overview',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green),
                          ),
                          child: const Row(
                            children: [
                              CircleAvatar(radius: 4, backgroundColor: Colors.green),
                              SizedBox(width: 6),
                              Text('LIVE', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.systemInfo?.os?.name ?? "OS"} ${widget.systemInfo?.os?.version ?? ""} (${widget.systemInfo?.cpu?.architecture?.name ?? ""})',
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _MetricCard(
                  title: 'CPU Usage',
                  value: Converters.formatPercentage(cpuUsage),
                  progress: cpuUsage / 100.0,
                  icon: Icons.memory,
                  color: Colors.orangeAccent,
                ),
                _MetricCard(
                  title: 'RAM Usage',
                  value: Converters.formatPercentage(ramUsage),
                  progress: ramUsage / 100.0,
                  subtitle: '${Converters.formatBytes(widget.systemInfo?.memory?.usedBytes)} / ${Converters.formatBytes(widget.systemInfo?.memory?.totalBytes)}',
                  icon: Icons.storage,
                  color: Colors.blueAccent,
                ),
                _MetricCard(
                  title: 'Battery',
                  value: Converters.formatPercentage(batteryLevel),
                  progress: batteryLevel / 100.0,
                  subtitle: isCharging ? 'Charging ⚡' : 'Discharging',
                  icon: isCharging ? Icons.battery_charging_full : Icons.battery_std,
                  color: Colors.greenAccent,
                ),
                _MetricCard(
                  title: 'CPU Speed',
                  value: Converters.formatFrequency(widget.systemInfo?.cpu?.currentFrequencyMHz),
                  progress: 0.8,
                  subtitle: '${widget.systemInfo?.cpu?.logicalCores ?? "-"} Logical Cores',
                  icon: Icons.speed,
                  color: Colors.purpleAccent,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _SectionHeader(title: 'Per-Core Usage (Live)', icon: Icons.grid_view),
            const SizedBox(height: 8),
            if (metrics?.perCoreCpuUsagePercent.isNotEmpty == true)
              Column(
                children: List.generate(
                  metrics!.perCoreCpuUsagePercent.length,
                  (index) => _CoreUsageBar(
                    coreId: index,
                    usagePercent: metrics.perCoreCpuUsagePercent[index],
                  ),
                ),
              )
            else if (widget.systemInfo?.cpu?.cores.isNotEmpty == true)
              Column(
                children: widget.systemInfo!.cpu!.cores
                    .map((c) => _CoreUsageBar(coreId: c.id, usagePercent: c.usagePercent ?? 0.0))
                    .toList(),
              )
            else
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Per-core usage metrics updating...'),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final double progress;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.progress,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
                Icon(icon, color: color, size: 22),
              ],
            ),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            if (subtitle != null) Text(subtitle!, style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              color: color,
              backgroundColor: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoreUsageBar extends StatelessWidget {
  final int coreId;
  final double usagePercent;

  const _CoreUsageBar({required this.coreId, required this.usagePercent});

  @override
  Widget build(BuildContext context) {
    final clamped = usagePercent.clamp(0.0, 100.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 60, child: Text('Core $coreId', style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
            child: LinearProgressIndicator(
              value: clamped / 100.0,
              minHeight: 12,
              borderRadius: BorderRadius.circular(6),
              color: clamped > 80 ? Colors.redAccent : (clamped > 50 ? Colors.orangeAccent : Colors.tealAccent),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 50,
            child: Text(
              Converters.formatPercentage(clamped),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

/// 2. CPU Tab
class CpuTab extends StatelessWidget {
  final CpuInfo? cpu;
  const CpuTab({super.key, this.cpu});

  @override
  Widget build(BuildContext context) {
    if (cpu == null) return const Center(child: Text('CPU Information Unavailable'));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoTile(label: 'Name', value: cpu!.name ?? 'N/A', icon: Icons.memory),
        _InfoTile(label: 'Vendor', value: cpu!.vendor ?? 'N/A', icon: Icons.business),
        _InfoTile(label: 'Architecture', value: cpu!.architecture?.name.toUpperCase() ?? 'N/A', icon: Icons.architecture),
        _InfoTile(label: 'Physical Cores', value: '${cpu!.physicalCores ?? "N/A"}', icon: Icons.hardware),
        _InfoTile(label: 'Logical Cores', value: '${cpu!.logicalCores ?? "N/A"}', icon: Icons.lan),
        _InfoTile(label: '64-Bit Architecture', value: cpu!.is64Bit == true ? 'Yes' : 'No', icon: Icons.check_circle_outline),
        _InfoTile(label: 'Current Frequency', value: Converters.formatFrequency(cpu!.currentFrequencyMHz), icon: Icons.speed),
        _InfoTile(label: 'Max Frequency', value: Converters.formatFrequency(cpu!.maxFrequencyMHz), icon: Icons.bolt),
        _InfoTile(label: 'L1 Cache', value: Converters.formatBytes(cpu!.l1CacheBytes), icon: Icons.cached),
        _InfoTile(label: 'L2 Cache', value: Converters.formatBytes(cpu!.l2CacheBytes), icon: Icons.cached),
        _InfoTile(label: 'L3 Cache', value: Converters.formatBytes(cpu!.l3CacheBytes), icon: Icons.cached),
        if (cpu!.features.isNotEmpty) ...[
          const SizedBox(height: 12),
          const _SectionHeader(title: 'CPU Features & Extension Flags', icon: Icons.extension),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: cpu!.features
                .map((f) => Chip(
                      label: Text(f, style: const TextStyle(fontSize: 12)),
                      backgroundColor: Colors.deepPurple.withValues(alpha: 0.2),
                    ))
                .toList(),
          ),
        ]
      ],
    );
  }
}

/// 3. Memory Tab
class MemoryTab extends StatelessWidget {
  final MemoryInfo? memory;
  const MemoryTab({super.key, this.memory});

  @override
  Widget build(BuildContext context) {
    if (memory == null) return const Center(child: Text('Memory Information Unavailable'));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text('Physical Memory (RAM)', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                CircularProgressIndicator(
                  value: (memory!.usagePercent ?? 0.0) / 100.0,
                  strokeWidth: 12,
                  backgroundColor: Colors.grey.shade800,
                ),
                const SizedBox(height: 16),
                Text(
                  Converters.formatPercentage(memory!.usagePercent),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _InfoTile(label: 'Total RAM', value: Converters.formatBytes(memory!.totalBytes), icon: Icons.storage),
        _InfoTile(label: 'Used RAM', value: Converters.formatBytes(memory!.usedBytes), icon: Icons.memory),
        _InfoTile(label: 'Available RAM', value: Converters.formatBytes(memory!.availableBytes), icon: Icons.event_available),
        _InfoTile(label: 'Free RAM', value: Converters.formatBytes(memory!.freeBytes), icon: Icons.cleaning_services),
        _InfoTile(label: 'Total Swap Memory', value: Converters.formatBytes(memory!.swapTotalBytes), icon: Icons.swap_horiz),
        _InfoTile(label: 'Used Swap Memory', value: Converters.formatBytes(memory!.swapUsedBytes), icon: Icons.swap_vert),
      ],
    );
  }
}

/// 4. GPU Tab
class GpuTab extends StatelessWidget {
  final GpuInfo? gpu;
  const GpuTab({super.key, this.gpu});

  @override
  Widget build(BuildContext context) {
    if (gpu == null) return const Center(child: Text('GPU Information Unavailable'));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoTile(label: 'GPU Name', value: gpu!.name ?? 'N/A', icon: Icons.videogame_asset),
        _InfoTile(label: 'Vendor', value: gpu!.vendor ?? 'N/A', icon: Icons.business),
        _InfoTile(label: 'Renderer', value: gpu!.renderer ?? 'N/A', icon: Icons.palette),
        _InfoTile(label: 'Driver Version', value: gpu!.driverVersion ?? 'N/A', icon: Icons.system_update),
        _InfoTile(label: 'VRAM Capacity', value: Converters.formatBytes(gpu!.vramBytes), icon: Icons.memory),
        _InfoTile(label: 'Discrete GPU', value: gpu!.isDiscrete == true ? 'Dedicated' : 'Integrated', icon: Icons.extension),
        if (gpu!.graphicsApis.isNotEmpty) ...[
          const SizedBox(height: 12),
          const _SectionHeader(title: 'Supported Graphics APIs', icon: Icons.code),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: gpu!.graphicsApis
                .map((api) => Chip(
                      label: Text(api),
                      backgroundColor: Colors.blue.withValues(alpha: 0.2),
                    ))
                .toList(),
          ),
        ]
      ],
    );
  }
}

/// 5. Storage Tab
class StorageTab extends StatelessWidget {
  final List<StorageInfo> storage;
  const StorageTab({super.key, required this.storage});

  @override
  Widget build(BuildContext context) {
    if (storage.isEmpty) return const Center(child: Text('Storage Volumes Unavailable'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: storage.length,
      itemBuilder: (context, index) {
        final volume = storage[index];
        final total = volume.totalBytes ?? 0;
        final used = volume.usedBytes ?? 0;
        final progress = total > 0 ? (used / total) : 0.0;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(volume.name ?? volume.path ?? 'Volume', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Chip(label: Text(volume.type.name.toUpperCase(), style: const TextStyle(fontSize: 10))),
                  ],
                ),
                Text('Path: ${volume.path ?? "N/A"}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 12),
                LinearProgressIndicator(value: progress, minHeight: 8, borderRadius: BorderRadius.circular(4)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Used: ${Converters.formatBytes(volume.usedBytes)}'),
                    Text('Free: ${Converters.formatBytes(volume.freeBytes)}'),
                    Text('Total: ${Converters.formatBytes(volume.totalBytes)}'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 6. Battery Tab
class BatteryTab extends StatelessWidget {
  final BatteryInfo? battery;
  const BatteryTab({super.key, this.battery});

  @override
  Widget build(BuildContext context) {
    if (battery == null) return const Center(child: Text('Battery Information Unavailable'));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoTile(label: 'Charge Level', value: Converters.formatPercentage(battery!.levelPercent), icon: Icons.battery_charging_full),
        _InfoTile(label: 'Status', value: battery!.status.name.toUpperCase(), icon: Icons.info_outline),
        _InfoTile(label: 'Is Charging', value: battery!.isCharging == true ? 'Plugged In ⚡' : 'Discharging', icon: Icons.power),
        _InfoTile(label: 'Health', value: battery!.health ?? 'N/A', icon: Icons.health_and_safety),
        _InfoTile(label: 'Temperature', value: Converters.formatTemperature(battery!.temperatureCelsius), icon: Icons.thermostat),
        _InfoTile(label: 'Voltage', value: battery!.voltageVolts != null ? '${battery!.voltageVolts!.toStringAsFixed(2)} V' : 'N/A', icon: Icons.bolt),
        _InfoTile(label: 'Current', value: battery!.currentMilliAmperes != null ? '${battery!.currentMilliAmperes!.toStringAsFixed(0)} mA' : 'N/A', icon: Icons.electric_meter),
        _InfoTile(label: 'Capacity', value: battery!.capacityMilliAmpereHours != null ? '${battery!.capacityMilliAmpereHours} mAh' : 'N/A', icon: Icons.battery_unknown),
      ],
    );
  }
}

/// 7. Network Tab
class NetworkTab extends StatelessWidget {
  final List<NetworkInfo> network;
  const NetworkTab({super.key, required this.network});

  @override
  Widget build(BuildContext context) {
    if (network.isEmpty) return const Center(child: Text('Network Interfaces Unavailable'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: network.length,
      itemBuilder: (context, index) {
        final net = network[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: Icon(net.interfaceType == 'wifi' ? Icons.wifi : Icons.lan, color: Colors.deepPurpleAccent),
            title: Text(net.interfaceName ?? 'Interface ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('IPv4: ${net.ipv4Address ?? "None"}'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _InfoRow(label: 'Type', value: net.interfaceType ?? 'N/A'),
                    _InfoRow(label: 'Status', value: net.status ?? 'N/A'),
                    _InfoRow(label: 'IPv4 Address', value: net.ipv4Address ?? 'N/A'),
                    _InfoRow(label: 'IPv6 Address', value: net.ipv6Address ?? 'N/A'),
                    _InfoRow(label: 'MAC Address', value: net.macAddress ?? 'Restricted'),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }
}

/// 8. Sensors Tab
class SensorsTab extends StatelessWidget {
  final List<SensorInfo> sensors;
  const SensorsTab({super.key, required this.sensors});

  @override
  Widget build(BuildContext context) {
    if (sensors.isEmpty) return const Center(child: Text('Hardware Sensors Unavailable / Not Present'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sensors.length,
      itemBuilder: (context, index) {
        final s = sensors[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.sensors, color: Colors.purpleAccent),
            title: Text(s.name ?? s.type.name.toUpperCase()),
            subtitle: Text('Vendor: ${s.vendor ?? "Generic"} | Type: ${s.type.name}'),
            trailing: Icon(
              s.isAvailable ? Icons.check_circle : Icons.cancel,
              color: s.isAvailable ? Colors.green : Colors.grey,
            ),
          ),
        );
      },
    );
  }
}

/// 9. Device & OS Tab
class DeviceOsTab extends StatelessWidget {
  final DeviceInfo? device;
  final OsInfo? os;

  const DeviceOsTab({super.key, this.device, this.os});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionHeader(title: 'Device Specifications', icon: Icons.devices),
        const SizedBox(height: 8),
        _InfoTile(label: 'Manufacturer', value: device?.manufacturer ?? 'N/A', icon: Icons.business),
        _InfoTile(label: 'Model', value: device?.model ?? 'N/A', icon: Icons.phone_android),
        _InfoTile(label: 'Device Name', value: device?.deviceName ?? 'N/A', icon: Icons.badge),
        _InfoTile(label: 'Host Name', value: device?.hostName ?? 'N/A', icon: Icons.dns),
        _InfoTile(label: 'Uptime', value: Converters.formatUptime(device?.uptimeSeconds), icon: Icons.timer),
        const SizedBox(height: 16),
        const _SectionHeader(title: 'Operating System Specifications', icon: Icons.settings_system_daydream),
        const SizedBox(height: 8),
        _InfoTile(label: 'OS Name', value: os?.name ?? 'N/A', icon: Icons.settings_suggest),
        _InfoTile(label: 'Release Version', value: os?.version ?? 'N/A', icon: Icons.build),
        _InfoTile(label: 'Kernel Version', value: os?.kernelVersion ?? 'N/A', icon: Icons.terminal),
        _InfoTile(label: 'Build Number', value: os?.buildNumber ?? 'N/A', icon: Icons.confirmation_number),
        _InfoTile(label: '64-Bit System', value: os?.is64Bit == true ? 'Yes' : 'No', icon: Icons.memory),
      ],
    );
  }
}

/// 10. Capabilities Tab
class CapabilitiesTab extends StatelessWidget {
  final DeviceCapabilities? capabilities;
  const CapabilitiesTab({super.key, this.capabilities});

  @override
  Widget build(BuildContext context) {
    if (capabilities == null) return const Center(child: Text('Capabilities Detection Unavailable'));
    final caps = [
      ('CPU Hardware Info', capabilities!.cpuInfo),
      ('CPU Utilization', capabilities!.cpuUsage),
      ('CPU Frequencies', capabilities!.cpuFrequency),
      ('Per-Core CPU Metrics', capabilities!.perCoreUsage),
      ('GPU Info', capabilities!.gpuInfo),
      ('Memory (RAM) Stats', capabilities!.memoryInfo),
      ('Storage Volumes', capabilities!.storageInfo),
      ('Battery Diagnostics', capabilities!.batteryInfo),
      ('Network Interfaces', capabilities!.networkInfo),
      ('Hardware Sensors', capabilities!.sensorInfo),
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: caps.length,
      itemBuilder: (context, index) {
        final cap = caps[index];
        return Card(
          child: ListTile(
            leading: Icon(
              cap.$2 ? Icons.check_circle : Icons.highlight_off,
              color: cap.$2 ? Colors.greenAccent : Colors.redAccent,
            ),
            title: Text(cap.$1, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(cap.$2 ? 'Supported on this platform' : 'Not supported / Restricted'),
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.deepPurpleAccent, size: 20),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurpleAccent)),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoTile({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.deepPurpleAccent),
        title: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        subtitle: Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
