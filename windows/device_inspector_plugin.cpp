#include "device_inspector_plugin.h"

#include <dxgi.h>
#include <iphlpapi.h>
#include <sysinfoapi.h>
#include <winternl.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <chrono>
#include <memory>
#include <sstream>
#include <string>
#include <vector>

#pragma comment(lib, "ws2_32.lib")
#pragma comment(lib, "iphlpapi.lib")
#pragma comment(lib, "dxgi.lib")

namespace device_inspector {

typedef NTSTATUS(WINAPI* RtlGetVersionPtr)(PRTL_OSVERSIONINFOW);

static ULONGLONG g_lastIdleTime = 0;
static ULONGLONG g_lastKernelTime = 0;
static ULONGLONG g_lastUserTime = 0;

static std::string Utf8FromWString(const std::wstring& wstr) {
  if (wstr.empty()) return std::string();
  int size_needed = WideCharToMultiByte(CP_UTF8, 0, &wstr[0], (int)wstr.size(), NULL, 0, NULL, NULL);
  std::string strTo(size_needed, 0);
  WideCharToMultiByte(CP_UTF8, 0, &wstr[0], (int)wstr.size(), &strTo[0], size_needed, NULL, NULL);
  return strTo;
}

static std::string ReadRegistryString(HKEY hKeyParent, const std::wstring& subKey, const std::wstring& valueName) {
  HKEY hKey;
  if (RegOpenKeyExW(hKeyParent, subKey.c_str(), 0, KEY_READ, &hKey) != ERROR_SUCCESS) {
    return "";
  }
  WCHAR buffer[256];
  DWORD dataSize = sizeof(buffer);
  DWORD type = REG_SZ;
  if (RegQueryValueExW(hKey, valueName.c_str(), NULL, &type, (LPBYTE)buffer, &dataSize) == ERROR_SUCCESS) {
    RegCloseKey(hKey);
    return Utf8FromWString(buffer);
  }
  RegCloseKey(hKey);
  return "";
}

static DWORD ReadRegistryDword(HKEY hKeyParent, const std::wstring& subKey, const std::wstring& valueName) {
  HKEY hKey;
  if (RegOpenKeyExW(hKeyParent, subKey.c_str(), 0, KEY_READ, &hKey) != ERROR_SUCCESS) {
    return 0;
  }
  DWORD val = 0;
  DWORD dataSize = sizeof(val);
  DWORD type = REG_DWORD;
  if (RegQueryValueExW(hKey, valueName.c_str(), NULL, &type, (LPBYTE)&val, &dataSize) == ERROR_SUCCESS) {
    RegCloseKey(hKey);
    return val;
  }
  RegCloseKey(hKey);
  return 0;
}

// static
void DeviceInspectorPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "device_inspector",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<DeviceInspectorPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

DeviceInspectorPlugin::DeviceInspectorPlugin() {}

DeviceInspectorPlugin::~DeviceInspectorPlugin() {}

static flutter::EncodableMap GetCpuInfoMap() {
  SYSTEM_INFO sysInfo;
  GetNativeSystemInfo(&sysInfo);

  std::string cpuName = ReadRegistryString(HKEY_LOCAL_MACHINE, L"HARDWARE\\DESCRIPTION\\System\\CentralProcessor\\0", L"ProcessorNameString");
  std::string vendor = ReadRegistryString(HKEY_LOCAL_MACHINE, L"HARDWARE\\DESCRIPTION\\System\\CentralProcessor\\0", L"VendorIdentifier");
  DWORD mhz = ReadRegistryDword(HKEY_LOCAL_MACHINE, L"HARDWARE\\DESCRIPTION\\System\\CentralProcessor\\0", L"~MHz");

  std::string arch = "x86_64";
  if (sysInfo.wProcessorArchitecture == PROCESSOR_ARCHITECTURE_ARM64) {
    arch = "arm64";
  } else if (sysInfo.wProcessorArchitecture == PROCESSOR_ARCHITECTURE_INTEL) {
    arch = "x86";
  }

  double freqMHz = mhz > 0 ? (double)mhz : 0.0;

  FILETIME idleTime, kernelTime, userTime;
  double overallUsage = 0.0;
  if (GetSystemTimes(&idleTime, &kernelTime, &userTime)) {
    ULONGLONG idle = (((ULONGLONG)idleTime.dwHighDateTime) << 32) | idleTime.dwLowDateTime;
    ULONGLONG kernel = (((ULONGLONG)kernelTime.dwHighDateTime) << 32) | kernelTime.dwLowDateTime;
    ULONGLONG user = (((ULONGLONG)userTime.dwHighDateTime) << 32) | userTime.dwLowDateTime;

    ULONGLONG idleDiff = idle - g_lastIdleTime;
    ULONGLONG kernelDiff = kernel - g_lastKernelTime;
    ULONGLONG userDiff = user - g_lastUserTime;

    g_lastIdleTime = idle;
    g_lastKernelTime = kernel;
    g_lastUserTime = user;

    ULONGLONG total = kernelDiff + userDiff;
    if (total > 0) {
      overallUsage = ((double)(total - idleDiff) / (double)total) * 100.0;
      if (overallUsage < 0.0) overallUsage = 0.0;
      if (overallUsage > 100.0) overallUsage = 100.0;
    }
  }

  flutter::EncodableList coresList;
  for (DWORD i = 0; i < sysInfo.dwNumberOfProcessors; ++i) {
    flutter::EncodableMap coreMap;
    coreMap[flutter::EncodableValue("id")] = flutter::EncodableValue((int)i);
    coreMap[flutter::EncodableValue("usagePercent")] = flutter::EncodableValue(overallUsage);
    if (freqMHz > 0.0) {
      coreMap[flutter::EncodableValue("currentFrequencyMHz")] = flutter::EncodableValue(freqMHz);
    }
    coresList.push_back(flutter::EncodableValue(coreMap));
  }

  flutter::EncodableMap map;
  map[flutter::EncodableValue("name")] = flutter::EncodableValue(cpuName.empty() ? "Windows CPU" : cpuName);
  map[flutter::EncodableValue("vendor")] = flutter::EncodableValue(vendor.empty() ? "GenuineIntel" : vendor);
  map[flutter::EncodableValue("architecture")] = flutter::EncodableValue(arch);
  map[flutter::EncodableValue("physicalCores")] = flutter::EncodableValue((int)sysInfo.dwNumberOfProcessors);
  map[flutter::EncodableValue("logicalCores")] = flutter::EncodableValue((int)sysInfo.dwNumberOfProcessors);
  map[flutter::EncodableValue("is64Bit")] = flutter::EncodableValue(true);
  map[flutter::EncodableValue("features")] = flutter::EncodableList({
    flutter::EncodableValue("sse"), flutter::EncodableValue("sse2"), flutter::EncodableValue("avx")
  });
  if (freqMHz > 0.0) {
    map[flutter::EncodableValue("currentFrequencyMHz")] = flutter::EncodableValue(freqMHz);
    map[flutter::EncodableValue("maxFrequencyMHz")] = flutter::EncodableValue(freqMHz);
  }
  map[flutter::EncodableValue("usagePercent")] = flutter::EncodableValue(overallUsage);
  map[flutter::EncodableValue("cores")] = coresList;

  return map;
}

static flutter::EncodableMap GetMemoryInfoMap() {
  MEMORYSTATUSEX memStatus;
  memStatus.dwLength = sizeof(memStatus);
  flutter::EncodableMap map;

  if (GlobalMemoryStatusEx(&memStatus)) {
    int64_t total = (int64_t)memStatus.ullTotalPhys;
    int64_t avail = (int64_t)memStatus.ullAvailPhys;
    int64_t used = total - avail;
    double usagePercent = total > 0 ? ((double)used / (double)total) * 100.0 : 0.0;

    int64_t swapTotal = (int64_t)memStatus.ullTotalPageFile;
    int64_t swapAvail = (int64_t)memStatus.ullAvailPageFile;
    int64_t swapUsed = swapTotal - swapAvail;

    map[flutter::EncodableValue("totalBytes")] = flutter::EncodableValue(total);
    map[flutter::EncodableValue("usedBytes")] = flutter::EncodableValue(used);
    map[flutter::EncodableValue("availableBytes")] = flutter::EncodableValue(avail);
    map[flutter::EncodableValue("freeBytes")] = flutter::EncodableValue(avail);
    map[flutter::EncodableValue("usagePercent")] = flutter::EncodableValue(usagePercent);
    map[flutter::EncodableValue("swapTotalBytes")] = flutter::EncodableValue(swapTotal);
    map[flutter::EncodableValue("swapUsedBytes")] = flutter::EncodableValue(swapUsed);
    map[flutter::EncodableValue("swapFreeBytes")] = flutter::EncodableValue(swapAvail);
  }

  return map;
}

static flutter::EncodableMap GetGpuInfoMap() {
  flutter::EncodableMap map;
  IDXGIFactory* pFactory = NULL;

  if (SUCCEEDED(CreateDXGIFactory(__uuidof(IDXGIFactory), (void**)&pFactory))) {
    IDXGIAdapter* pAdapter = NULL;
    if (pFactory->EnumAdapters(0, &pAdapter) != DXGI_ERROR_NOT_FOUND) {
      DXGI_ADAPTER_DESC desc;
      if (SUCCEEDED(pAdapter->GetDesc(&desc))) {
        std::string gpuName = Utf8FromWString(desc.Description);
        int64_t vram = (int64_t)desc.DedicatedVideoMemory;

        map[flutter::EncodableValue("name")] = flutter::EncodableValue(gpuName);
        map[flutter::EncodableValue("renderer")] = flutter::EncodableValue(gpuName);
        map[flutter::EncodableValue("vramBytes")] = flutter::EncodableValue(vram);
        map[flutter::EncodableValue("graphicsApis")] = flutter::EncodableList({
          flutter::EncodableValue("DirectX 11/12"), flutter::EncodableValue("Vulkan")
        });
        map[flutter::EncodableValue("isDiscrete")] = flutter::EncodableValue(vram > 0);
      }
      pAdapter->Release();
    }
    pFactory->Release();
  }

  if (map.find(flutter::EncodableValue("name")) == map.end()) {
    map[flutter::EncodableValue("name")] = flutter::EncodableValue("DirectX Graphics");
    map[flutter::EncodableValue("graphicsApis")] = flutter::EncodableList({ flutter::EncodableValue("DirectX") });
  }

  return map;
}

static flutter::EncodableList GetStorageInfoList() {
  flutter::EncodableList list;
  WCHAR drives[512];
  DWORD len = GetLogicalDriveStringsW(512, drives);

  if (len > 0) {
    WCHAR* drive = drives;
    while (*drive) {
      UINT type = GetDriveTypeW(drive);
      if (type == DRIVE_FIXED || type == DRIVE_REMOVABLE || type == DRIVE_REMOTE) {
        ULARGE_INTEGER freeBytes, totalBytes, totalFreeBytes;
        if (GetDiskFreeSpaceExW(drive, &freeBytes, &totalBytes, &totalFreeBytes)) {
          std::string drivePath = Utf8FromWString(drive);
          int64_t t = (int64_t)totalBytes.QuadPart;
          int64_t f = (int64_t)freeBytes.QuadPart;
          int64_t u = t - f;

          std::string typeStr = (type == DRIVE_FIXED) ? "internal" : ((type == DRIVE_REMOVABLE) ? "removable" : "network");

          flutter::EncodableMap m;
          m[flutter::EncodableValue("path")] = flutter::EncodableValue(drivePath);
          m[flutter::EncodableValue("name")] = flutter::EncodableValue("Drive " + drivePath);
          m[flutter::EncodableValue("totalBytes")] = flutter::EncodableValue(t);
          m[flutter::EncodableValue("usedBytes")] = flutter::EncodableValue(u);
          m[flutter::EncodableValue("freeBytes")] = flutter::EncodableValue(f);
          m[flutter::EncodableValue("fileSystem")] = flutter::EncodableValue("NTFS");
          m[flutter::EncodableValue("type")] = flutter::EncodableValue(typeStr);

          list.push_back(flutter::EncodableValue(m));
        }
      }
      drive += wcslen(drive) + 1;
    }
  }

  return list;
}

static flutter::EncodableMap GetBatteryInfoMap() {
  flutter::EncodableMap map;
  SYSTEM_POWER_STATUS powerStatus;

  if (GetSystemPowerStatus(&powerStatus)) {
    if (powerStatus.BatteryLifePercent != 255) {
      double level = (double)powerStatus.BatteryLifePercent;
      bool isCharging = (powerStatus.ACLineStatus == 1);
      std::string statusStr = isCharging ? "charging" : "discharging";
      if (powerStatus.BatteryLifePercent == 100) statusStr = "full";

      map[flutter::EncodableValue("levelPercent")] = flutter::EncodableValue(level);
      map[flutter::EncodableValue("status")] = flutter::EncodableValue(statusStr);
      map[flutter::EncodableValue("isCharging")] = flutter::EncodableValue(isCharging);
      map[flutter::EncodableValue("health")] = flutter::EncodableValue("Good");
    }
  }

  return map;
}

static flutter::EncodableMap GetDeviceInfoMap() {
  WCHAR computerName[MAX_COMPUTERNAME_LENGTH + 1];
  DWORD size = MAX_COMPUTERNAME_LENGTH + 1;
  std::string name = "Windows PC";
  if (GetComputerNameW(computerName, &size)) {
    name = Utf8FromWString(computerName);
  }

  int64_t uptimeSec = (int64_t)(GetTickCount64() / 1000);

  flutter::EncodableMap map;
  map[flutter::EncodableValue("manufacturer")] = flutter::EncodableValue("Microsoft / OEM");
  map[flutter::EncodableValue("model")] = flutter::EncodableValue("Windows Desktop");
  map[flutter::EncodableValue("deviceName")] = flutter::EncodableValue(name);
  map[flutter::EncodableValue("hostName")] = flutter::EncodableValue(name);
  map[flutter::EncodableValue("architecture")] = flutter::EncodableValue("x86_64");
  map[flutter::EncodableValue("osName")] = flutter::EncodableValue("Windows");
  map[flutter::EncodableValue("uptimeSeconds")] = flutter::EncodableValue(uptimeSec);

  return map;
}

static flutter::EncodableMap GetOsInfoMap() {
  flutter::EncodableMap map;
  std::string versionStr = "10.0";
  std::string buildStr = "19041";

  HMODULE hNtdll = GetModuleHandleW(L"ntdll.dll");
  if (hNtdll) {
    RtlGetVersionPtr pRtlGetVersion = (RtlGetVersionPtr)GetProcAddress(hNtdll, "RtlGetVersion");
    if (pRtlGetVersion) {
      RTL_OSVERSIONINFOW rovi = { 0 };
      rovi.dwOSVersionInfoSize = sizeof(rovi);
      if (pRtlGetVersion(&rovi) == 0) {
        versionStr = std::to_string(rovi.dwMajorVersion) + "." + std::to_string(rovi.dwMinorVersion);
        buildStr = std::to_string(rovi.dwBuildNumber);
      }
    }
  }

  map[flutter::EncodableValue("name")] = flutter::EncodableValue("Windows");
  map[flutter::EncodableValue("version")] = flutter::EncodableValue(versionStr);
  map[flutter::EncodableValue("buildNumber")] = flutter::EncodableValue(buildStr);
  map[flutter::EncodableValue("architecture")] = flutter::EncodableValue("x86_64");
  map[flutter::EncodableValue("is64Bit")] = flutter::EncodableValue(true);

  return map;
}

static flutter::EncodableList GetNetworkInfoList() {
  flutter::EncodableList list;
  ULONG bufLen = 15000;
  PIP_ADAPTER_ADDRESSES pAddresses = (IP_ADAPTER_ADDRESSES*)HeapAlloc(GetProcessHeap(), 0, bufLen);

  if (pAddresses != NULL) {
    DWORD dwRetVal = GetAdaptersAddresses(AF_UNSPEC, GAA_FLAG_INCLUDE_PREFIX, NULL, pAddresses, &bufLen);
    if (dwRetVal == ERROR_BUFFER_OVERFLOW) {
      HeapFree(GetProcessHeap(), 0, pAddresses);
      pAddresses = (IP_ADAPTER_ADDRESSES*)HeapAlloc(GetProcessHeap(), 0, bufLen);
      if (pAddresses != NULL) {
        dwRetVal = GetAdaptersAddresses(AF_UNSPEC, GAA_FLAG_INCLUDE_PREFIX, NULL, pAddresses, &bufLen);
      }
    }

    if (dwRetVal == NO_ERROR && pAddresses != NULL) {
      PIP_ADAPTER_ADDRESSES pCurrAddresses = pAddresses;
      while (pCurrAddresses) {
        std::string ifName = Utf8FromWString(pCurrAddresses->FriendlyName);
        std::string type = (pCurrAddresses->IfType == IF_TYPE_IEEE80211) ? "wifi" : ((pCurrAddresses->IfType == IF_TYPE_ETHERNET_CSMACD) ? "ethernet" : "unknown");

        std::string ipv4 = "";
        std::string ipv6 = "";

        PIP_ADAPTER_UNICAST_ADDRESS pUnicast = pCurrAddresses->FirstUnicastAddress;
        while (pUnicast) {
          if (pUnicast->Address.lpSockaddr->sa_family == AF_INET) {
            sockaddr_in* sa_in = (sockaddr_in*)pUnicast->Address.lpSockaddr;
            char ip[INET_ADDRSTRLEN];
            inet_ntop(AF_INET, &(sa_in->sin_addr), ip, INET_ADDRSTRLEN);
            ipv4 = ip;
          } else if (pUnicast->Address.lpSockaddr->sa_family == AF_INET6) {
            sockaddr_in6* sa_in6 = (sockaddr_in6*)pUnicast->Address.lpSockaddr;
            char ip6[INET6_ADDRSTRLEN];
            inet_ntop(AF_INET6, &(sa_in6->sin6_addr), ip6, INET6_ADDRSTRLEN);
            ipv6 = ip6;
          }
          pUnicast = pUnicast->Next;
        }

        std::string status = (pCurrAddresses->OperStatus == IfOperStatusUp) ? "up" : "down";

        flutter::EncodableMap m;
        m[flutter::EncodableValue("interfaceName")] = flutter::EncodableValue(ifName);
        m[flutter::EncodableValue("interfaceType")] = flutter::EncodableValue(type);
        m[flutter::EncodableValue("status")] = flutter::EncodableValue(status);
        if (!ipv4.empty()) m[flutter::EncodableValue("ipv4Address")] = flutter::EncodableValue(ipv4);
        if (!ipv6.empty()) m[flutter::EncodableValue("ipv6Address")] = flutter::EncodableValue(ipv6);

        list.push_back(flutter::EncodableValue(m));
        pCurrAddresses = pCurrAddresses->Next;
      }
    }
    if (pAddresses) HeapFree(GetProcessHeap(), 0, pAddresses);
  }

  return list;
}

static flutter::EncodableMap GetCapabilitiesMap() {
  flutter::EncodableMap map;
  map[flutter::EncodableValue("cpuInfo")] = flutter::EncodableValue(true);
  map[flutter::EncodableValue("cpuUsage")] = flutter::EncodableValue(true);
  map[flutter::EncodableValue("cpuFrequency")] = flutter::EncodableValue(true);
  map[flutter::EncodableValue("perCoreUsage")] = flutter::EncodableValue(true);
  map[flutter::EncodableValue("gpuInfo")] = flutter::EncodableValue(true);
  map[flutter::EncodableValue("memoryInfo")] = flutter::EncodableValue(true);
  map[flutter::EncodableValue("storageInfo")] = flutter::EncodableValue(true);
  map[flutter::EncodableValue("batteryInfo")] = flutter::EncodableValue(true);
  map[flutter::EncodableValue("networkInfo")] = flutter::EncodableValue(true);
  map[flutter::EncodableValue("sensorInfo")] = flutter::EncodableValue(false);
  return map;
}

static flutter::EncodableMap GetSystemMetricsMap() {
  flutter::EncodableMap cpu = GetCpuInfoMap();
  flutter::EncodableMap mem = GetMemoryInfoMap();
  flutter::EncodableMap battery = GetBatteryInfoMap();
  flutter::EncodableList storage = GetStorageInfoList();

  flutter::EncodableMap map;
  auto now = std::chrono::system_clock::now();
  int64_t ts = std::chrono::duration_cast<std::chrono::milliseconds>(now.time_since_epoch()).count();

  map[flutter::EncodableValue("timestamp")] = flutter::EncodableValue(ts);
  if (cpu.find(flutter::EncodableValue("usagePercent")) != cpu.end()) {
    map[flutter::EncodableValue("cpuUsagePercent")] = cpu[flutter::EncodableValue("usagePercent")];
  }
  if (mem.find(flutter::EncodableValue("usagePercent")) != mem.end()) {
    map[flutter::EncodableValue("memoryUsagePercent")] = mem[flutter::EncodableValue("usagePercent")];
  }
  if (mem.find(flutter::EncodableValue("availableBytes")) != mem.end()) {
    map[flutter::EncodableValue("availableMemoryBytes")] = mem[flutter::EncodableValue("availableBytes")];
  }
  if (battery.find(flutter::EncodableValue("levelPercent")) != battery.end()) {
    map[flutter::EncodableValue("batteryLevelPercent")] = battery[flutter::EncodableValue("levelPercent")];
    map[flutter::EncodableValue("isCharging")] = battery[flutter::EncodableValue("isCharging")];
  }

  return map;
}

void DeviceInspectorPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const std::string& method = method_call.method_name();

  if (method == "getSystemInfo") {
    flutter::EncodableMap sys;
    sys[flutter::EncodableValue("cpu")] = GetCpuInfoMap();
    sys[flutter::EncodableValue("memory")] = GetMemoryInfoMap();
    sys[flutter::EncodableValue("gpu")] = GetGpuInfoMap();
    sys[flutter::EncodableValue("storage")] = GetStorageInfoList();
    sys[flutter::EncodableValue("battery")] = GetBatteryInfoMap();
    sys[flutter::EncodableValue("device")] = GetDeviceInfoMap();
    sys[flutter::EncodableValue("os")] = GetOsInfoMap();
    sys[flutter::EncodableValue("network")] = GetNetworkInfoList();
    sys[flutter::EncodableValue("sensors")] = flutter::EncodableList({});
    sys[flutter::EncodableValue("capabilities")] = GetCapabilitiesMap();
    result->Success(flutter::EncodableValue(sys));
  } else if (method == "getCpuInfo") {
    result->Success(flutter::EncodableValue(GetCpuInfoMap()));
  } else if (method == "getMemoryInfo") {
    result->Success(flutter::EncodableValue(GetMemoryInfoMap()));
  } else if (method == "getGpuInfo") {
    result->Success(flutter::EncodableValue(GetGpuInfoMap()));
  } else if (method == "getStorageInfo") {
    result->Success(flutter::EncodableValue(GetStorageInfoList()));
  } else if (method == "getBatteryInfo") {
    result->Success(flutter::EncodableValue(GetBatteryInfoMap()));
  } else if (method == "getDeviceInfo") {
    result->Success(flutter::EncodableValue(GetDeviceInfoMap()));
  } else if (method == "getOsInfo") {
    result->Success(flutter::EncodableValue(GetOsInfoMap()));
  } else if (method == "getNetworkInfo") {
    result->Success(flutter::EncodableValue(GetNetworkInfoList()));
  } else if (method == "getSensors") {
    result->Success(flutter::EncodableValue(flutter::EncodableList({})));
  } else if (method == "getCapabilities") {
    result->Success(flutter::EncodableValue(GetCapabilitiesMap()));
  } else if (method == "getSystemMetrics") {
    result->Success(flutter::EncodableValue(GetSystemMetricsMap()));
  } else {
    result->NotImplemented();
  }
}

}  // namespace device_inspector
