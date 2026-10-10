package app.hazri

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat

/**
 * Diagnostics (02-notifications DP6): an alarm set straight through Android,
 * without the notification plugin, so a phone that never delivers a scheduled
 * reminder can say which part fails. When it fires it records the moment and
 * posts a notification of its own.
 *
 * Two kinds: "exact" is what reminders use (setExactAndAllowWhileIdle), and
 * "clock" is an alarm-clock alarm (setAlarmClock), which phone makers almost
 * never hold back. If only the second arrives, the phone is stopping Hazri's
 * alarms; if both arrive and reminders still do not, the plugin's path is at
 * fault.
 */
class AlarmProbeReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val kind = intent.getStringExtra(EXTRA_KIND) ?: "exact"
        val now = System.currentTimeMillis()
        prefs(context).edit()
            .putLong("fired_$kind", now)
            .putLong("planned_fired_$kind", intent.getLongExtra(EXTRA_AT, 0L))
            .apply()
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(CHANNEL, "Diagnostics", NotificationManager.IMPORTANCE_HIGH),
            )
        }
        val open = PendingIntent.getActivity(
            context,
            0,
            Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        val title = intent.getStringExtra(EXTRA_TITLE) ?: "Hazri"
        val body = intent.getStringExtra(EXTRA_BODY) ?: kind
        manager.notify(
            if (kind == "clock") 0x2000_0002 else 0x2000_0001,
            NotificationCompat.Builder(context, CHANNEL)
                .setSmallIcon(R.drawable.ic_notification)
                .setContentTitle(title)
                .setContentText(body)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setContentIntent(open)
                .setAutoCancel(true)
                .build(),
        )
    }

    companion object {
        private const val CHANNEL = "diagnostics"
        private const val EXTRA_KIND = "kind"
        private const val EXTRA_AT = "at"
        private const val EXTRA_TITLE = "title"
        private const val EXTRA_BODY = "body"

        private fun prefs(context: Context) = context.getSharedPreferences("hazri_alarm_probe", Context.MODE_PRIVATE)

        /** Sets one probe alarm [seconds] from now; answers the time it is due. */
        fun schedule(context: Context, kind: String, seconds: Int, title: String, body: String): Long {
            val at = System.currentTimeMillis() + seconds * 1000L
            val intent = Intent(context, AlarmProbeReceiver::class.java)
                .putExtra(EXTRA_KIND, kind)
                .putExtra(EXTRA_AT, at)
                .putExtra(EXTRA_TITLE, title)
                .putExtra(EXTRA_BODY, body)
            val pending = PendingIntent.getBroadcast(
                context,
                if (kind == "clock") 2 else 1,
                intent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
            val alarms = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val exactAllowed = Build.VERSION.SDK_INT < Build.VERSION_CODES.S || alarms.canScheduleExactAlarms()
            when {
                kind == "clock" && exactAllowed -> {
                    val show = PendingIntent.getActivity(
                        context,
                        3,
                        Intent(context, MainActivity::class.java),
                        PendingIntent.FLAG_IMMUTABLE,
                    )
                    alarms.setAlarmClock(AlarmManager.AlarmClockInfo(at, show), pending)
                }
                exactAllowed -> alarms.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pending)
                else -> alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pending)
            }
            prefs(context).edit().putLong("planned_$kind", at).apply()
            return at
        }

        /** What was set and what arrived, in epoch milliseconds (0 = never). */
        fun results(context: Context): Map<String, Long> {
            val p = prefs(context)
            return mapOf(
                "plannedExact" to p.getLong("planned_exact", 0L),
                "firedExact" to p.getLong("fired_exact", 0L),
                "plannedClock" to p.getLong("planned_clock", 0L),
                "firedClock" to p.getLong("fired_clock", 0L),
            )
        }
    }
}
