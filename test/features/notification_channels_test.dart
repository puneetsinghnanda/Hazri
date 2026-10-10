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
  // DP7: Hazri's own scheduler, android/.../Reminders.kt.
  const native = MethodChannel('app.hazri/reminders');
  late List<MethodCall> nativeCalls;
  late List<Map<String, Object?>> nativePending;

  setUp(() {
    calls = [];
    pending = [];
    nativeCalls = [];
    nativePending = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(native, (call) async {
      nativeCalls.add(call);
      return switch (call.method) {
        'pending' => nativePending,
        _ => null,
      };
    });
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
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(native, null);
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

  test('DP7: every reminder goes to Hazri\'s own scheduler, none to the plugin\'s', () async {
    final service = ReminderService();
    await service.init();
    await service.replaceSchedule(plan, channelNames: names);

    expect(calls.map((c) => c.method), isNot(contains('zonedSchedule')),
        reason: 'the plugin\'s scheduled path never showed a reminder on the owner\'s phone');
    final scheduled = [
      for (final c in nativeCalls)
        if (c.method == 'schedule') args(c),
    ];
    expect(scheduled, hasLength(NotificationKind.values.length));
    for (final r in scheduled) {
      expect(r['channelId'], endsWith('_v2'));
      expect(r['at'], isA<int>());
      expect(r['payload'], isA<String>());
    }
    final first = scheduled.firstWhere((r) => r['id'] == plan.first.notificationId);
    expect(first['at'], plan.first.at.millisecondsSinceEpoch);
    expect(first['title'], plan.first.title);
  });

  test('DP7: what the plugin still holds from earlier builds is cancelled', () async {
    final service = ReminderService();
    await service.init();
    pending = [
      {'id': 7, 'title': 't', 'body': 'b', 'payload': ''},
    ];
    calls.clear();
    await service.replaceSchedule(plan, channelNames: names);
    expect([for (final c in calls) if (c.method == 'cancel') args(c)['id']], [7]);
  });

  test('DP7: a tap on one of Hazri\'s reminders opens its route', () async {
    final service = ReminderService();
    await service.init();
    final routes = <String>[];
    service.onTap = routes.add;
    final payload = NotificationPayload(
      route: '/reader/japji-sahib',
      actions: const [(id: 'nitnem', label: 'Start Nitnem', route: '/nitnem')],
    ).encode();
    Future<void> tap(String? action) => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(native.name,
            native.codec.encodeMethodCall(MethodCall('tap', {'payload': payload, 'action': action})), (_) {});
    await tap(null);
    await tap('nitnem');
    expect(routes, ['/reader/japji-sahib', '/nitnem']);
  });

  test('the test notification now is posted high on the new channel', () async {
    final service = ReminderService();
    await service.init();
    await service.sendTest(plan.first, 'Amrit Vela');
    final p = args(calls.singleWhere((c) => c.method == 'show'))['platformSpecifics']! as Map<Object?, Object?>;
    expect(p['channelId'], endsWith('_v2'));
    expect(p['importance'], high);
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
    expect(nativeCalls.where((c) => c.method == 'schedule').single.arguments,
        containsPair('id', ReminderPlanner.diagnosticId),
        reason: 'the two-minute test goes the way every reminder goes');

    final stale = ReminderPlanner.notificationIdFor('goal-item:9', DateTime.now().add(const Duration(days: 1)));
    final kept = plan.first.notificationId;
    final snoozed = stale ^ ReminderPlanner.snoozeBit;
    final later = DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch;
    Map<String, Object?> req(int id) => {'id': id, 'at': later, 'title': 't'};
    nativePending = [req(ReminderPlanner.diagnosticId), req(snoozed), req(stale), req(kept)];
    calls.clear();
    nativeCalls.clear();

    await service.replaceSchedule(plan, channelNames: names);

    expect(calls.map((c) => c.method), isNot(contains('cancelAll')),
        reason: 'cancelAll took "Send one now" off the screen half a second after it showed');
    final cancelled = [
      for (final c in nativeCalls)
        if (c.method == 'cancel') args(c)['id'],
    ];
    expect(cancelled, [stale], reason: 'only a planned id that is no longer planned');
  });

  test('a met goal item\'s reminder showing today is taken away (GR2)', () async {
    final service = ReminderService();
    await service.init();
    calls.clear();
    await service.replaceSchedule(plan, channelNames: names, dismiss: {123, 123 ^ ReminderPlanner.snoozeBit});
    final dismissed = [
      for (final c in nativeCalls)
        if (c.method == 'dismiss') args(c)['id'],
    ];
    expect(dismissed, unorderedEquals([123, 123 ^ ReminderPlanner.snoozeBit]));
  });

  test('every planned id is below the test and snooze ids', () {
    expect(ReminderPlanner.isPlannedId(ReminderPlanner.notificationIdFor('zzzzzzzzzzzz', DateTime(2026, 12, 31))),
        isTrue);
    expect(ReminderPlanner.isPlannedId(ReminderPlanner.diagnosticId), isFalse);
    expect(ReminderPlanner.isPlannedId(1 ^ ReminderPlanner.snoozeBit), isFalse);
  });
}
