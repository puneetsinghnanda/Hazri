package app.hazri

import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import androidx.core.view.WindowCompat
import com.android.installreferrer.api.InstallReferrerClient
import com.android.installreferrer.api.InstallReferrerStateListener
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// AudioServiceActivity, so a notification or lock-screen tap reaches the
// running instance rather than starting a second one.
class MainActivity : AudioServiceActivity() {
    private val channel = "app.hazri/system"

    override fun onCreate(savedInstanceState: Bundle?) {
        // Android 15+ enforces edge-to-edge; opting in on every version keeps
        // one layout path, and Flutter handles the insets per screen.
        WindowCompat.setDecorFitsSystemWindows(window, false)
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            window.isNavigationBarContrastEnforced = false
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // Once notifications are denied, Android will not ask
                    // again, so the only way back is the settings page.
                    "openNotificationSettings" -> {
                        val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                            .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                        startActivity(intent)
                        result.success(true)
                    }
                    // Diagnostics (02-notifications DP4): whether Android's
                    // battery optimisation is off for Hazri.
                    "ignoringBatteryOptimizations" -> {
                        val pm = getSystemService(POWER_SERVICE) as PowerManager
                        result.success(pm.isIgnoringBatteryOptimizations(packageName))
                    }
                    // 02-notifications DP6: probe alarms set straight
                    // through Android, and what became of them.
                    "probeAlarm" -> {
                        val at = AlarmProbeReceiver.schedule(
                            this,
                            call.argument<String>("kind") ?: "exact",
                            call.argument<Int>("seconds") ?: 60,
                            call.argument<String>("title") ?: "Hazri",
                            call.argument<String>("body") ?: "",
                        )
                        result.success(at)
                    }
                    "probeResults" -> result.success(AlarmProbeReceiver.results(this))
                    // DP6: the system list where Hazri's battery
                    // optimisation is switched off. The list, not the one-tap
                    // request, which Play reserves for a few kinds of app.
                    "openBatterySettings" -> {
                        val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                        try {
                            startActivity(intent)
                            result.success(true)
                        } catch (_: Exception) {
                            startActivity(
                                Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                                    .setData(android.net.Uri.parse("package:$packageName")),
                            )
                            result.success(true)
                        }
                    }
                    // 08-sangat IV6: the Play install referrer, once. Answers
                    // null when Play has none or the service is missing.
                    "installReferrer" -> readInstallReferrer(result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun readInstallReferrer(result: MethodChannel.Result) {
        val client = InstallReferrerClient.newBuilder(this).build()
        var answered = false
        fun answer(value: String?) {
            if (answered) return
            answered = true
            runOnUiThread { result.success(value) }
            try {
                client.endConnection()
            } catch (_: Exception) {
            }
        }
        try {
            client.startConnection(object : InstallReferrerStateListener {
                override fun onInstallReferrerSetupFinished(responseCode: Int) {
                    if (responseCode == InstallReferrerClient.InstallReferrerResponse.OK) {
                        answer(
                            try {
                                client.installReferrer.installReferrer
                            } catch (_: Exception) {
                                null
                            },
                        )
                    } else {
                        answer(null)
                    }
                }

                override fun onInstallReferrerServiceDisconnected() {
                    answer(null)
                }
            })
        } catch (_: Exception) {
            answer(null)
        }
    }
}
