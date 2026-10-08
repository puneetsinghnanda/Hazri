import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../domain/reminder_plan.dart';

/// Set during bootstrap in `main.dart`.
final reminderServiceProvider = Provider<ReminderService>(
  (ref) => throw UnimplementedError('ReminderService must be overridden at startup'),
);

/// What a notification asks the app to open when tapped.
typedef ReminderTapHandler = void Function(String route);

/// The channels of Hazri before 2026-10-07, deleted on upgrade so system
/// settings shows only the five of 02-notifications §6.1.
const _oldChannels = ['nitnem_reminders', 'daily_simran', 'gurpurab', 'paath_goals'];

/// What travels with a notification so a tap, an action or a snooze can act
/// on it without the planner: the route, and for a snooze the text to re-send.
@immutable
class NotificationPayload {
  const NotificationPayload({
    required this.route,
    this.title,
    this.body,
    this.channel,
    this.channelName,
    this.actions = const [],
  });

  final String route;
  final String? title;
  final String? body;
  final String? channel;
  final String? channelName;

  /// Action id → route, for the buttons that open something.
  final List<({String id, String label, String? route})> actions;

  String encode() => jsonEncode({
        'route': route,
        'title': ?title,
        'body': ?body,
        'channel': ?channel,
        'channelName': ?channelName,
        'actions': [
          for (final a in actions) {'id': a.id, 'label': a.label, 'route': ?a.route},
        ],
      });

  /// Accepts a bare route too: notifications planned by an older build.
  static NotificationPayload decode(String raw) {
    if (!raw.startsWith('{')) return NotificationPayload(route: raw);
    final m = jsonDecode(raw) as Map<String, Object?>;
    return NotificationPayload(
      route: (m['route'] as String?) ?? '/today',
      title: m['title'] as String?,
      body: m['body'] as String?,
      channel: m['channel'] as String?,
      channelName: m['channelName'] as String?,
      actions: [
        for (final a in (m['actions'] as List<Object?>? ?? const []))
          if (a is Map<String, Object?>)
            (id: a['id']! as String, label: a['label']! as String, route: a['route'] as String?),
      ],
    );
  }

  /// The route an action opens: its own, or the notification's for a tap.
  String? routeFor(String? actionId) {
    if (actionId == null || actionId.isEmpty) return route;
    return actions.where((a) => a.id == actionId).firstOrNull?.route;
  }
}

/// The snooze, run by Android with the app not open (02-notifications §6.3):
/// one copy in 15 minutes, with no actions but "Open", so a second snooze is
/// never offered (GR3).
@pragma('vm:entry-point')
Future<void> onNotificationActionInBackground(NotificationResponse response) async {
  if (response.actionId != 'snooze' || response.payload == null) return;
  final p = NotificationPayload.decode(response.payload!);
  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(
    const InitializationSettings(android: AndroidInitializationSettings('@drawable/ic_notification')),
  );
  tzdata.initializeTimeZones();
  try {
    tz.setLocalLocation(tz.getLocation(await FlutterTimezone.getLocalTimezone()));
  } on Exception {
    tz.setLocalLocation(tz.getLocation('UTC'));
  }
  final open = p.actions.where((a) => a.id == 'open').toList();
  final copy = NotificationPayload(
    route: p.route,
    title: p.title,
    body: p.body,
    channel: p.channel,
    channelName: p.channelName,
    actions: open,
  );
  await plugin.zonedSchedule(
    (response.id ?? 0) ^ 0x40000000,
    p.title,
    p.body,
    tz.TZDateTime.now(tz.local).add(const Duration(minutes: 15)),
    NotificationDetails(
      android: AndroidNotificationDetails(
        p.channel ?? NotificationKind.goalBani.channelId,
        p.channelName ?? 'Hazri',
        category: AndroidNotificationCategory.reminder,
        actions: [
          for (final a in open)
            AndroidNotificationAction(a.id, a.label, showsUserInterface: true, cancelNotification: true),
        ],
      ),
    ),
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    payload: copy.encode(),
  );
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

  /// What was last scheduled, for the diagnostics screen (DP4).
  List<PlannedNotification> lastPlan = const [];

  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation(await FlutterTimezone.getLocalTimezone()));
    } catch (_) {
      // A device time zone the database does not know: fall back to UTC rather
      // than failing startup.
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: _handleResponse,
      onDidReceiveBackgroundNotificationResponse: onNotificationActionInBackground,
    );

    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      final r = launch?.notificationResponse;
      if (r?.payload != null) {
        pendingPayload = NotificationPayload.decode(r!.payload!).routeFor(r.actionId);
      }
    }
    for (final id in _oldChannels) {
      await _android?.deleteNotificationChannel(id);
    }
    _ready = true;
  }

  void _handleResponse(NotificationResponse response) {
    final raw = response.payload;
    if (raw == null) return;
    if (response.actionId == 'snooze') {
      onNotificationActionInBackground(response);
      return;
    }
    final route = NotificationPayload.decode(raw).routeFor(response.actionId);
    if (route == null) return; // "Later" dismisses only.
    final handler = onTap;
    if (handler == null) {
      pendingPayload = route;
    } else {
      handler(route);
    }
  }

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  /// POST_NOTIFICATIONS on Android 13+.
  Future<bool> requestNotificationPermission() async =>
      await _android?.requestNotificationsPermission() ?? true;

  Future<bool> notificationsAllowed() async =>
      await _android?.areNotificationsEnabled() ?? true;

  /// SCHEDULE_EXACT_ALARM, which Android 12+ denies by default. Never asked
  /// for (DP2); read for the note and the diagnostics.
  Future<bool> canScheduleExact() async =>
      await _android?.canScheduleExactNotifications() ?? true;

  /// Replaces the whole pending schedule with [planned].
  Future<void> replaceSchedule(
    List<PlannedNotification> planned, {
    required Map<NotificationKind, String> channelNames,
  }) async {
    if (!_ready) return;
    await _plugin.cancelAll();
    final exact = await canScheduleExact();
    for (final n in planned) {
      await _schedule(n, channelNames[n.kind] ?? 'Hazri', exact: exact);
    }
    lastPlan = planned;
  }

  NotificationDetails _details(PlannedNotification n, String channelName) {
    final progress = n.progress;
    return NotificationDetails(
      android: AndroidNotificationDetails(
        n.kind.channelId,
        channelName,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        category: AndroidNotificationCategory.reminder,
        styleInformation: BigTextStyleInformation(n.body),
        showProgress: progress != null && progress.$2 > 0,
        maxProgress: progress?.$2 ?? 0,
        progress: progress?.$1 ?? 0,
        actions: [
          for (final a in n.actions)
            AndroidNotificationAction(
              a.id,
              a.label,
              showsUserInterface: a.route != null,
              cancelNotification: true,
            ),
        ],
      ),
    );
  }

  String _payload(PlannedNotification n, String channelName) => NotificationPayload(
        route: n.route,
        title: n.title,
        body: n.body,
        channel: n.kind.channelId,
        channelName: channelName,
        actions: [for (final a in n.actions) (id: a.id, label: a.label, route: a.route)],
      ).encode();

  Future<void> _schedule(PlannedNotification n, String channelName, {required bool exact}) async {
    final when = tz.TZDateTime.from(n.at, tz.local);
    if (!when.isAfter(tz.TZDateTime.now(tz.local))) return;
    try {
      await _plugin.zonedSchedule(
        n.notificationId,
        n.title,
        n.body,
        when,
        _details(n, channelName),
        androidScheduleMode:
            exact ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: _payload(n, channelName),
      );
    } on Exception catch (e) {
      debugPrint('Hazri: could not schedule ${n.reminderId}: $e');
    }
  }

  /// Diagnostics: shows [n] now, or in two minutes (DP4).
  Future<void> sendTest(PlannedNotification n, String channelName, {Duration? after}) async {
    if (!_ready) return;
    if (after == null) {
      await _plugin.show(n.notificationId, n.title, n.body, _details(n, channelName),
          payload: _payload(n, channelName));
    } else {
      final at = tz.TZDateTime.now(tz.local).add(after);
      await _plugin.zonedSchedule(n.notificationId, n.title, n.body, at, _details(n, channelName),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          payload: _payload(n, channelName));
    }
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  Future<int> pendingCount() async => (await _plugin.pendingNotificationRequests()).length;

  /// The most recent Hazri notification still showing, for "last delivered".
  Future<String?> lastShownTitle() async {
    final active = await _android?.getActiveNotifications();
    return active?.lastOrNull?.title;
  }
}
