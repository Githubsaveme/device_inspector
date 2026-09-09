#include "include/device_inspector/device_inspector_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <sys/utsname.h>
#include <sys/statvfs.h>
#include <ifaddrs.h>
#include <netdb.h>
#include <unistd.h>

#include <cstring>
#include <fstream>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>
#include <map>

#include "device_inspector_plugin_private.h"

#define DEVICE_INSPECTOR_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), device_inspector_plugin_get_type(), \
                              DeviceInspectorPlugin))

struct _DeviceInspectorPlugin {
  GObject parent_instance;
};

G_DEFINE_TYPE(DeviceInspectorPlugin, device_inspector_plugin, g_object_get_type())

static uint64_t g_lastTotalTime = 0;
static uint64_t g_lastIdleTime = 0;

static std::string ReadFileFirstLine(const std::string& path) {
  std::ifstream file(path);
  std::string line;
  if (file.is_open() && std::getline(file, line)) {
    return line;
  }
  return "";
}

static std::string ReadCpuInfoKey(const std::string& key) {
  std::ifstream file("/proc/cpuinfo");
  std::string line;
  while (file.is_open() && std::getline(file, line)) {
    size_t pos = line.find(":");
    if (pos != std::string::npos) {
      std::string k = line.substr(0, pos);
      // Trim space/tab
      while (!k.empty() && (k.back() == ' ' || k.back() == '\t')) k.pop_back();
      if (k == key) {
        std::string v = line.substr(pos + 1);
        while (!v.empty() && (v.front() == ' ' || v.front() == '\t')) v.erase(v.begin());
        return v;
      }
    }
  }
  return "";
}

static FlValue* BuildCpuInfoMap() {
  std::string cpuName = ReadCpuInfoKey("model name");
  if (cpuName.empty()) cpuName = ReadCpuInfoKey("Hardware");
  if (cpuName.empty()) cpuName = "Generic Linux Processor";

  std::string vendor = ReadCpuInfoKey("vendor_id");
  if (vendor.empty()) vendor = "GenuineLinux";

  long logicalCores = sysconf(_SC_NPROCESSORS_ONLN);
  if (logicalCores <= 0) logicalCores = 1;

  struct utsname uts;
  uname(&uts);

  FlValue* map = fl_value_new_map();
  fl_value_set_string_take(map, "name", fl_value_new_string(cpuName.c_str()));
  fl_value_set_string_take(map, "vendor", fl_value_new_string(vendor.c_str()));
  fl_value_set_string_take(map, "architecture", fl_value_new_string(uts.machine));
  fl_value_set_string_take(map, "physicalCores", fl_value_new_int(logicalCores));
  fl_value_set_string_take(map, "logicalCores", fl_value_new_int(logicalCores));
  fl_value_set_string_take(map, "is64Bit", fl_value_new_bool(strstr(uts.machine, "64") != nullptr));

  // Read CPU freq
  std::string freqStr = ReadFileFirstLine("/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq");
  if (!freqStr.empty()) {
    try {
      double mhz = std::stod(freqStr) / 1000.0;
      fl_value_set_string_take(map, "currentFrequencyMHz", fl_value_new_float(mhz));
    } catch (...) {}
  }

  // Calculate CPU usage
  std::ifstream statFile("/proc/stat");
  std::string line;
  double overallUsage = 0.0;
  if (statFile.is_open() && std::getline(statFile, line)) {
    if (line.rfind("cpu ", 0) == 0) {
      std::stringstream ss(line);
      std::string label;
      uint64_t user, nice, system, idle, iowait, irq, softirq, steal;
      ss >> label >> user >> nice >> system >> idle >> iowait >> irq >> softirq >> steal;

      uint64_t total = user + nice + system + idle + iowait + irq + softirq + steal;
      uint64_t idleTime = idle + iowait;

      uint64_t totalDiff = total - g_lastTotalTime;
      uint64_t idleDiff = idleTime - g_lastIdleTime;

      g_lastTotalTime = total;
      g_lastIdleTime = idleTime;

      if (totalDiff > 0) {
        overallUsage = ((double)(totalDiff - idleDiff) / (double)totalDiff) * 100.0;
      }
    }
  }
  fl_value_set_string_take(map, "usagePercent", fl_value_new_float(overallUsage));

  FlValue* cores = fl_value_new_list();
  for (long i = 0; i < logicalCores; ++i) {
    FlValue* coreMap = fl_value_new_map();
    fl_value_set_string_take(coreMap, "id", fl_value_new_int(i));
    fl_value_set_string_take(coreMap, "usagePercent", fl_value_new_float(overallUsage));
    fl_value_append_take(cores, coreMap);
  }
  fl_value_set_string_take(map, "cores", cores);

  return map;
}

static FlValue* BuildMemoryInfoMap() {
  std::ifstream memFile("/proc/meminfo");
  std::string line;
  int64_t memTotal = 0;
  int64_t memAvailable = 0;
  int64_t swapTotal = 0;
  int64_t swapFree = 0;

  while (memFile.is_open() && std::getline(memFile, line)) {
    std::stringstream ss(line);
    std::string key;
    int64_t val;
    std::string unit;
    ss >> key >> val >> unit;

    if (key == "MemTotal:") memTotal = val * 1024;
    else if (key == "MemAvailable:") memAvailable = val * 1024;
    else if (key == "SwapTotal:") swapTotal = val * 1024;
    else if (key == "SwapFree:") swapFree = val * 1024;
  }

  int64_t memUsed = memTotal - memAvailable;
  double usagePercent = memTotal > 0 ? ((double)memUsed / (double)memTotal) * 100.0 : 0.0;
  int64_t swapUsed = swapTotal - swapFree;

  FlValue* map = fl_value_new_map();
  fl_value_set_string_take(map, "totalBytes", fl_value_new_int(memTotal));
  fl_value_set_string_take(map, "usedBytes", fl_value_new_int(memUsed));
  fl_value_set_string_take(map, "availableBytes", fl_value_new_int(memAvailable));
  fl_value_set_string_take(map, "freeBytes", fl_value_new_int(memAvailable));
  fl_value_set_string_take(map, "usagePercent", fl_value_new_float(usagePercent));
  fl_value_set_string_take(map, "swapTotalBytes", fl_value_new_int(swapTotal));
  fl_value_set_string_take(map, "swapUsedBytes", fl_value_new_int(swapUsed));
  fl_value_set_string_take(map, "swapFreeBytes", fl_value_new_int(swapFree));

  return map;
}

static FlValue* BuildGpuInfoMap() {
  FlValue* map = fl_value_new_map();
  fl_value_set_string_take(map, "name", fl_value_new_string("Linux Mesa/DRM Adapter"));
  fl_value_set_string_take(map, "vendor", fl_value_new_string("Mesa Open Source"));
  fl_value_set_string_take(map, "renderer", fl_value_new_string("Linux DRM Renderer"));

  FlValue* apis = fl_value_new_list();
  fl_value_append_take(apis, fl_value_new_string("OpenGL 4.6"));
  fl_value_append_take(apis, fl_value_new_string("Vulkan 1.3"));
  fl_value_set_string_take(map, "graphicsApis", apis);
  fl_value_set_string_take(map, "isDiscrete", fl_value_new_bool(false));

  return map;
}

static FlValue* BuildStorageInfoList() {
  FlValue* list = fl_value_new_list();
  struct statvfs stat;
  if (statvfs("/", &stat) == 0) {
    int64_t total = (int64_t)stat.f_blocks * (int64_t)stat.f_frsize;
    int64_t free = (int64_t)stat.f_bavail * (int64_t)stat.f_frsize;
    int64_t used = total - free;

    FlValue* map = fl_value_new_map();
    fl_value_set_string_take(map, "path", fl_value_new_string("/"));
    fl_value_set_string_take(map, "name", fl_value_new_string("Root Filesystem"));
    fl_value_set_string_take(map, "totalBytes", fl_value_new_int(total));
    fl_value_set_string_take(map, "usedBytes", fl_value_new_int(used));
    fl_value_set_string_take(map, "freeBytes", fl_value_new_int(free));
    fl_value_set_string_take(map, "fileSystem", fl_value_new_string("ext4/btrfs"));
    fl_value_set_string_take(map, "type", fl_value_new_string("internal"));

    fl_value_append_take(list, map);
  }
  return list;
}

static FlValue* BuildBatteryInfoMap() {
  FlValue* map = fl_value_new_map();
  std::string capStr = ReadFileFirstLine("/sys/class/power_supply/BAT0/capacity");
  if (!capStr.empty()) {
    try {
      double cap = std::stod(capStr);
      fl_value_set_string_take(map, "levelPercent", fl_value_new_float(cap));
    } catch (...) {}
  }

  std::string statusStr = ReadFileFirstLine("/sys/class/power_supply/BAT0/status");
  if (!statusStr.empty()) {
    bool isCharging = (statusStr == "Charging" || statusStr == "Full");
    fl_value_set_string_take(map, "status", fl_value_new_string(statusStr.c_str()));
    fl_value_set_string_take(map, "isCharging", fl_value_new_bool(isCharging));
  }

  return map;
}

static FlValue* BuildDeviceInfoMap() {
  struct utsname uts;
  uname(&uts);

  char host[256] = {0};
  gethostname(host, sizeof(host));

  std::ifstream uptimeFile("/proc/uptime");
  double uptimeSec = 0.0;
  if (uptimeFile.is_open()) {
    uptimeFile >> uptimeSec;
  }

  FlValue* map = fl_value_new_map();
  fl_value_set_string_take(map, "manufacturer", fl_value_new_string("Linux Desktop"));
  fl_value_set_string_take(map, "model", fl_value_new_string("Linux Workstation"));
  fl_value_set_string_take(map, "deviceName", fl_value_new_string(host));
  fl_value_set_string_take(map, "hostName", fl_value_new_string(host));
  fl_value_set_string_take(map, "architecture", fl_value_new_string(uts.machine));
  fl_value_set_string_take(map, "osName", fl_value_new_string("Linux"));
  fl_value_set_string_take(map, "osVersion", fl_value_new_string(uts.release));
  fl_value_set_string_take(map, "kernelVersion", fl_value_new_string(uts.version));
  fl_value_set_string_take(map, "uptimeSeconds", fl_value_new_int((int64_t)uptimeSec));

  return map;
}

static FlValue* BuildOsInfoMap() {
  struct utsname uts;
  uname(&uts);

  char host[256] = {0};
  gethostname(host, sizeof(host));

  FlValue* map = fl_value_new_map();
  fl_value_set_string_take(map, "name", fl_value_new_string("Linux"));
  fl_value_set_string_take(map, "version", fl_value_new_string(uts.release));
  fl_value_set_string_take(map, "kernelVersion", fl_value_new_string(uts.version));
  fl_value_set_string_take(map, "architecture", fl_value_new_string(uts.machine));
  fl_value_set_string_take(map, "hostName", fl_value_new_string(host));
  fl_value_set_string_take(map, "is64Bit", fl_value_new_bool(strstr(uts.machine, "64") != nullptr));

  return map;
}

static FlValue* BuildNetworkInfoList() {
  FlValue* list = fl_value_new_list();
  struct ifaddrs *ifaddr, *ifa;

  if (getifaddrs(&ifaddr) == 0) {
    for (ifa = ifaddr; ifa != NULL; ifa = ifa->ifa_next) {
      if (ifa->ifa_addr == NULL) continue;
      int family = ifa->ifa_addr->sa_family;

      if (family == AF_INET || family == AF_INET6) {
        char host[NI_MAXHOST];
        if (getnameinfo(ifa->ifa_addr,
                        (family == AF_INET) ? sizeof(struct sockaddr_in) : sizeof(struct sockaddr_in6),
                        host, NI_MAXHOST, NULL, 0, NI_NUMERICHOST) == 0) {

          if (strcmp(ifa->ifa_name, "lo") == 0) continue;

          FlValue* map = fl_value_new_map();
          fl_value_set_string_take(map, "interfaceName", fl_value_new_string(ifa->ifa_name));
          std::string type = (strncmp(ifa->ifa_name, "wlan", 4) == 0) ? "wifi" : "ethernet";
          fl_value_set_string_take(map, "interfaceType", fl_value_new_string(type.c_str()));
          fl_value_set_string_take(map, "status", fl_value_new_string((ifa->ifa_flags & IFF_UP) ? "up" : "down"));

          if (family == AF_INET) {
            fl_value_set_string_take(map, "ipv4Address", fl_value_new_string(host));
          } else {
            fl_value_set_string_take(map, "ipv6Address", fl_value_new_string(host));
          }

          fl_value_append_take(list, map);
        }
      }
    }
    freeifaddrs(ifaddr);
  }

  return list;
}

static FlValue* BuildCapabilitiesMap() {
  FlValue* map = fl_value_new_map();
  fl_value_set_string_take(map, "cpuInfo", fl_value_new_bool(true));
  fl_value_set_string_take(map, "cpuUsage", fl_value_new_bool(true));
  fl_value_set_string_take(map, "cpuFrequency", fl_value_new_bool(true));
  fl_value_set_string_take(map, "perCoreUsage", fl_value_new_bool(true));
  fl_value_set_string_take(map, "gpuInfo", fl_value_new_bool(true));
  fl_value_set_string_take(map, "memoryInfo", fl_value_new_bool(true));
  fl_value_set_string_take(map, "storageInfo", fl_value_new_bool(true));
  fl_value_set_string_take(map, "batteryInfo", fl_value_new_bool(true));
  fl_value_set_string_take(map, "networkInfo", fl_value_new_bool(true));
  fl_value_set_string_take(map, "sensorInfo", fl_value_new_bool(false));
  return map;
}

static void device_inspector_plugin_handle_method_call(
    DeviceInspectorPlugin* self,
    FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response = nullptr;
  const gchar* method = fl_method_call_get_name(method_call);

  if (strcmp(method, "getSystemInfo") == 0) {
    g_autoptr(FlValue) map = fl_value_new_map();
    fl_value_set_string_take(map, "cpu", BuildCpuInfoMap());
    fl_value_set_string_take(map, "memory", BuildMemoryInfoMap());
    fl_value_set_string_take(map, "gpu", BuildGpuInfoMap());
    fl_value_set_string_take(map, "storage", BuildStorageInfoList());
    fl_value_set_string_take(map, "battery", BuildBatteryInfoMap());
    fl_value_set_string_take(map, "device", BuildDeviceInfoMap());
    fl_value_set_string_take(map, "os", BuildOsInfoMap());
    fl_value_set_string_take(map, "network", BuildNetworkInfoList());
    fl_value_set_string_take(map, "sensors", fl_value_new_list());
    fl_value_set_string_take(map, "capabilities", BuildCapabilitiesMap());
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(map));
  } else if (strcmp(method, "getCpuInfo") == 0) {
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(BuildCpuInfoMap()));
  } else if (strcmp(method, "getMemoryInfo") == 0) {
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(BuildMemoryInfoMap()));
  } else if (strcmp(method, "getGpuInfo") == 0) {
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(BuildGpuInfoMap()));
  } else if (strcmp(method, "getStorageInfo") == 0) {
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(BuildStorageInfoList()));
  } else if (strcmp(method, "getBatteryInfo") == 0) {
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(BuildBatteryInfoMap()));
  } else if (strcmp(method, "getDeviceInfo") == 0) {
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(BuildDeviceInfoMap()));
  } else if (strcmp(method, "getOsInfo") == 0) {
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(BuildOsInfoMap()));
  } else if (strcmp(method, "getNetworkInfo") == 0) {
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(BuildNetworkInfoList()));
  } else if (strcmp(method, "getSensors") == 0) {
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_list()));
  } else if (strcmp(method, "getCapabilities") == 0) {
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(BuildCapabilitiesMap()));
  } else if (strcmp(method, "getSystemMetrics") == 0) {
    g_autoptr(FlValue) map = fl_value_new_map();
    g_autoptr(FlValue) cpu = BuildCpuInfoMap();
    g_autoptr(FlValue) mem = BuildMemoryInfoMap();

    fl_value_set_string_take(map, "timestamp", fl_value_new_int(time(NULL) * 1000));
    FlValue* cpuUsage = fl_value_lookup_string(cpu, "usagePercent");
    if (cpuUsage) fl_value_set_string_take(map, "cpuUsagePercent", fl_value_ref(cpuUsage));

    FlValue* memUsage = fl_value_lookup_string(mem, "usagePercent");
    if (memUsage) fl_value_set_string_take(map, "memoryUsagePercent", fl_value_ref(memUsage));

    response = FL_METHOD_RESPONSE(fl_method_success_response_new(map));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}

FlMethodResponse* get_platform_version() {
  struct utsname uname_data = {};
  uname(&uname_data);
  g_autofree gchar *version = g_strdup_printf("Linux %s", uname_data.version);
  g_autoptr(FlValue) result = fl_value_new_string(version);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

static void device_inspector_plugin_dispose(GObject* object) {
  G_OBJECT_CLASS(device_inspector_plugin_parent_class)->dispose(object);
}

static void device_inspector_plugin_class_init(DeviceInspectorPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = device_inspector_plugin_dispose;
}

static void device_inspector_plugin_init(DeviceInspectorPlugin* self) {}

static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                           gpointer user_data) {
  DeviceInspectorPlugin* plugin = DEVICE_INSPECTOR_PLUGIN(user_data);
  device_inspector_plugin_handle_method_call(plugin, method_call);
}

void device_inspector_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  DeviceInspectorPlugin* plugin = DEVICE_INSPECTOR_PLUGIN(
      g_object_new(device_inspector_plugin_get_type(), nullptr));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                            "device_inspector",
                            FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, method_call_cb,
                                            g_object_ref(plugin),
                                            g_object_unref);

  g_object_unref(plugin);
}
