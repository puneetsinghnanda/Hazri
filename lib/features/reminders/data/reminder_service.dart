import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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

/// The channels of Hazri before 2026-10-07, and the five of ARCHITECTURE
/// §4.1 as first created at default importance (until 2026-10-09), deleted on
/// upgrade so system settings shows only the current five.
final _oldChannels = [
  'nitnem_reminders',
  'daily_simran',
  'gurpurab',
  'paath_goals',
  for (final k in NotificationKind.values) k.channelId,
];

/// Every Hazri notification shows as a pop-up, not only in the shade: a
/// reminder nobody sees is no reminder (ARCHITECTURE §4.1).
const _importance = Importance.high;
const _priority = Priority.high;

/// The current Android channel for one named in a payload: a snooze planned
/// by an older build names a channel that has since been deleted, and posting
/// to it would bring it back at its old importance.
String _currentChannel(String? id) =>
    NotificationKind.values
        .where((k) => k.channelId == id || k.androidChannelId == id)
        .firstOrNull
        ?.androidChannelId ??
    NotificationKind.goalBani.androidChannelId;

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
    (response.id ?? 0) ^ ReminderPlanner.snoozeBit,
    p.title,
    p.body,
    tz.TZDateTime.now(tz.local).add(const Duration(minutes: 15)),
    NotificationDetails(
      android: AndroidNotificationDetails(
        _currentChannel(p.channel),
        p.channelName ?? 'Hazri',
        importance: _importance,
        priority: _priority,
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
        // A plain white drawable: the launcher icon is adaptive, which is not
        // a valid status-bar icon on every Android version.
        android: AndroidInitializationSettings('@drawable/ic_notification'),
      ),
      onDidReceiveNotificationResponse: _handleResponse,
      onDidReceiveBackgroundNotificationResponse: onNotificationActionInBackground,
    );

    // DP7: Hazri's own reminders answer taps through its own channel.
    _native.setMethodCallHandler((call) async {
      if (call.method == 'tap') _handleNativeTap(call.arguments);
      return null;
    });
    try {
      _handleNativeTap(await _native.invokeMethod<Object?>('takeLaunchTap'));
    } on PlatformException catch (e) {
      debugPrint('Hazri: no launch tap ($e)');
    } on MissingPluginException {
      // Tests and non-Android.
    }

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

  /// A tap on one of Hazri's own reminders, or one of its buttons (DP7).
  void _handleNativeTap(Object? arguments) {
    if (arguments is! Map) return;
    final raw = arguments['payload'];
    if (raw is! String || raw.isEmpty) return;
    final action = arguments['action'];
    final route = NotificationPayload.decode(raw).routeFor(action is String ? action : null);
    if (route == null) return;
    final handler = onTap;
    if (handler == null) {
      pendingPayload = route;
    } else {
      handler(route);
    }
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

  /// Opens Android's "Alarms & reminders" for Hazri (DP2).
  Future<void> requestExactAlarms() async {
    await _android?.requestExactAlarmsPermission();
  }

  /// Replaces the planned part of the pending schedule with [planned], and
  /// takes away the notifications in [dismiss] if they are showing.
  ///
  /// Never `cancelAll`: that also takes every notification off the screen,
  /// and a re-plan follows every write. "Send one now" was shown and gone
  /// within half a second, the two-minute test and a snooze were deleted
  /// before they fired, and opening the app cleared a delivered Amrit Vela
  /// (2026-10-10).
  Future<void> replaceSchedule(
    List<PlannedNotification> planned, {
    required Map<NotificationKind, String> channelNames,
    Set<int> dismiss = const {},
  }) async {
    if (!_ready) return;
    // Every channel exists from the first plan, so a Sangat push Android
    // shows by itself lands on its own channel (the manifest names it), and
    // each switch in system settings is there before its first notification.
    for (final e in channelNames.entries) {
      await _android?.createNotificationChannel(
          AndroidNotificationChannel(e.key.androidChannelId, e.value, importance: _importance));
    }
    // DP7: whatever the plugin still holds from earlier builds is cancelled;
    // its scheduled path never showed a reminder on the owner's phone.
    for (final p in await _plugin.pendingNotificationRequests()) {
      await _plugin.cancel(p.id);
    }
    // A pending planned id that is not planned again is cancelled; one that
    // is planned again is replaced under the same id. Only pending ones:
    // today's that already fired stay where they are.
    final keep = {for (final n in planned) n.notificationId};
    for (final p in await _nativePending()) {
      if (ReminderPlanner.isPlannedId(p.id) && !keep.contains(p.id)) await _nativeCall('cancel', {'id': p.id});
    }
    for (final id in dismiss) {
      await _nativeCall('cancel', {'id': id});
      await _nativeCall('dismiss', {'id': id});
    }
    for (final n in planned) {
      await _schedule(n, channelNames[n.kind] ?? 'Hazri');
    }
    lastPlan = planned;
  }

  NotificationDetails _details(PlannedNotification n, String channelName) {
    final progress = n.progress;
    return NotificationDetails(
      android: AndroidNotificationDetails(
        n.kind.androidChannelId,
        channelName,
        importance: _importance,
        priority: _priority,
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
        channel: n.kind.androidChannelId,
        channelName: channelName,
        actions: [for (final a in n.actions) (id: a.id, label: a.label, route: a.route)],
      ).encode();

  /// Hazri's own scheduler (DP7): `android/.../Reminders.kt`.
  static const _native = MethodChannel('app.hazri/reminders');

  Future<void> _nativeCall(String method, Map<String, Object?> args) async {
    try {
      await _native.invokeMethod<void>(method, args);
    } on PlatformException catch (e) {
      debugPrint('Hazri: reminders.$method failed ($e)');
    } on MissingPluginException {
      // Tests and non-Android.
    }
  }

  Future<List<({int id, DateTime at})>> _nativePending() async {
    try {
      final list = await _native.invokeListMethod<Map<Object?, Object?>>('pending') ?? const [];
      return [
        for (final m in list)
          (id: m['id']! as int, at: DateTime.fromMillisecondsSinceEpoch(m['at']! as int)),
      ];
    } on PlatformException {
      return const [];
    } on MissingPluginException {
      return const [];
    }
  }

  /// What Hazri's scheduler stores for one reminder: everything the native
  /// side needs to post it with no help from Dart.
  Map<String, Object?> _nativeReminder(PlannedNotification n, String channelName, {int? id, DateTime? at}) {
    final progress = n.progress;
    return {
      'id': id ?? n.notificationId,
      'at': (at ?? n.at).millisecondsSinceEpoch,
      'title': n.title,
      'body': n.body,
      'channelId': n.kind.androidChannelId,
      'channelName': channelName,
      'payload': _payload(n, channelName),
      'progress': progress?.$1 ?? 0,
      'maxProgress': progress?.$2 ?? 0,
    };
  }

  Future<void> _schedule(PlannedNotification n, String channelName) async {
    if (!n.at.isAfter(DateTime.now())) return;
    await _nativeCall('schedule', _nativeReminder(n, channelName));
  }

  /// Diagnostics: shows [n] now, or in two minutes (DP4).
  Future<void> sendTest(PlannedNotification n, String channelName, {Duration? after}) async {
    if (!_ready) return;
    const id = ReminderPlanner.diagnosticId;
    if (after == null) {
      await _plugin.show(id, n.title, n.body, _details(n, channelName),
          payload: _payload(n, channelName));
    } else {
      // Through Hazri's own scheduler, as every reminder is (DP7).
      await _nativeCall('schedule', _nativeReminder(n, channelName, id: id, at: DateTime.now().add(after)));
    }
  }

  /// A Sangat push that arrived while the app was open: Android shows a
  /// notification message only in the background, so the app shows it here
  /// on the same channel (02-notifications §6.1).
  Future<void> showPush({required String title, required String body, String? route, required String channelName}) async {
    if (!_ready) return;
    await _plugin.show(
      title.hashCode ^ body.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(NotificationKind.sangat.androidChannelId, channelName,
            importance: _importance, priority: _priority, category: AndroidNotificationCategory.social),
      ),
      payload: NotificationPayload(route: route ?? '/sangat').encode(),
    );
  }

  Future<void> cancelAll() async {
    for (final p in await _nativePending()) {
      await _nativeCall('cancel', {'id': p.id});
    }
    await _plugin.cancelAll();
  }

  Future<int> pendingCount() async => (await _nativePending()).length;

  /// The most recent Hazri notification still showing, for "last delivered".
  Future<String?> lastShownTitle() async {
    final active = await _android?.getActiveNotifications();
    return active?.lastOrNull?.title;
  }
}
