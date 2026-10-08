import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/db/user_db.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';
import 'package:hazri/features/reminders/domain/reminder_plan.dart';

/// 02-notifications §8: the planner is pure, so each scenario is one call.
void main() {
  late L l;
  setUpAll(() async => l = await L.delegate.load(const Locale('en')));

  // 4 Oct 2026 is a Sunday.
  final sat = DateTime(2026, 10, 3, 22);
  final utc = DateTime.utc(2026, 10, 1);

  GoalItem bani(String id, String baniId, {int times = 1, String? at, String start = '2026-10-01'}) => GoalItem(
        id: id,
        goalId: 'g',
        seriesId: id,
        itemType: ItemType.bani,
        baniId: baniId,
        timesPerDay: times,
        durationType: DurationType.everyDay,
        startDate: start,
        reminderTime: at,
        createdAt: utc,
        updatedAt: utc,
      );

  Completion done(String baniId, DateTime at) => Completion(
        id: '$baniId$at',
        localDate: '${at.year}-${at.month.toString().padLeft(2, '0')}-${at.day.toString().padLeft(2, '0')}',
        baniId: baniId,
        slot: BaniSlotValue.morning,
        source: CompletionSource.reader,
        completedAt: at,
        updatedAt: at,
      );

  List<PlannedNotification> plan({
    DateTime? now,
    List<GoalItem> items = const [],
    List<Completion> completions = const [],
    List<PlannerEvent> events = const [],
    Set<NotificationKind>? enabled,
    int? streak,
    DateTime? quietUntil,
  }) =>
      ReminderPlanner.plan(
        l,
        PlannerInput(
          now: now ?? sat,
          enabled: enabled ?? NotificationKind.values.toSet(),
          items: items,
          todayCompletions: completions,
          todaySittings: const [],
          banis: const {'JAPJ': 'Japji Sahib', 'REHR': 'Rehras Sahib', 'SOHL': 'Kirtan Sohila'},
          events: events,
          streakThroughToday: streak,
          quietUntil: quietUntil,
        ),
      );

  Iterable<PlannedNotification> ofKind(List<PlannedNotification> p, NotificationKind k) =>
      p.where((n) => n.kind == k);

  test('T-1: Amrit Vela at 04:00 every day, Sunday\'s message on Sunday', () {
    final av = ofKind(plan(), NotificationKind.amritVela).toList();
    // Today's (Saturday's) 04:00 has passed; the window is today and six more.
    expect(av, hasLength(6));
    expect(av.every((n) => n.at.hour == 4 && n.at.minute == 0), isTrue);
    expect(av.first.at, DateTime(2026, 10, 4, 4));
    expect(av.first.title, l.notifAv1Title);
  });

  test('T-2: Monday with no profile falls back to Sunday\'s message (CM1)', () {
    final monday = ofKind(plan(now: DateTime(2026, 10, 4, 22)), NotificationKind.amritVela).first;
    expect(monday.at, DateTime(2026, 10, 5, 4));
    expect(monday.title, l.notifAv1Title);
  });

  test('T-3 / T-4: Wednesday names the streak only when it is known within 24 h (CM3, CM4)', () {
    final tue = DateTime(2026, 10, 6, 21);
    final known = ofKind(plan(now: tue, streak: 12), NotificationKind.amritVela).first;
    expect(known.title, l.notifAv4Title(12));
    final unknown = ofKind(plan(now: tue), NotificationKind.amritVela).first;
    expect(unknown.title, l.notifAv1Title);
    // A week ahead the same Wednesday falls back, because the number would be stale.
    final weekAhead = ofKind(plan(now: DateTime(2026, 10, 1, 21), streak: 12), NotificationKind.amritVela)
        .firstWhere((n) => n.at.day == 7);
    expect(weekAhead.title, l.notifAv1Title);
  });

  test('T-5: a goal already met today sends nothing today (GR2, RM3)', () {
    final now = DateTime(2026, 10, 4, 6, 20);
    final p = plan(
      now: now,
      items: [bani('a', 'JAPJ', at: '06:40')],
      completions: [done('JAPJ', DateTime(2026, 10, 4, 6, 10))],
    );
    final goals = ofKind(p, NotificationKind.goalBani);
    expect(goals.where((n) => n.at.day == 4), isEmpty);
    expect(goals.where((n) => n.at.day == 5), hasLength(1));
  });

  test('T-6: Japji ×3, one paath: "1 of 3", a snooze, and progress', () {
    final now = DateTime(2026, 10, 4, 6, 20);
    final n = ofKind(
      plan(now: now, items: [bani('a', 'JAPJ', times: 3, at: '06:40')], completions: [done('JAPJ', DateTime(2026, 10, 4, 6))]),
      NotificationKind.goalBani,
    ).first;
    expect(n.at, DateTime(2026, 10, 4, 6, 40));
    expect(n.title, l.notifGoalBaniTitle('Japji Sahib'));
    expect(n.body, l.notifGoalBaniOpenBody(1, 3));
    expect(n.actions.map((a) => a.id), contains('snooze'));
    expect(n.progress, (0, 1));
  });

  test('T-8: three items at three times are three notifications a day', () {
    final p = plan(items: [
      bani('a', 'JAPJ', at: '05:00'),
      bani('b', 'REHR', at: '18:30'),
      bani('c', 'SOHL', at: '21:30'),
    ]);
    expect(ofKind(p, NotificationKind.goalBani).where((n) => n.at.day == 4), hasLength(3));
  });

  test('RM1: an item with no reminder time sends nothing', () {
    expect(ofKind(plan(items: [bani('a', 'JAPJ')]), NotificationKind.goalBani), isEmpty);
  });

  test('T-9, T-10, T-11: Gurpurabs at 06:00, other events at 07:00, on the day', () {
    final p = plan(events: const [
      PlannerEvent(id: 'p1', date: '2026-10-05', kind: 'prakash', name: 'Prakash A', remind: true),
      PlannerEvent(id: 'p2', date: '2026-10-05', kind: 'gurgaddi', name: 'Gurgaddi B', remind: true),
      PlannerEvent(id: 's1', date: '2026-10-06', kind: 'shaheedi', name: 'Shaheedi C', remind: true),
      PlannerEvent(id: 'x', date: '2026-10-06', kind: 'prakash', name: 'Off', remind: false),
    ]);
    final cal = ofKind(p, NotificationKind.calendar).toList();
    expect(cal, hasLength(3));
    expect(cal.where((n) => n.at == DateTime(2026, 10, 5, 6)), hasLength(2));
    final shaheedi = cal.singleWhere((n) => n.reminderId == 'event:s1');
    expect(shaheedi.at, DateTime(2026, 10, 6, 7));
    expect(shaheedi.title, l.notifRememberTitle('Shaheedi C'));
  });

  test('T-14, T-15, T-16: the hazri nudge only with no goal and no hazri', () {
    final morning = DateTime(2026, 10, 4, 5);
    expect(ofKind(plan(now: morning), NotificationKind.hazriNudge).first.at, DateTime(2026, 10, 4, 7));
    final afterJapji = plan(now: morning, completions: [done('JAPJ', DateTime(2026, 10, 4, 5, 30))]);
    expect(ofKind(afterJapji, NotificationKind.hazriNudge).where((n) => n.at.day == 4), isEmpty);
    expect(ofKind(plan(now: morning, items: [bani('a', 'JAPJ')]), NotificationKind.hazriNudge), isEmpty);
  });

  test('T-17: anything due during a sitting is moved to its end (CM5)', () {
    final now = DateTime(2026, 10, 4, 6, 55);
    final p = plan(now: now, quietUntil: DateTime(2026, 10, 4, 7, 10));
    expect(ofKind(p, NotificationKind.hazriNudge).first.at, DateTime(2026, 10, 4, 7, 10));
  });

  test('CM7: a kind switched off plans nothing', () {
    final p = plan(enabled: {NotificationKind.calendar});
    expect(ofKind(p, NotificationKind.amritVela), isEmpty);
    expect(ofKind(p, NotificationKind.hazriNudge), isEmpty);
  });

  test('CM2: never more than 60 pending, nearest first, nothing in the past', () {
    final items = [for (var i = 0; i < 12; i++) bani('i$i', 'JAPJ$i', at: '${(5 + i).toString().padLeft(2, '0')}:00')];
    final p = plan(items: items);
    expect(p.length, lessThanOrEqualTo(ReminderPlanner.maxPending));
    for (var i = 1; i < p.length; i++) {
      expect(p[i].at.isBefore(p[i - 1].at), isFalse);
    }
    expect(p.every((n) => n.at.isAfter(sat)), isTrue);
  });

  test('notification ids are stable and distinct across a week', () {
    final p = plan(items: [bani('a', 'JAPJ', at: '06:00'), bani('b', 'REHR', at: '18:00')]);
    final ids = p.map((n) => n.notificationId).toList();
    expect(ids.toSet(), hasLength(ids.length));
    expect(plan(items: [bani('a', 'JAPJ', at: '06:00'), bani('b', 'REHR', at: '18:00')]).map((n) => n.notificationId),
        ids);
  });

  for (final code in ['pa', 'hi']) {
    test('Friday\'s weekday name in $code does not throw', () async {
      final lx = await L.delegate.load(Locale(code));
      final p = ReminderPlanner.plan(
        lx,
        PlannerInput(
          now: DateTime(2026, 10, 8, 22),
          enabled: {NotificationKind.amritVela},
          items: const [],
          todayCompletions: const [],
          todaySittings: const [],
          banis: const {},
        ),
      );
      expect(p.first.at, DateTime(2026, 10, 9, 4));
      expect(p.first.title, isNotEmpty);
    });
  }
}
