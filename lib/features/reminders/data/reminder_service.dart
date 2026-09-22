import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Set during bootstrap in `main.dart`.
final reminderServiceProvider = Provider<ReminderService>(
  (ref) => throw UnimplementedError('ReminderService must be overridden at startup'),
);

/// What a notification asks the app to open when tapped.
typedef ReminderTapHandler = void Function(String payload);

/// The notification channels the app declares, so each can be tuned
/// separately in system settings (PRD 1.10).
enum ReminderChannel {
  nitnem('nitnem_reminders'),
  simran('daily_simran'),
  gurpurab('gurpurab'),
  goals('paath_goals');

  const ReminderChannel(this.id);

  final String id;
}

/// The id of the simran end bell. Below every id `notificationIdFor` can
/// produce, which start at 2.
const int kSimranEndNotificationId = 1;

/// One notification to post at one instant.
@immutable
class ScheduledNotification {
  const ScheduledNotification({
    required this.id,
    required this.at,
    required this.title,
    required this.body,
    required this.channel,
    required this.channelName,
    required this.payload,
  });

  final int id;
  final DateTime at;
  final String title;
  final String body;
  final ReminderChannel channel;
  final String channelName;

  /// The route to open, e.g. `/reader/japji-sahib?autoplay=0`.
  final String payload;
}

/// Wraps the local-notification plugin: permissions, channels and the rolling
/// schedule.
class ReminderService {
  ReminderService([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  /// Set by the router so a notification tap can navigate.
  ReminderTapHandler? onTap;

  /// A tap that arrived before the router was ready.
  String? pendingPayload;

  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation(await FlutterTimezone.getLocalTimezone()));
    } catch (_) {
      // A device time zone the database does not know: fall back to UTC rather
      // than failing startup. Reminders still fire, just computed in UTC.
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: _handleResponse,
    );

    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      pendingPayload = launch?.notificationResponse?.payload;
    }
    _ready = true;
  }

  void _handleResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;
    final handler = onTap;
    if (handler == null) {
      pendingPayload = payload;
    } else {
      handler(payload);
    }
  }

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  /// POST_NOTIFICATIONS on Android 13+. Denying it never blocks setup.
  Future<bool> requestNotificationPermission() async =>
      await _android?.requestNotificationsPermission() ?? true;

  Future<bool> notificationsAllowed() async =>
      await _android?.areNotificationsEnabled() ?? true;

  /// SCHEDULE_EXACT_ALARM, which Android 12+ denies by default.
  Future<bool> canScheduleExact() async =>
      await _android?.canScheduleExactNotifications() ?? true;

  Future<void> requestExactAlarmPermission() async =>
      _android?.requestExactAlarmsPermission();

  /// Replaces the whole pending schedule.
  ///
  /// Cancelling first keeps the pending count bounded even when reminders are
  /// re-planned often, and avoids stale occurrences after a settings change.
  Future<void> replaceSchedule(List<ScheduledNotification> notifications) async {
    if (!_ready) return;
    await _plugin.cancelAll();
    final exact = await canScheduleExact();
    for (final n in notifications) {
      await _schedule(n, exact: exact);
    }
  }

  Future<void> _schedule(ScheduledNotification n, {required bool exact}) async {
    final when = tz.TZDateTime.from(n.at, tz.local);
    if (!when.isAfter(tz.TZDateTime.now(tz.local))) return;
    try {
      await _plugin.zonedSchedule(
        n.id,
        n.title,
        n.body,
        when,
        NotificationDetails(
          android: AndroidNotificationDetails(
            n.channel.id,
            n.channelName,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            category: AndroidNotificationCategory.reminder,
          ),
        ),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: exact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        payload: n.payload,
      );
    } on Exception catch (e) {
      debugPrint('Hazri: could not schedule reminder ${n.id}: $e');
    }
  }

  /// Posts one notification at one instant, outside the rolling schedule.
  ///
  /// The simran end bell. It is not part of the plan `replaceSchedule`
  /// writes, so a re-plan while a sitting is open -- a completion logged, a
  /// city changed -- drops it with everything else; the sitting's own ticker
  /// still ends the sitting, so what is lost is the bell in the one case the
  /// process was frozen as well. Rare enough to accept and say here.
  Future<void> scheduleOnce(ScheduledNotification n) async {
    if (!_ready) return;
    await _schedule(n, exact: await canScheduleExact());
  }

  Future<void> cancel(int id) async {
    if (!_ready) return;
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  Future<int> pendingCount() async => (await _plugin.pendingNotificationRequests()).length;
}
