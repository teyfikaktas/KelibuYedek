package com.phdakademi.kelibu

import android.content.Context
import android.os.PowerManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import androidx.annotation.NonNull

class MainActivity: FlutterActivity() {
    private val CHANNEL = "app_settings"
    private val POWER_CHANNEL = "power_manager"

    private fun isPowerSaveMode(): Boolean {
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        return powerManager.isPowerSaveMode
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Mevcut channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call, result ->
            when (call.method) {
                "getManufacturer" -> result.success(android.os.Build.MANUFACTURER)
                "miui_battery_settings" -> {
                    try {
                        val intent = android.content.Intent()
                        intent.component = android.content.ComponentName(
                            "com.miui.powerkeeper",
                            "com.miui.powerkeeper.ui.HiddenAppsContainerManagementActivity"
                        )
                        intent.flags = android.content.Intent.FLAG_ACTIVITY_NEW_TASK
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", "Ayarlar açılamadı", e.message)
                    }
                }
                "android_battery_settings" -> {
                    try {
                        val intent = android.content.Intent(android.provider.Settings.ACTION_BATTERY_SAVER_SETTINGS)
                        intent.flags = android.content.Intent.FLAG_ACTIVITY_NEW_TASK
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", "Ayarlar açılamadı", e.message)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // Yeni power manager channel'ı
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, POWER_CHANNEL).setMethodCallHandler {
                call, result ->
            when (call.method) {
                "isPowerSaveMode" -> result.success(isPowerSaveMode())
                else -> result.notImplemented()
            }
        }
    }
}