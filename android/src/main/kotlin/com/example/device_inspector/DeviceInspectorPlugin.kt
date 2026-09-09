package com.example.device_inspector

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.Sensor
import android.hardware.SensorManager
import android.net.ConnectivityManager
import android.os.BatteryManager
import android.os.Build
import android.os.Environment
import android.os.Process
import android.os.StatFs
import android.os.SystemClock
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File
import java.io.RandomAccessFile
import java.net.NetworkInterface

/** DeviceInspectorPlugin implementation for Android */
class DeviceInspectorPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private var context: Context? = null

    // Last CPU stat counters for delta calculation
    private var lastTotalCpuTime: Long = 0
    private var lastIdleCpuTime: Long = 0
    private var lastPerCoreCpuTime = mutableMapOf<Int, Pair<Long, Long>>()

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "device_inspector")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        context = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        try {
            when (call.method) {
                "getSystemInfo" -> result.success(getSystemInfoMap())
                "getCpuInfo" -> result.success(getCpuInfoMap())
                "getMemoryInfo" -> result.success(getMemoryInfoMap())
                "getGpuInfo" -> result.success(getGpuInfoMap())
                "getStorageInfo" -> result.success(getStorageInfoList())
                "getBatteryInfo" -> result.success(getBatteryInfoMap())
                "getDeviceInfo" -> result.success(getDeviceInfoMap())
                "getOsInfo" -> result.success(getOsInfoMap())
                "getNetworkInfo" -> result.success(getNetworkInfoList())
                "getSensors" -> result.success(getSensorsList())
                "getCapabilities" -> result.success(getCapabilitiesMap())
                "getSystemMetrics" -> result.success(getSystemMetricsMap())
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("NATIVE_ERROR", e.localizedMessage ?: "Native Android execution error", e)
        }
    }

    private fun getSystemInfoMap(): Map<String, Any?> {
        return mapOf(
            "cpu" to safeCall { getCpuInfoMap() },
            "memory" to safeCall { getMemoryInfoMap() },
            "gpu" to safeCall { getGpuInfoMap() },
            "storage" to safeCall { getStorageInfoList() },
            "battery" to safeCall { getBatteryInfoMap() },
            "device" to safeCall { getDeviceInfoMap() },
            "os" to safeCall { getOsInfoMap() },
            "network" to safeCall { getNetworkInfoList() },
            "sensors" to safeCall { getSensorsList() },
            "capabilities" to safeCall { getCapabilitiesMap() }
        )
    }

    private fun getCpuInfoMap(): Map<String, Any?> {
        val logicalCores = Runtime.getRuntime().availableProcessors()
        val abis = Build.SUPPORTED_ABIS
        val primaryAbi = if (abis.isNotEmpty()) abis[0] else System.getProperty("os.arch")
        val is64Bit = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) Process.is64Bit() else primaryAbi?.contains("64") == true

        var cpuName: String? = null
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            cpuName = try { Build.SOC_MODEL } catch (_: Throwable) { null }
        }
        if (cpuName.isNullOrBlank()) {
            cpuName = readCpuInfoKey("Hardware") ?: readCpuInfoKey("model name") ?: Build.HARDWARE
        }

        val vendor = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            try { Build.SOC_MANUFACTURER } catch (_: Throwable) { Build.MANUFACTURER }
        } else {
            Build.MANUFACTURER
        }

        val featuresList = readCpuInfoKey("Features")?.split("\\s+".toRegex()) ?: emptyList()

        // Read frequency info
        val coreFrequencies = mutableListOf<Double>()
        var curFreqSum = 0.0
        var minFreqVal: Double? = null
        var maxFreqVal: Double? = null

        val coresList = mutableListOf<Map<String, Any?>>()
        for (i in 0 until logicalCores) {
            val cur = readSysFile("/sys/devices/system/cpu/cpu$i/cpufreq/scaling_cur_freq")?.toDoubleOrNull()?.div(1000.0)
            val min = readSysFile("/sys/devices/system/cpu/cpu$i/cpufreq/cpuinfo_min_freq")?.toDoubleOrNull()?.div(1000.0)
            val max = readSysFile("/sys/devices/system/cpu/cpu$i/cpufreq/cpuinfo_max_freq")?.toDoubleOrNull()?.div(1000.0)

            if (cur != null) {
                coreFrequencies.add(cur)
                curFreqSum += cur
            }
            if (min != null) {
                val currentMin = minFreqVal
                minFreqVal = if (currentMin == null) min else (if (min < currentMin) min else currentMin)
            }
            if (max != null) {
                val currentMax = maxFreqVal
                maxFreqVal = if (currentMax == null) max else (if (max > currentMax) max else currentMax)
            }

            coresList.add(
                mapOf(
                    "id" to i,
                    "usagePercent" to getPerCoreCpuUsage(i),
                    "currentFrequencyMHz" to cur,
                    "minFrequencyMHz" to min,
                    "maxFrequencyMHz" to max
                )
            )
        }

        val avgCurFreq = if (coreFrequencies.isNotEmpty()) curFreqSum / coreFrequencies.size else null
        val overallCpuUsage = calculateCpuUsagePercent()

        return mapOf(
            "name" to cpuName,
            "vendor" to vendor,
            "architecture" to primaryAbi,
            "physicalCores" to logicalCores,
            "logicalCores" to logicalCores,
            "is64Bit" to is64Bit,
            "features" to featuresList,
            "l1CacheBytes" to null,
            "l2CacheBytes" to null,
            "l3CacheBytes" to null,
            "currentFrequencyMHz" to avgCurFreq,
            "minFrequencyMHz" to minFreqVal,
            "maxFrequencyMHz" to maxFreqVal,
            "usagePercent" to overallCpuUsage,
            "cores" to coresList
        )
    }

    private fun getMemoryInfoMap(): Map<String, Any?> {
        val ctx = context
        var totalBytes: Long? = null
        var availBytes: Long? = null

        if (ctx != null) {
            val actMgr = ctx.getSystemService(Context.ACTIVITY_SERVICE) as? android.app.ActivityManager
            val memInfo = android.app.ActivityManager.MemoryInfo()
            if (actMgr != null) {
                actMgr.getMemoryInfo(memInfo)
                totalBytes = memInfo.totalMem
                availBytes = memInfo.availMem
            }
        }

        // Fallback or swap reading via /proc/meminfo
        val memMap = parseProcMeminfo()
        if (totalBytes == null || totalBytes <= 0) {
            totalBytes = memMap["MemTotal"]
        }
        if (availBytes == null || availBytes <= 0) {
            availBytes = memMap["MemAvailable"] ?: memMap["MemFree"]
        }

        val usedBytes = if (totalBytes != null && availBytes != null) totalBytes - availBytes else null
        val usagePercent = if (totalBytes != null && totalBytes > 0 && usedBytes != null) {
            (usedBytes.toDouble() / totalBytes.toDouble()) * 100.0
        } else null

        val swapTotal = memMap["SwapTotal"]
        val swapFree = memMap["SwapFree"]
        val swapUsed = if (swapTotal != null && swapFree != null) swapTotal - swapFree else null

        return mapOf(
            "totalBytes" to totalBytes,
            "usedBytes" to usedBytes,
            "availableBytes" to availBytes,
            "freeBytes" to availBytes,
            "usagePercent" to usagePercent,
            "swapTotalBytes" to swapTotal,
            "swapUsedBytes" to swapUsed,
            "swapFreeBytes" to swapFree
        )
    }

    private fun getGpuInfoMap(): Map<String, Any?> {
        return mapOf(
            "name" to Build.HARDWARE,
            "vendor" to Build.MANUFACTURER,
            "renderer" to (readCpuInfoKey("Hardware") ?: Build.HARDWARE),
            "driverVersion" to null,
            "vramBytes" to null,
            "graphicsApis" to listOf("Vulkan", "OpenGL ES 3.2"),
            "isDiscrete" to false
        )
    }

    private fun getStorageInfoList(): List<Map<String, Any?>> {
        val list = mutableListOf<Map<String, Any?>>()
        try {
            val internalPath = Environment.getDataDirectory().path
            val stat = StatFs(internalPath)
            val totalBytes = stat.blockCountLong * stat.blockSizeLong
            val freeBytes = stat.availableBlocksLong * stat.blockSizeLong
            val usedBytes = totalBytes - freeBytes

            list.add(
                mapOf(
                    "path" to internalPath,
                    "name" to "Internal Storage",
                    "totalBytes" to totalBytes,
                    "usedBytes" to usedBytes,
                    "freeBytes" to freeBytes,
                    "fileSystem" to "ext4/f2fs",
                    "type" to "internal"
                )
            )

            if (Environment.getExternalStorageState() == Environment.MEDIA_MOUNTED) {
                val extPath = Environment.getExternalStorageDirectory().path
                if (extPath != internalPath) {
                    val extStat = StatFs(extPath)
                    val extTotal = extStat.blockCountLong * extStat.blockSizeLong
                    val extFree = extStat.availableBlocksLong * extStat.blockSizeLong
                    val extUsed = extTotal - extFree

                    list.add(
                        mapOf(
                            "path" to extPath,
                            "name" to "External Storage",
                            "totalBytes" to extTotal,
                            "usedBytes" to extUsed,
                            "freeBytes" to extFree,
                            "fileSystem" to "sdcardfs/fuse",
                            "type" to "external"
                        )
                    )
                }
            }
        } catch (_: Throwable) {}
        return list
    }

    private fun getBatteryInfoMap(): Map<String, Any?> {
        val ctx = context ?: return emptyMap()
        val filter = IntentFilter(Intent.ACTION_BATTERY_CHANGED)
        val batteryStatus: Intent? = ctx.registerReceiver(null, filter)

        if (batteryStatus == null) return emptyMap()

        val level = batteryStatus.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
        val scale = batteryStatus.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
        val levelPercent = if (level >= 0 && scale > 0) (level * 100.0) / scale else null

        val statusInt = batteryStatus.getIntExtra(BatteryManager.EXTRA_STATUS, -1)
        val isCharging = statusInt == BatteryManager.BATTERY_STATUS_CHARGING ||
                statusInt == BatteryManager.BATTERY_STATUS_FULL

        val statusStr = when (statusInt) {
            BatteryManager.BATTERY_STATUS_CHARGING -> "charging"
            BatteryManager.BATTERY_STATUS_DISCHARGING -> "discharging"
            BatteryManager.BATTERY_STATUS_FULL -> "full"
            BatteryManager.BATTERY_STATUS_NOT_CHARGING -> "notCharging"
            else -> "unknown"
        }

        val healthInt = batteryStatus.getIntExtra(BatteryManager.EXTRA_HEALTH, -1)
        val healthStr = when (healthInt) {
            BatteryManager.BATTERY_HEALTH_GOOD -> "Good"
            BatteryManager.BATTERY_HEALTH_OVERHEAT -> "Overheat"
            BatteryManager.BATTERY_HEALTH_DEAD -> "Dead"
            BatteryManager.BATTERY_HEALTH_OVER_VOLTAGE -> "Over Voltage"
            BatteryManager.BATTERY_HEALTH_UNSPECIFIED_FAILURE -> "Failure"
            BatteryManager.BATTERY_HEALTH_COLD -> "Cold"
            else -> "Unknown"
        }

        val tempTenths = batteryStatus.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, -1)
        val tempCelsius = if (tempTenths > 0) tempTenths / 10.0 else null

        val voltageMv = batteryStatus.getIntExtra(BatteryManager.EXTRA_VOLTAGE, -1)
        val voltageVolts = if (voltageMv > 0) voltageMv / 1000.0 else null

        var currentMa: Double? = null
        var capacityMah: Int? = null

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            val bm = ctx.getSystemService(Context.BATTERY_SERVICE) as? BatteryManager
            if (bm != null) {
                val curUa = bm.getIntProperty(BatteryManager.BATTERY_PROPERTY_CURRENT_NOW)
                if (curUa != Int.MIN_VALUE && curUa != 0) {
                    currentMa = curUa / 1000.0
                }
                val capUah = bm.getIntProperty(BatteryManager.BATTERY_PROPERTY_CHARGE_COUNTER)
                if (capUah != Int.MIN_VALUE && capUah > 0) {
                    capacityMah = capUah / 1000
                }
            }
        }

        return mapOf(
            "levelPercent" to levelPercent,
            "status" to statusStr,
            "isCharging" to isCharging,
            "health" to healthStr,
            "temperatureCelsius" to tempCelsius,
            "voltageVolts" to voltageVolts,
            "currentMilliAmperes" to currentMa,
            "capacityMilliAmpereHours" to capacityMah
        )
    }

    private fun getDeviceInfoMap(): Map<String, Any?> {
        val uptimeSec = SystemClock.elapsedRealtime() / 1000
        val abis = Build.SUPPORTED_ABIS
        val primaryAbi = if (abis.isNotEmpty()) abis[0] else System.getProperty("os.arch")

        return mapOf(
            "manufacturer" to Build.MANUFACTURER,
            "model" to Build.MODEL,
            "deviceName" to Build.DEVICE,
            "hostName" to Build.HOST,
            "architecture" to primaryAbi,
            "osName" to "Android",
            "osVersion" to Build.VERSION.RELEASE,
            "kernelVersion" to System.getProperty("os.version"),
            "buildNumber" to Build.DISPLAY,
            "uptimeSeconds" to uptimeSec
        )
    }

    private fun getOsInfoMap(): Map<String, Any?> {
        val abis = Build.SUPPORTED_ABIS
        val primaryAbi = if (abis.isNotEmpty()) abis[0] else System.getProperty("os.arch")
        val is64Bit = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) Process.is64Bit() else primaryAbi?.contains("64") == true

        return mapOf(
            "name" to "Android",
            "version" to Build.VERSION.RELEASE,
            "buildNumber" to Build.DISPLAY,
            "kernelVersion" to System.getProperty("os.version"),
            "architecture" to primaryAbi,
            "hostName" to Build.HOST,
            "is64Bit" to is64Bit
        )
    }

    private fun getNetworkInfoList(): List<Map<String, Any?>> {
        val result = mutableListOf<Map<String, Any?>>()
        try {
            val interfaces = NetworkInterface.getNetworkInterfaces() ?: return emptyList()

            while (interfaces.hasMoreElements()) {
                val iface = interfaces.nextElement()
                if (iface.isLoopback) continue

                var ipv4: String? = null
                var ipv6: String? = null
                val addrs = iface.inetAddresses
                while (addrs.hasMoreElements()) {
                    val addr = addrs.nextElement()
                    if (!addr.isLoopbackAddress) {
                        val host = addr.hostAddress
                        if (host != null) {
                            if (!host.contains(":")) {
                                ipv4 = host
                            } else {
                                ipv6 = host.split("%")[0]
                            }
                        }
                    }
                }

                val type = when {
                    iface.name.contains("wlan") -> "wifi"
                    iface.name.contains("rmnet") || iface.name.contains("ccmni") -> "cellular"
                    iface.name.contains("eth") -> "ethernet"
                    iface.name.contains("tun") || iface.name.contains("ppp") -> "vpn"
                    else -> "unknown"
                }

                var macAddress: String? = null
                try {
                    val macBytes = iface.hardwareAddress
                    if (macBytes != null && macBytes.isNotEmpty()) {
                        macAddress = macBytes.joinToString(":") { String.format("%02X", it) }
                    }
                } catch (_: Throwable) {}

                result.add(
                    mapOf(
                        "interfaceName" to iface.name,
                        "interfaceType" to type,
                        "status" to if (iface.isUp) "up" else "down",
                        "ipv4Address" to ipv4,
                        "ipv6Address" to ipv6,
                        "linkSpeedMbps" to null,
                        "macAddress" to macAddress
                    )
                )
            }
        } catch (_: Throwable) {}
        return result
    }

    private fun getSensorsList(): List<Map<String, Any?>> {
        val ctx = context ?: return emptyList()
        val sm = ctx.getSystemService(Context.SENSOR_SERVICE) as? SensorManager ?: return emptyList()
        val sensors = sm.getSensorList(Sensor.TYPE_ALL)

        val result = mutableListOf<Map<String, Any?>>()
        for (s in sensors) {
            val typeStr = mapSensorType(s.type)
            result.add(
                mapOf(
                    "type" to typeStr,
                    "name" to s.name,
                    "vendor" to s.vendor,
                    "isAvailable" to true,
                    "powerMilliAmperes" to s.power.toDouble(),
                    "resolution" to s.resolution.toDouble()
                )
            )
        }
        return result
    }

    private fun getCapabilitiesMap(): Map<String, Boolean> {
        return mapOf(
            "cpuInfo" to true,
            "cpuUsage" to true,
            "cpuFrequency" to true,
            "perCoreUsage" to true,
            "gpuInfo" to true,
            "memoryInfo" to true,
            "storageInfo" to true,
            "batteryInfo" to true,
            "networkInfo" to true,
            "sensorInfo" to true
        )
    }

    private fun getSystemMetricsMap(): Map<String, Any?> {
        val cpuUsage = calculateCpuUsagePercent()
        val mem = getMemoryInfoMap()
        val battery = getBatteryInfoMap()
        val storage = getStorageInfoList().firstOrNull()

        val logicalCores = Runtime.getRuntime().availableProcessors()
        val perCoreUsage = mutableListOf<Double>()
        for (i in 0 until logicalCores) {
            val usage = getPerCoreCpuUsage(i)
            if (usage != null) perCoreUsage.add(usage)
        }

        return mapOf(
            "timestamp" to System.currentTimeMillis(),
            "cpuUsagePercent" to cpuUsage,
            "perCoreCpuUsagePercent" to perCoreUsage,
            "memoryUsagePercent" to mem["usagePercent"],
            "availableMemoryBytes" to mem["availableBytes"],
            "batteryLevelPercent" to battery["levelPercent"],
            "isCharging" to battery["isCharging"],
            "storageFreeBytes" to storage?.get("freeBytes"),
            "networkRxBytesPerSecond" to null,
            "networkTxBytesPerSecond" to null
        )
    }

    private fun calculateCpuUsagePercent(): Double? {
        return try {
            val reader = RandomAccessFile("/proc/stat", "r")
            val line = reader.readLine()
            reader.close()
            if (line == null || !line.startsWith("cpu ")) return null

            val toks = line.split("\\s+".toRegex())
            if (toks.size < 8) return null

            val user = toks[1].toLong()
            val nice = toks[2].toLong()
            val system = toks[3].toLong()
            val idle = toks[4].toLong()
            val iowait = toks[5].toLong()
            val irq = toks[6].toLong()
            val softirq = toks[7].toLong()

            val total = user + nice + system + idle + iowait + irq + softirq
            val idleTime = idle + iowait

            if (lastTotalCpuTime == 0L) {
                lastTotalCpuTime = total
                lastIdleCpuTime = idleTime
                return null
            }

            val totalDiff = total - lastTotalCpuTime
            val idleDiff = idleTime - lastIdleCpuTime

            lastTotalCpuTime = total
            lastIdleCpuTime = idleTime

            if (totalDiff <= 0) return null
            val usage = ((totalDiff - idleDiff).toDouble() / totalDiff.toDouble()) * 100.0
            usage.coerceIn(0.0, 100.0)
        } catch (_: Throwable) {
            null
        }
    }

    private fun getPerCoreCpuUsage(coreIndex: Int): Double? {
        return try {
            val reader = RandomAccessFile("/proc/stat", "r")
            var line: String? = null
            val targetKey = "cpu$coreIndex "
            while (reader.readLine()?.also { line = it } != null) {
                if (line!!.startsWith(targetKey)) break
            }
            reader.close()

            val curLine = line ?: return null
            val toks = curLine.split("\\s+".toRegex())
            if (toks.size < 8) return null

            val user = toks[1].toLong()
            val nice = toks[2].toLong()
            val system = toks[3].toLong()
            val idle = toks[4].toLong()
            val iowait = toks[5].toLong()
            val irq = toks[6].toLong()
            val softirq = toks[7].toLong()

            val total = user + nice + system + idle + iowait + irq + softirq
            val idleTime = idle + iowait

            val last = lastPerCoreCpuTime[coreIndex]
            lastPerCoreCpuTime[coreIndex] = Pair(total, idleTime)

            if (last == null) return null

            val totalDiff = total - last.first
            val idleDiff = idleTime - last.second

            if (totalDiff <= 0) return null
            val usage = ((totalDiff - idleDiff).toDouble() / totalDiff.toDouble()) * 100.0
            usage.coerceIn(0.0, 100.0)
        } catch (_: Throwable) {
            null
        }
    }

    private fun readCpuInfoKey(key: String): String? {
        return try {
            val file = File("/proc/cpuinfo")
            if (!file.exists()) return null
            file.useLines { lines ->
                for (line in lines) {
                    if (line.contains(":")) {
                        val parts = line.split(":")
                        if (parts[0].trim().equals(key, ignoreCase = true)) {
                            return parts[1].trim()
                        }
                    }
                }
            }
            null
        } catch (_: Throwable) {
            null
        }
    }

    private fun parseProcMeminfo(): Map<String, Long> {
        val map = mutableMapOf<String, Long>()
        try {
            val file = File("/proc/meminfo")
            if (!file.exists()) return map
            file.useLines { lines ->
                for (line in lines) {
                    val parts = line.split(":")
                    if (parts.size >= 2) {
                        val key = parts[0].trim()
                        val valStr = parts[1].trim().replace("kB", "").trim()
                        val kb = valStr.toLongOrNull()
                        if (kb != null) {
                            map[key] = kb * 1024L
                        }
                    }
                }
            }
        } catch (_: Throwable) {}
        return map
    }

    private fun readSysFile(path: String): String? {
        return try {
            val file = File(path)
            if (file.exists()) file.readText().trim() else null
        } catch (_: Throwable) {
            null
        }
    }

    private fun mapSensorType(type: Int): String {
        return when (type) {
            Sensor.TYPE_ACCELEROMETER -> "accelerometer"
            Sensor.TYPE_GYROSCOPE -> "gyroscope"
            Sensor.TYPE_MAGNETIC_FIELD -> "magnetometer"
            Sensor.TYPE_PROXIMITY -> "proximity"
            Sensor.TYPE_LIGHT -> "ambientLight"
            Sensor.TYPE_PRESSURE -> "barometer"
            Sensor.TYPE_GRAVITY -> "gravity"
            Sensor.TYPE_LINEAR_ACCELERATION -> "linearAcceleration"
            Sensor.TYPE_ROTATION_VECTOR -> "rotationVector"
            Sensor.TYPE_STEP_COUNTER -> "stepCounter"
            Sensor.TYPE_RELATIVE_HUMIDITY -> "humidity"
            Sensor.TYPE_AMBIENT_TEMPERATURE -> "temperature"
            else -> "unknown"
        }
    }

    private inline fun <T> safeCall(action: () -> T): T? {
        return try { action() } catch (_: Throwable) { null }
    }
}
