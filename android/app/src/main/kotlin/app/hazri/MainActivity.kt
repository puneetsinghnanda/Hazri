package app.hazri

import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import androidx.core.view.WindowCompat
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
                    else -> result.notImplemented()
                }
            }
    }
}
