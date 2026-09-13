import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/time/clock.dart';
import 'package:hazri/features/diary/domain/streak.dart';

/// The gentle streak and its grace days (PRD 1.9).
void main() {
  Set<String> daysBack(DateTime from, int count, {Set<int> skip = const {}}) => {
    for (var i = 0; i < count; i++)
      if (!skip.contains(i)) localDateKey(from.subtract(Duration(days: i))),
  };

  final today = DateTime(2026, 9, 12);

  test('no Nitnem days means no streak, and nothing is scolded', () {
    final r = StreakCalculator.compute(
      nitnemDays: const {},
      existingGraceDays: const {},
      today: today,
    );
    expect(r.days, 0);
    expect(r.graceUsed, isEmpty);
    expect(r.graceLeftThisMonth, StreakCalculator.gracePerMonth);
  });

  test('an unbroken run ending today counts every day', () {
    final r = StreakCalculator.compute(
      nitnemDays: daysBack(today, 11),
      existingGraceDays: const {},
      today: today,
    );
    expect(r.days, 11);
    expect(r.graceUsed, isEmpty);
  });

  test('a run ending yesterday still stands: today is not over', () {
    final r = StreakCalculator.compute(
      nitnemDays: daysBack(today.subtract(const Duration(days: 1)), 5),
      existingGraceDays: const {},
      today: today,
    );
    expect(r.days, 5);
  });

  test('a run that ended two days ago is broken', () {
    final r = StreakCalculator.compute(
      nitnemDays: daysBack(today.subtract(const Duration(days: 2)), 5),
      existingGraceDays: const {},
      today: today,
    );
    expect(r.days, 0);
  });

  test('one missed day is bridged by a grace day, which is reported back', () {
    // Days 0..10 kept, except day 3.
    final r = StreakCalculator.compute(
      nitnemDays: daysBack(today, 11, skip: {3}),
      existingGraceDays: const {},
      today: today,
    );
    expect(r.days, 10, reason: 'grace bridges the gap but does not add a day');
    expect(r.graceUsed.length, 1);
    expect(localDateKey(r.graceUsed.single), localDateKey(DateTime(2026, 9, 9)));
    expect(r.graceLeftThisMonth, 1);
  });

  test('a month gives two grace days and no more', () {
    final r = StreakCalculator.compute(
      nitnemDays: daysBack(today, 11, skip: {3, 5, 7}),
      existingGraceDays: const {},
      today: today,
    );
    // Days 0,1,2 then a forgiven gap, day 4, another forgiven gap, day 6 --
    // the third gap has no grace left and breaks the run.
    expect(r.graceUsed.length, 2);
    expect(r.days, 5);
    expect(r.graceLeftThisMonth, 0);
  });

  test('grace already granted is not granted twice', () {
    final already = {localDateKey(DateTime(2026, 9, 9))};
    final r = StreakCalculator.compute(
      nitnemDays: daysBack(today, 11, skip: {3}),
      existingGraceDays: already,
      today: today,
    );
    expect(r.graceUsed, isEmpty);
    expect(r.days, 10);
    expect(r.graceLeftThisMonth, 1);
  });

  test('grace budgets are per calendar month, so a run can cross a boundary', () {
    // Today is 2 October; the gap falls on 29 September, whose month still has
    // both of its grace days.
    final oct2 = DateTime(2026, 10, 2);
    final days = daysBack(oct2, 10, skip: {3});
    final r = StreakCalculator.compute(
      nitnemDays: days,
      existingGraceDays: const {},
      today: oct2,
    );
    expect(localDateKey(r.graceUsed.single), '2026-09-29');
    expect(
      r.graceLeftThisMonth,
      StreakCalculator.gracePerMonth,
      reason: 'the grace was spent from September, not October',
    );
    expect(r.days, 9);
  });

  test('a fresh install does not spend grace on the empty past', () {
    final r = StreakCalculator.compute(
      nitnemDays: {localDateKey(today)},
      existingGraceDays: const {},
      today: today,
    );
    expect(r.days, 1);
    expect(r.graceUsed, isEmpty);
  });

  test('a day already forgiven keeps the run anchored when today is empty', () {
    final r = StreakCalculator.compute(
      nitnemDays: daysBack(today.subtract(const Duration(days: 1)), 4),
      existingGraceDays: {localDateKey(today)},
      today: today,
    );
    expect(r.days, 4);
  });
}
