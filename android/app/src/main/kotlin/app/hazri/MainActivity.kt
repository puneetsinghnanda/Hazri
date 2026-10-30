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

    // 02-notifications DP7: Hazri's own reminders, and the tap that opened
    // the app from one, held until Dart asks for it.
    private var reminders: MethodChannel? = null
    private var launchTap: Map<String, Any?>? = null

    private fun tapOf(intent: Intent?): Map<String, Any?>? {
        if (intent?.action != Reminders.ACTION_TAP) return null
        intent.getIntExtra(Reminders.EXTRA_ID, 0).let { if (it != 0) Reminders.dismiss(this, it) }
        return mapOf(
            "payload" to intent.getStringExtra(Reminders.EXTRA_PAYLOAD),
            "action" to intent.getStringExtra(Reminders.EXTRA_ACTION),
        )
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val tap = tapOf(intent) ?: return
        val open = reminders
        if (open != null) open.invokeMethod("tap", tap) else launchTap = tap
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        // Android 15+ enforces edge-to-edge; opting in on every version keeps
        // one layout path, and Flutter handles the insets per screen.
        WindowCompat.setDecorFitsSystemWindows(window, false)
        super.onCreate(savedInstanceState)
        tapOf(intent)?.let { launchTap = it }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            window.isNavigationBarContrastEnforced = false
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        reminders = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.hazri/reminders").apply {
            setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "schedule" -> {
                            val args = call.arguments as Map<*, *>
                            val json = org.json.JSONObject()
                            for ((k, v) in args) json.put(k as String, if (v is Number && k == "at") v.toLong() else v)
                            Reminders.schedule(this@MainActivity, json)
                            result.success(null)
                        }
                        "cancel" -> {
                            Reminders.cancel(this@MainActivity, (call.argument<Number>("id") ?: 0).toInt())
                            result.success(null)
                        }
                        "dismiss" -> {
                            Reminders.dismiss(this@MainActivity, (call.argument<Number>("id") ?: 0).toInt())
                            result.success(null)
                        }
                        "pending" -> result.success(Reminders.pending(this@MainActivity))
                        "takeLaunchTap" -> {
                            result.success(launchTap)
                            launchTap = null
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("reminders", e.toString(), null)
                }
            }
        }
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
                    // 01-accounts §12: a web page in the browser, for the
                    // account deletion page. False when no app can open it.
                    "openUrl" -> {
                        val intent = Intent(
                            Intent.ACTION_VIEW,
                            android.net.Uri.parse(call.argument<String>("url") ?: ""),
                        ).addCategory(Intent.CATEGORY_BROWSABLE)
                        try {
                            startActivity(intent)
                            result.success(true)
                        } catch (_: android.content.ActivityNotFoundException) {
                            result.success(false)
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
