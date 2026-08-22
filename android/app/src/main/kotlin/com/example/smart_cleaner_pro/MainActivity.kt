package com.example.smart_cleaner_pro

import android.app.ActivityManager
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "smart_cleaner_pro/battery"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "getBatteryDetails") {
                    result.success(getBatteryDetails())
                } else if (call.method == "getDeviceMemory") {
                    result.success(getDeviceMemory())
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun getBatteryDetails(): Map<String, Any?> {
        val intent = registerReceiver(
            null,
            IntentFilter(Intent.ACTION_BATTERY_CHANGED)
        )

        val tempTenthsCelsius =
            intent?.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, -1) ?: -1
        val voltageMillivolts =
            intent?.getIntExtra(BatteryManager.EXTRA_VOLTAGE, -1) ?: -1
        val healthCode =
            intent?.getIntExtra(BatteryManager.EXTRA_HEALTH, -1) ?: -1
        val technology =
            intent?.getStringExtra(BatteryManager.EXTRA_TECHNOLOGY)

        return mapOf(
            "temperatureCelsius" to
                    if (tempTenthsCelsius >= 0) tempTenthsCelsius / 10.0
                    else null,
            "voltage" to
                    if (voltageMillivolts >= 0) voltageMillivolts / 1000.0
                    else null,
            "health" to healthLabel(healthCode),
            "technology" to technology
        )
    }

    private fun getDeviceMemory(): Map<String, Any?> {
        val activityManager = getSystemService(ACTIVITY_SERVICE) as ActivityManager
        val memoryInfo = ActivityManager.MemoryInfo()
        activityManager.getMemoryInfo(memoryInfo)
        val totalGB = memoryInfo.totalMem / (1024.0 * 1024.0 * 1024.0)
        val availableGB = memoryInfo.availMem / (1024.0 * 1024.0 * 1024.0)
        return mapOf(
            "totalGB" to totalGB,
            "availableGB" to availableGB
        )
    }

    private fun healthLabel(code: Int): String = when (code) {
        BatteryManager.BATTERY_HEALTH_GOOD -> "Good"
        BatteryManager.BATTERY_HEALTH_OVERHEAT -> "Overheating"
        BatteryManager.BATTERY_HEALTH_DEAD -> "Dead"
        BatteryManager.BATTERY_HEALTH_OVER_VOLTAGE -> "Over voltage"
        BatteryManager.BATTERY_HEALTH_UNSPECIFIED_FAILURE -> "Unspecified failure"
        BatteryManager.BATTERY_HEALTH_COLD -> "Cold"
        else -> "Unknown"
    }
}