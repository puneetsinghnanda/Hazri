import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/features/reminders/data/reminder_service.dart';
import 'package:hazri/features/reminders/domain/reminder_plan.dart';

/// ARCHITECTURE §4.1: every notification is posted on a high-importance
/// channel, so it shows as a pop-up and not only in the shade.
///
/// Driven through the real [ReminderService] and the plugin's own Android
/// implementation, down to the method channel, because the bug lived in what
/// reached Android: the reader heard the sound and saw nothing (2026-10-09).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  late List<MethodCall> calls;
  late List<Map<String, Object?>> pending;

  setUp(() {
    calls = [];
    pending = [];
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return switch (call.method) {
        'initialize' => true,
        'canScheduleExactNotifications' => false,
        'getNotificationAppLaunchDetails' => <String, Object?>{'notificationLaunchedApp': false},
        'pendingNotificationRequests' => pending,
        _ => null,
      };
    });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  // Android's NotificationManager.IMPORTANCE_HIGH.
  const high = 4;

  Map<Object?, Object?> args(MethodCall c) => c.arguments as Map<Object?, Object?>;

  final plan = [
    for (final k in NotificationKind.values)
      PlannedNotification(
        reminderId: k.channelId,
        kind: k,
        at: DateTime.now().add(const Duration(hours: 2)),
        title: 'Title ${k.channelId}',
        body: 'Body',
        route: '/today',
      ),
  ];
  final names = {for (final k in NotificationKind.values) k: k.channelId};

  test('the default-importance channels are deleted, the new ones created high', () async {
    final service = ReminderService();
    await service.init();
    await service.replaceSchedule(plan, channelNames: names);

    final deleted = [
      for (final c in calls)
        if (c.method == 'deleteNotificationChannel') c.arguments,
    ];
    for (final k in NotificationKind.values) {
      expect(deleted, contains(k.channelId), reason: 'Android never raises an existing channel');
    }

    final created = {
      for (final c in calls)
        if (c.method == 'createNotificationChannel') args(c)['id']: args(c)['importance'],
    };
    expect(created.keys, unorderedEquals([for (final k in NotificationKind.values) k.androidChannelId]));
    expect(created.values, everyElement(high));
    for (final k in NotificationKind.values) {
      expect(deleted, isNot(contains(k.androidChannelId)));
    }
  });

  test('every scheduled reminder and the test notification are posted high', () async {
    final service = ReminderService();
    await service.init();
    await service.replaceSchedule(plan, channelNames: names);
    await service.sendTest(plan.first, 'Amrit Vela');

    final posted = [
      for (final c in calls)
        if (c.method == 'zonedSchedule' || c.method == 'show')
          args(c)['platformSpecifics']! as Map<Object?, Object?>,
    ];
    expect(posted, hasLength(NotificationKind.values.length + 1));
    for (final p in posted) {
      expect(p['channelId'], endsWith('_v2'));
      expect(p['importance'], high);
    }
  });

  test('a Sangat push shown in the foreground goes on the new Sangat channel', () async {
    final service = ReminderService();
    await service.init();
    await service.showPush(title: 'Sangat', body: 'Body', channelName: 'Sangat');
    final shown = calls.singleWhere((c) => c.method == 'show');
    final p = args(shown)['platformSpecifics']! as Map<Object?, Object?>;
    expect(p['channelId'], NotificationKind.sangat.androidChannelId);
    expect(p['importance'], high);
  });

  test('a re-plan leaves the test, a snooze and what is showing alone', () async {
    final service = ReminderService();
    await service.init();
    await service.sendTest(plan.first, 'Amrit Vela');
    await service.sendTest(plan.first, 'Amrit Vela', after: const Duration(minutes: 2));

    final stale = ReminderPlanner.notificationIdFor('goal-item:9', DateTime.now().add(const Duration(days: 1)));
    final kept = plan.first.notificationId;
    final snoozed = stale ^ ReminderPlanner.snoozeBit;
    Map<String, Object?> req(int id) => {'id': id, 'title': 't', 'body': 'b', 'payload': ''};
    pending = [req(ReminderPlanner.diagnosticId), req(snoozed), req(stale), req(kept)];
    calls.clear();

    await service.replaceSchedule(plan, channelNames: names);

    expect(calls.map((c) => c.method), isNot(contains('cancelAll')),
        reason: 'cancelAll took "Send one now" off the screen half a second after it showed');
    final cancelled = [
      for (final c in calls)
        if (c.method == 'cancel') args(c)['id'],
    ];
    expect(cancelled, [stale], reason: 'only a planned id that is no longer planned');
  });

  test('a met goal item\'s reminder showing today is taken away (GR2)', () async {
    final service = ReminderService();
    await service.init();
    calls.clear();
    await service.replaceSchedule(plan, channelNames: names, dismiss: {123, 123 ^ ReminderPlanner.snoozeBit});
    final cancelled = [
      for (final c in calls)
        if (c.method == 'cancel') args(c)['id'],
    ];
    expect(cancelled, unorderedEquals([123, 123 ^ ReminderPlanner.snoozeBit]));
  });

  test('every planned id is below the test and snooze ids', () {
    expect(ReminderPlanner.isPlannedId(ReminderPlanner.notificationIdFor('zzzzzzzzzzzz', DateTime(2026, 12, 31))),
        isTrue);
    expect(ReminderPlanner.isPlannedId(ReminderPlanner.diagnosticId), isFalse);
    expect(ReminderPlanner.isPlannedId(1 ^ ReminderPlanner.snoozeBit), isFalse);
  });
}
