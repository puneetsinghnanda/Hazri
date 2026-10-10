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
import org.json.JSONArray
import org.json.JSONObject

/**
 * Hazri's own reminder scheduler (02-notifications DP7, 2026-10-11).
 *
 * The notification plugin's scheduled path never showed a single reminder on
 * the owner's phone, while an alarm set straight through Android and a
 * notification posted from its receiver arrived to the second (DP6). So every
 * planned reminder is now an alarm Hazri sets itself: the reminder is stored
 * as JSON in its own preferences, the alarm carries only its id, and
 * [ReminderReceiver] reads it back and posts it. Nothing here goes through
 * Gson or reflection, so R8 has nothing to strip.
 *
 * A reminder: id, at (epoch ms), title, body, channelId, channelName,
 * payload (the Dart NotificationPayload JSON: route and actions), progress,
 * maxProgress.
 */
object Reminders {
    private const val PREFS = "hazri_reminders"
    const val ACTION_TAP = "app.hazri.NOTIFICATION_TAP"
    const val EXTRA_PAYLOAD = "hazri_payload"
    const val EXTRA_ACTION = "hazri_action"
    const val EXTRA_ID = "hazri_id"

    /** Set on a snoozed copy's id, as in Dart's ReminderPlanner.snoozeBit. */
    const val SNOOZE_BIT = 0x40000000

    private fun prefs(context: Context) = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun alarmIntent(context: Context, id: Int): PendingIntent = PendingIntent.getBroadcast(
        context,
        id,
        Intent(context, ReminderReceiver::class.java).putExtra(EXTRA_ID, id),
        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
    )

    fun canExact(context: Context): Boolean {
        val alarms = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.S || alarms.canScheduleExactAlarms()
    }

    /** Stores [reminder] and sets its alarm; replaces one with the same id. */
    fun schedule(context: Context, reminder: JSONObject) {
        val id = reminder.getInt("id")
        val at = reminder.getLong("at")
        prefs(context).edit().putString("r_$id", reminder.toString()).apply()
        arm(context, id, at)
    }

    private fun arm(context: Context, id: Int, at: Long) {
        val alarms = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pending = alarmIntent(context, id)
        if (canExact(context)) {
            alarms.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pending)
        } else {
            alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pending)
        }
    }

    /** Cancels a stored reminder's alarm and forgets it. */
    fun cancel(context: Context, id: Int) {
        val alarms = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarms.cancel(alarmIntent(context, id))
        prefs(context).edit().remove("r_$id").apply()
    }

    /** Takes a showing notification off the screen. */
    fun dismiss(context: Context, id: Int) {
        (context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager).cancel(id)
    }

    /** Every stored reminder still to come: id and due time. */
    fun pending(context: Context): List<Map<String, Any>> {
        val now = System.currentTimeMillis()
        return stored(context)
            .filter { it.optLong("at") > now }
            .map { mapOf("id" to it.getInt("id"), "at" to it.getLong("at"), "title" to it.optString("title")) }
    }

    private fun stored(context: Context): List<JSONObject> = prefs(context).all.entries
        .filter { it.key.startsWith("r_") }
        .mapNotNull { e -> (e.value as? String)?.let { runCatching { JSONObject(it) }.getOrNull() } }

    /** After a reboot, an update or a clock change: every future alarm again. */
    fun rearmAll(context: Context) {
        val now = System.currentTimeMillis()
        for (r in stored(context)) {
            val id = r.getInt("id")
            if (r.optLong("at") > now) arm(context, id, r.getLong("at")) else prefs(context).edit().remove("r_$id").apply()
        }
    }

    fun take(context: Context, id: Int): JSONObject? {
        val raw = prefs(context).getString("r_$id", null) ?: return null
        prefs(context).edit().remove("r_$id").apply()
        return runCatching { JSONObject(raw) }.getOrNull()
    }

    /** Posts [r] as a notification: high importance, its buttons, its progress. */
    fun post(context: Context, r: JSONObject) {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val id = r.getInt("id")
        val channelId = r.optString("channelId", "goal_reminders_v2")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && manager.getNotificationChannel(channelId) == null) {
            manager.createNotificationChannel(
                NotificationChannel(channelId, r.optString("channelName", "Hazri"), NotificationManager.IMPORTANCE_HIGH),
            )
        }
        val payload = r.optString("payload", "")
        val body = r.optString("body", "")
        val builder = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(r.optString("title", "Hazri"))
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
            .setAutoCancel(true)
            .setContentIntent(openIntent(context, id, payload, null))
        val max = r.optInt("maxProgress", 0)
        if (max > 0) builder.setProgress(max, r.optInt("progress", 0), false)

        // Buttons from the payload's actions: one that opens a route opens
        // the app on it; "snooze" re-sends once in 15 minutes without opening
        // it (GR3); one with no route only dismisses ("Later").
        val actions = runCatching { JSONObject(payload).optJSONArray("actions") }.getOrNull() ?: JSONArray()
        for (i in 0 until actions.length()) {
            val a = actions.getJSONObject(i)
            val actionId = a.optString("id")
            val label = a.optString("label")
            val intent = when {
                actionId == "snooze" -> broadcast(context, id, i, ReminderActionReceiver.SNOOZE)
                a.has("route") -> openIntent(context, id, payload, actionId, i + 1)
                else -> broadcast(context, id, i, ReminderActionReceiver.DISMISS)
            }
            builder.addAction(0, label, intent)
        }
        manager.notify(id, builder.build())
    }

    private fun openIntent(context: Context, id: Int, payload: String, actionId: String?, slot: Int = 0): PendingIntent {
        val intent = Intent(context, MainActivity::class.java)
            .setAction(ACTION_TAP)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            .putExtra(EXTRA_ID, id)
            .putExtra(EXTRA_PAYLOAD, payload)
        if (actionId != null) intent.putExtra(EXTRA_ACTION, actionId)
        // A request code per notification and button, so their extras stay apart.
        return PendingIntent.getActivity(
            context,
            (id and 0x0FFFFFFF) * 8 + slot,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }

    private fun broadcast(context: Context, id: Int, index: Int, what: String): PendingIntent = PendingIntent.getBroadcast(
        context,
        (id and 0x0FFFFFFF) * 8 + index + 1,
        Intent(context, ReminderActionReceiver::class.java).setAction(what).putExtra(EXTRA_ID, id),
        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
    )

    /** The notification [id] last posted, kept so a snooze can re-send it. */
    fun remember(context: Context, r: JSONObject) {
        prefs(context).edit().putString("shown_${r.getInt("id")}", r.toString()).apply()
    }

    fun shown(context: Context, id: Int): JSONObject? =
        prefs(context).getString("shown_$id", null)?.let { runCatching { JSONObject(it) }.getOrNull() }
}

/** An alarm set by [Reminders] has fired: post the reminder it stands for. */
class ReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getIntExtra(Reminders.EXTRA_ID, 0)
        val r = Reminders.take(context, id) ?: return
        Reminders.remember(context, r)
        Reminders.post(context, r)
    }
}

/** A button that does not open the app: the snooze, or "Later". */
class ReminderActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getIntExtra(Reminders.EXTRA_ID, 0)
        Reminders.dismiss(context, id)
        if (intent.action != SNOOZE) return
        val shown = Reminders.shown(context, id) ?: return
        // GR3: once, 15 minutes on, with no second snooze.
        val payload = runCatching { JSONObject(shown.optString("payload", "{}")) }.getOrNull() ?: JSONObject()
        val kept = JSONArray()
        val actions = payload.optJSONArray("actions") ?: JSONArray()
        for (i in 0 until actions.length()) {
            if (actions.getJSONObject(i).optString("id") == "open") kept.put(actions.getJSONObject(i))
        }
        payload.put("actions", kept)
        val copy = JSONObject(shown.toString())
            .put("id", id xor Reminders.SNOOZE_BIT)
            .put("at", System.currentTimeMillis() + 15 * 60 * 1000L)
            .put("payload", payload.toString())
        Reminders.schedule(context, copy)
    }

    companion object {
        const val SNOOZE = "app.hazri.REMINDER_SNOOZE"
        const val DISMISS = "app.hazri.REMINDER_DISMISS"
    }
}

/** A reboot, an app update or a clock change clears or moves alarms: set them again. */
class ReminderBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        Reminders.rearmAll(context)
    }
}
