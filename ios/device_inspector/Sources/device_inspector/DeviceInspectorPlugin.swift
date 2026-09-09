import Flutter
import UIKit
import CoreMotion
import Metal
import SystemConfiguration
import mach

public class DeviceInspectorPlugin: NSObject, FlutterPlugin {
  private static var lastTotalCpuTicks: (user: UInt64, system: UInt64, idle: UInt64, nice: UInt64)?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "device_inspector", binaryMessenger: registrar.messenger())
    let instance = DeviceInspectorPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getSystemInfo":
      result(getSystemInfoMap())
    case "getCpuInfo":
      result(getCpuInfoMap())
    case "getMemoryInfo":
      result(getMemoryInfoMap())
    case "getGpuInfo":
      result(getGpuInfoMap())
    case "getStorageInfo":
      result(getStorageInfoList())
    case "getBatteryInfo":
      result(getBatteryInfoMap())
    case "getDeviceInfo":
      result(getDeviceInfoMap())
    case "getOsInfo":
      result(getOsInfoMap())
    case "getNetworkInfo":
      result(getNetworkInfoList())
    case "getSensors":
      result(getSensorsList())
    case "getCapabilities":
      result(getCapabilitiesMap())
    case "getSystemMetrics":
      result(getSystemMetricsMap())
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func getSystemInfoMap() -> [String: Any?] {
    return [
      "cpu": getCpuInfoMap(),
      "memory": getMemoryInfoMap(),
      "gpu": getGpuInfoMap(),
      "storage": getStorageInfoList(),
      "battery": getBatteryInfoMap(),
      "device": getDeviceInfoMap(),
      "os": getOsInfoMap(),
      "network": getNetworkInfoList(),
      "sensors": getSensorsList(),
      "capabilities": getCapabilitiesMap()
    ]
  }

  private func getCpuInfoMap() -> [String: Any?] {
    let name = getSysctlString(name: "machdep.cpu.brand_string") ?? getDeviceModelName()
    let physicalCores = getSysctlInt(name: "hw.physicalcpu") ?? ProcessInfo.processInfo.processorCount
    let logicalCores = getSysctlInt(name: "hw.logicalcpu") ?? ProcessInfo.processInfo.activeProcessorCount

    var freqMHz: Double? = nil
    if let freqHz = getSysctlInt64(name: "hw.cpufrequency") {
      freqMHz = Double(freqHz) / 1_000_000.0
    }

    let l1Cache = getSysctlInt64(name: "hw.l1icachesize")
    let l2Cache = getSysctlInt64(name: "hw.l2cachesize")
    let l3Cache = getSysctlInt64(name: "hw.l3cachesize")

    let overallUsage = calculateCpuUsagePercent()
    let perCoreUsage = calculatePerCoreCpuUsage()

    var coresList = [[String: Any?]]()
    for i in 0..<logicalCores {
      let coreUsage = i < perCoreUsage.count ? perCoreUsage[i] : nil
      coresList.append([
        "id": i,
        "usagePercent": coreUsage,
        "currentFrequencyMHz": freqMHz,
        "minFrequencyMHz": nil,
        "maxFrequencyMHz": freqMHz
      ])
    }

    return [
      "name": name,
      "vendor": "Apple Inc.",
      "architecture": "arm64",
      "physicalCores": physicalCores,
      "logicalCores": logicalCores,
      "is64Bit": true,
      "features": ["neon", "fp16", "crc32", "aes"],
      "l1CacheBytes": l1Cache,
      "l2CacheBytes": l2Cache,
      "l3CacheBytes": l3Cache,
      "currentFrequencyMHz": freqMHz,
      "minFrequencyMHz": nil,
      "maxFrequencyMHz": freqMHz,
      "usagePercent": overallUsage,
      "cores": coresList
    ]
  }

  private func getMemoryInfoMap() -> [String: Any?] {
    let total = Int64(ProcessInfo.processInfo.physicalMemory)
    var available: Int64? = nil
    var free: Int64? = nil

    var pageSizeBytes: vm_size_t = 0
    host_page_size(mach_host_self(), &pageSizeBytes)

    var vmStat = vm_statistics64()
    var count = mach_msg_type_number_t(HOST_VM_INFO64_COUNT)
    let kerr = withUnsafeMutablePointer(to: &vmStat) {
      $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
        host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
      }
    }

    if kerr == KERN_SUCCESS {
      let pageSize = Int64(pageSizeBytes)
      free = Int64(vmStat.free_count) * pageSize
      available = Int64(vmStat.free_count + vmStat.inactive_count) * pageSize
    }

    let used = total - (available ?? (free ?? 0))
    let usagePercent = total > 0 ? (Double(used) / Double(total)) * 100.0 : nil

    return [
      "totalBytes": total,
      "usedBytes": used,
      "availableBytes": available,
      "freeBytes": free,
      "usagePercent": usagePercent,
      "swapTotalBytes": nil,
      "swapUsedBytes": nil,
      "swapFreeBytes": nil
    ]
  }

  private func getGpuInfoMap() -> [String: Any?] {
    var gpuName = "Apple GPU"
    if let device = MTLCreateSystemDefaultDevice() {
      gpuName = device.name
    }
    return [
      "name": gpuName,
      "vendor": "Apple Inc.",
      "renderer": gpuName,
      "driverVersion": nil,
      "vramBytes": nil,
      "graphicsApis": ["Metal 3"],
      "isDiscrete": false
    ]
  }

  private func getStorageInfoList() -> [[String: Any?]] {
    let homeDir = NSHomeDirectory()
    var total: Int64? = nil
    var free: Int64? = nil

    if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: homeDir) {
      if let t = attrs[.systemSize] as? NSNumber { total = t.int64Value }
      if let f = attrs[.systemFreeSize] as? NSNumber { free = f.int64Value }
    }

    let used = (total != nil && free != nil) ? total! - free! : nil

    return [[
      "path": homeDir,
      "name": "Primary Storage",
      "totalBytes": total,
      "usedBytes": used,
      "freeBytes": free,
      "fileSystem": "APFS",
      "type": "internal"
    ]]
  }

  private func getBatteryInfoMap() -> [String: Any?] {
    UIDevice.current.isBatteryMonitoringEnabled = true
    let level = UIDevice.current.batteryLevel
    let levelPercent = level >= 0 ? Double(level) * 100.0 : nil

    let state = UIDevice.current.batteryState
    let isCharging = state == .charging || state == .full
    let statusStr: String = {
      switch state {
      case .charging: return "charging"
      case .full: return "full"
      case .unplugged: return "discharging"
      default: return "unknown"
      }
    }()

    return [
      "levelPercent": levelPercent,
      "status": statusStr,
      "isCharging": isCharging,
      "health": "Good",
      "temperatureCelsius": nil,
      "voltageVolts": nil,
      "currentMilliAmperes": nil,
      "capacityMilliAmpereHours": nil
    ]
  }

  private func getDeviceInfoMap() -> [String: Any?] {
    let device = UIDevice.current
    let uptimeSec = Int64(ProcessInfo.processInfo.systemUptime)
    return [
      "manufacturer": "Apple Inc.",
      "model": getDeviceModelName(),
      "deviceName": device.name,
      "hostName": ProcessInfo.processInfo.hostName,
      "architecture": "arm64",
      "osName": "iOS",
      "osVersion": device.systemVersion,
      "kernelVersion": getSysctlString(name: "kern.osrelease"),
      "buildNumber": getSysctlString(name: "kern.osversion"),
      "uptimeSeconds": uptimeSec
    ]
  }

  private func getOsInfoMap() -> [String: Any?] {
    return [
      "name": "iOS",
      "version": UIDevice.current.systemVersion,
      "buildNumber": getSysctlString(name: "kern.osversion"),
      "kernelVersion": getSysctlString(name: "kern.osrelease"),
      "architecture": "arm64",
      "hostName": ProcessInfo.processInfo.hostName,
      "is64Bit": true
    ]
  }

  private func getNetworkInfoList() -> [[String: Any?]] {
    var result = [[String: Any?]]()
    var ifaddr: UnsafeMutablePointer<ifaddrs>?
    guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return result }

    for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
      let flags = Int32(ptr.pointee.ifa_flags)
      let name = String(cString: ptr.pointee.ifa_name)

      if (flags & IFF_LOOPBACK) != 0 { continue }
      guard let addr = ptr.pointee.ifa_addr else { continue }

      let saFamily = Int32(addr.pointee.sa_family)
      var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))

      if saFamily == AF_INET || saFamily == AF_INET6 {
        if getnameinfo(addr, socklen_t(addr.pointee.sa_len),
                       &hostname, socklen_t(hostname.count),
                       nil, 0, NI_NUMERICHOST) == 0 {
          let address = String(cString: hostname)
          let type = name.contains("en") ? "wifi" : (name.contains("pdp_ip") ? "cellular" : "unknown")

          result.append([
            "interfaceName": name,
            "interfaceType": type,
            "status": (flags & IFF_UP) != 0 ? "up" : "down",
            "ipv4Address": saFamily == AF_INET ? address : nil,
            "ipv6Address": saFamily == AF_INET6 ? address : nil,
            "linkSpeedMbps": nil,
            "macAddress": nil
          ])
        }
      }
    }
    freeifaddrs(ifaddr)
    return result
  }

  private func getSensorsList() -> [[String: Any?]] {
    let motionManager = CMMotionManager()
    let sensors: [(type: String, available: Bool)] = [
      ("accelerometer", motionManager.isAccelerometerAvailable),
      ("gyroscope", motionManager.isGyroAvailable),
      ("magnetometer", motionManager.isMagnetometerAvailable),
      ("gravity", motionManager.isDeviceMotionAvailable),
      ("linearAcceleration", motionManager.isDeviceMotionAvailable),
      ("rotationVector", motionManager.isDeviceMotionAvailable)
    ]

    return sensors.map {
      [
        "type": $0.type,
        "name": "iOS Motion Hardware",
        "vendor": "Apple Inc.",
        "isAvailable": $0.available,
        "powerMilliAmperes": nil,
        "resolution": nil
      ]
    }
  }

  private func getCapabilitiesMap() -> [String: Bool] {
    return [
      "cpuInfo": true,
      "cpuUsage": true,
      "cpuFrequency": true,
      "perCoreUsage": true,
      "gpuInfo": true,
      "memoryInfo": true,
      "storageInfo": true,
      "batteryInfo": true,
      "networkInfo": true,
      "sensorInfo": true
    ]
  }

  private func getSystemMetricsMap() -> [String: Any?] {
    let cpuUsage = calculateCpuUsagePercent()
    let perCore = calculatePerCoreCpuUsage()
    let mem = getMemoryInfoMap()
    let battery = getBatteryInfoMap()
    let storage = getStorageInfoList().first

    return [
      "timestamp": Int64(Date().timeIntervalSince1970 * 1000),
      "cpuUsagePercent": cpuUsage,
      "perCoreCpuUsagePercent": perCore,
      "memoryUsagePercent": mem["usagePercent"] as? Double,
      "availableMemoryBytes": mem["availableBytes"] as? Int64,
      "batteryLevelPercent": battery["levelPercent"] as? Double,
      "isCharging": battery["isCharging"] as? Bool,
      "storageFreeBytes": storage?["freeBytes"] as? Int64,
      "networkRxBytesPerSecond": nil,
      "networkTxBytesPerSecond": nil
    ]
  }

  private func calculateCpuUsagePercent() -> Double? {
    var cpuInfo: host_cpu_load_info = host_cpu_load_info()
    var count = mach_msg_type_number_t(HOST_CPU_LOAD_INFO_COUNT)

    let kerr = withUnsafeMutablePointer(to: &cpuInfo) {
      $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
        host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
      }
    }

    guard kerr == KERN_SUCCESS else { return nil }

    let user = UInt64(cpuInfo.cpu_ticks.0)
    let system = UInt64(cpuInfo.cpu_ticks.1)
    let idle = UInt64(cpuInfo.cpu_ticks.2)
    let nice = UInt64(cpuInfo.cpu_ticks.3)

    guard let last = DeviceInspectorPlugin.lastTotalCpuTicks else {
      DeviceInspectorPlugin.lastTotalCpuTicks = (user, system, idle, nice)
      return nil
    }

    let userDiff = user - last.user
    let sysDiff = system - last.system
    let idleDiff = idle - last.idle
    let niceDiff = nice - last.nice

    DeviceInspectorPlugin.lastTotalCpuTicks = (user, system, idle, nice)

    let totalTicks = userDiff + sysDiff + idleDiff + niceDiff
    guard totalTicks > 0 else { return nil }

    let usedTicks = userDiff + sysDiff + niceDiff
    return (Double(usedTicks) / Double(totalTicks)) * 100.0
  }

  private func calculatePerCoreCpuUsage() -> [Double] {
    var numCPUs: processor_info_array_t?
    var numCPUInfo: mach_msg_type_number_t = 0
    var numCPUsU: natural_t = 0

    let err = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &numCPUsU, &numCPUs, &numCPUInfo)
    guard err == KERN_SUCCESS, let cpuInfo = numCPUs else { return [] }

    let count = Int(numCPUsU)
    var result = [Double]()

    for i in 0..<count {
      let offset = Int(CPU_STATE_MAX) * i
      let user = UInt64(cpuInfo[offset + Int(CPU_STATE_USER)])
      let sys = UInt64(cpuInfo[offset + Int(CPU_STATE_SYSTEM)])
      let idle = UInt64(cpuInfo[offset + Int(CPU_STATE_IDLE)])
      let nice = UInt64(cpuInfo[offset + Int(CPU_STATE_NICE)])

      let total = user + sys + idle + nice
      if total > 0 {
        let usage = (Double(user + sys + nice) / Double(total)) * 100.0
        result.append(usage)
      } else {
        result.append(0.0)
      }
    }

    vm_deallocate(mach_task_self_, vm_address_t(UInt(bitPattern: cpuInfo)), vm_size_t(numCPUInfo) * vm_size_t(MemoryLayout<integer_t>.size))
    return result
  }

  private func getSysctlString(name: String) -> String? {
    var size: Int = 0
    sysctlbyname(name, nil, &size, nil, 0)
    guard size > 0 else { return nil }
    var data = [CChar](repeating: 0, count: size)
    sysctlbyname(name, &data, &size, nil, 0)
    return String(cString: data)
  }

  private func getSysctlInt(name: String) -> Int? {
    var val: Int = 0
    var size = MemoryLayout<Int>.size
    if sysctlbyname(name, &val, &size, nil, 0) == 0 {
      return val
    }
    return nil
  }

  private func getSysctlInt64(name: String) -> Int64? {
    var val: Int64 = 0
    var size = MemoryLayout<Int64>.size
    if sysctlbyname(name, &val, &size, nil, 0) == 0 {
      return val
    }
    return nil
  }

  private func getDeviceModelName() -> String {
    var systemInfo = utsname()
    uname(&systemInfo)
    let machineMirror = Mirror(reflecting: systemInfo.machine)
    let identifier = machineMirror.children.reduce("") { identifier, element in
      guard let value = element.value as? Int8, value != 0 else { return identifier }
      return identifier + String(UnicodeScalar(UInt8(value)))
    }
    return identifier.isEmpty ? "iPhone" : identifier
  }
}
