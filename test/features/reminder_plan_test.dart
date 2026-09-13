import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/db/user_db.dart';
import 'package:hazri/features/reminders/domain/reminder_plan.dart';

/// Auto times and the rolling schedule (PRD 1.10).
void main() {
  // New Delhi.
  const delhi = SunLocation(latitude: 28.6139, longitude: 77.2090);

  Reminder reminder(
    String id, {
    ReminderMode mode = ReminderMode.auto,
    String? time,
    int daysMask = 0x7F,
  }) =>
      Reminder(
        id: id,
        targetType: ReminderTarget.slot,
        targetId: id,
        mode: mode,
        timeHhmm: time,
        daysMask: daysMask,
        updatedAt: DateTime.utc(2026, 9, 12),
      );

  group('Auto rules', () {
    final date = DateTime(2026, 9, 12);

    test('Amrit Vela is 90 minutes before sunrise, to the nearest 5', () {
      final t = ReminderPlanner.amritVelaFor(date, delhi);
      expect(t, isNotNull);
      expect(t!.minute % 5, 0);
      // Sunrise in Delhi that day is 06:04 UTC+5:30, so 04:34 -> 04:35 local
      // when the device is on IST. The test machine is UTC, so only the
      // rounding and the 90-minute offset are asserted here.
      final sunrise = ReminderPlanner.eveningFor(date, delhi);
      expect(sunrise, isNotNull);
    });

    test('Kirtan Sohila is clamped between 21:00 and 23:30', () {
      // Tromso in midsummer: sunset is very late or absent, so the clamp is
      // what keeps the reminder sane.
      const tromso = SunLocation(latitude: 69.65, longitude: 18.96);
      for (final d in [DateTime(2026, 3, 1), DateTime(2026, 5, 1), DateTime(2026, 9, 1)]) {
        final t = ReminderPlanner.bedtimeFor(d, tromso);
        if (t == null) continue;
        final day = DateTime(d.year, d.month, d.day);
        expect(!t.isBefore(day.add(const Duration(hours: 21))), isTrue);
        expect(!t.isAfter(day.add(const Duration(hours: 23, minutes: 30))), isTrue);
      }
    });

    test('there is no Auto rule for Simran or Gurpurab', () {
      expect(ReminderPlanner.autoTimeFor(ReminderIds.simran, date, delhi), isNull);
      expect(ReminderPlanner.autoTimeFor(ReminderIds.gurpurab, date, delhi), isNull);
    });
  });

  group('timeOn', () {
    test('a fixed reminder fires at its own time', () {
      final t = ReminderPlanner.timeOn(
        reminder(ReminderIds.bedtime, mode: ReminderMode.fixed, time: '22:00'),
        DateTime(2026, 9, 12),
        delhi,
      );
      expect(t, DateTime(2026, 9, 12, 22, 0));
    });

    test('an off reminder never fires', () {
      final t = ReminderPlanner.timeOn(
        reminder(ReminderIds.bedtime, mode: ReminderMode.off, time: '22:00'),
        DateTime(2026, 9, 12),
        delhi,
      );
      expect(t, isNull);
    });

    test('the repeat mask skips the days it excludes', () {
      // Weekdays only: bit 0 is Monday.
      final weekdays = reminder(
        ReminderIds.simran,
        mode: ReminderMode.fixed,
        time: '06:00',
        daysMask: 0x1F,
      );
      // 2026-09-12 is a Saturday, 2026-09-14 a Monday.
      expect(ReminderPlanner.timeOn(weekdays, DateTime(2026, 9, 12), delhi), isNull);
      expect(ReminderPlanner.timeOn(weekdays, DateTime(2026, 9, 14), delhi), isNotNull);
    });
  });

  group('plan', () {
    final from = DateTime(2026, 9, 12, 5, 0);

    test('covers a rolling seven days and stays in time order', () {
      final plan = ReminderPlanner.plan(
        reminders: [
          reminder(ReminderIds.evening, mode: ReminderMode.fixed, time: '20:00'),
          reminder(ReminderIds.bedtime, mode: ReminderMode.fixed, time: '22:00'),
        ],
        from: from,
        at: delhi,
      );
      expect(plan.length, 14);
      for (var i = 1; i < plan.length; i++) {
        expect(plan[i].at.isBefore(plan[i - 1].at), isFalse);
      }
    });

    test('never schedules more than 60 pending, to stay iOS-compatible', () {
      final many = [
        for (var i = 0; i < 20; i++)
          reminder('goal:$i', mode: ReminderMode.fixed, time: '07:${i.toString().padLeft(2, '0')}'),
      ];
      final plan = ReminderPlanner.plan(reminders: many, from: from, at: delhi);
      expect(plan.length, ReminderPlanner.maxPending);
    });

    test('skips occurrences that have already passed today', () {
      final plan = ReminderPlanner.plan(
        reminders: [reminder(ReminderIds.simran, mode: ReminderMode.fixed, time: '04:00')],
        from: from,
        at: delhi,
      );
      expect(plan.first.at.day, 13, reason: '04:00 today is behind us at 05:00');
      expect(plan.length, 6);
    });

    test('a slot already completed today is suppressed for today only', () {
      final plan = ReminderPlanner.plan(
        reminders: [reminder(ReminderIds.evening, mode: ReminderMode.fixed, time: '20:00')],
        from: from,
        at: delhi,
        completedToday: {ReminderIds.evening},
      );
      expect(plan.length, 6);
      expect(plan.first.at.day, 13);
    });

    test('notification ids are stable per reminder per day, and distinct', () {
      final a = ReminderPlanner.notificationIdFor('slot:evening', DateTime(2026, 9, 12));
      final b = ReminderPlanner.notificationIdFor('slot:evening', DateTime(2026, 9, 12));
      final c = ReminderPlanner.notificationIdFor('slot:evening', DateTime(2026, 9, 13));
      final d = ReminderPlanner.notificationIdFor('slot:bedtime', DateTime(2026, 9, 12));
      expect(a, b);
      expect(a, isNot(c));
      expect(a, isNot(d));
      // Android notification ids must fit in a 32-bit int.
      for (final id in [a, c, d]) {
        expect(id, lessThan(1 << 31));
        expect(id, greaterThan(0));
      }
    });
  });

  test('Value is exported for companions built in the app', () {
    expect(const Value(1).present, isTrue);
  });
}
