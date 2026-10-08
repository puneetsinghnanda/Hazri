import 'package:flutter/foundation.dart';

import '../../../core/time/clock.dart';

/// The result of walking the diary backwards from today.
@immutable
class StreakResult {
  const StreakResult({
    required this.days,
    required this.graceUsed,
    required this.graceLeftThisMonth,
  });

  /// Consecutive Nitnem days, ending today or yesterday.
  final int days;

  /// Missed days the streak forgave, oldest first. These are persisted so the
  /// diary keeps showing the same GRACE cells tomorrow.
  final List<DateTime> graceUsed;

  /// How many grace days the current calendar month still has.
  final int graceLeftThisMonth;
}

/// The gentle streak and its grace days (PRD 1.9).
///
/// A Nitnem day is any day with at least one completed Nitnem bani. The streak
/// is the run of Nitnem days ending today or yesterday; a single missed day
/// inside the run is bridged by a grace day if that day's calendar month still
/// has one of its two left. Grace days bridge a gap but do not add to the
/// count, and nothing here ever produces a warning.
abstract final class StreakCalculator {
  static const int gracePerMonth = 2;

  /// How far back to walk. A streak longer than this is reported as this.
  static const int _maxLookbackDays = 3650;

  static StreakResult compute({
    required Set<String> nitnemDays,
    required Set<String> existingGraceDays,
    required DateTime today,
  }) {
    final todayKey = localDateKey(today);
    final yesterday = today.subtract(const Duration(days: 1));

    // Grace already granted still counts against its month's budget.
    final used = <String, int>{};
    for (final key in existingGraceDays) {
      final m = key.substring(0, 7);
      used[m] = (used[m] ?? 0) + 1;
    }

    final thisMonth = monthKey(today);
    int graceLeft() => (gracePerMonth - (used[thisMonth] ?? 0)).clamp(0, gracePerMonth);

    // The streak may end today or yesterday; anything older is broken. Today
    // is never forgiven on the fly -- the day is not over yet.
    final DateTime cursor0;
    if (nitnemDays.contains(todayKey) || existingGraceDays.contains(todayKey)) {
      cursor0 = today;
    } else if (nitnemDays.contains(localDateKey(yesterday))) {
      cursor0 = yesterday;
    } else {
      return StreakResult(days: 0, graceUsed: const [], graceLeftThisMonth: graceLeft());
    }
    var cursor = cursor0;

    var days = 0;
    final granted = <DateTime>[];

    for (var i = 0; i < _maxLookbackDays; i++) {
      final key = localDateKey(cursor);
      if (nitnemDays.contains(key)) {
        days++;
      } else if (existingGraceDays.contains(key)) {
        // Already forgiven on an earlier run: the run continues.
      } else {
        final m = key.substring(0, 7);
        final spent = used[m] ?? 0;
        if (spent >= gracePerMonth) break;
        // Only bridge a gap that has a Nitnem day before it, so a fresh install
        // does not spend grace on the empty past.
        final before = localDateKey(cursor.subtract(const Duration(days: 1)));
        if (!nitnemDays.contains(before)) break;
        used[m] = spent + 1;
        granted.add(cursor);
      }
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return StreakResult(
      days: days,
      graceUsed: granted.reversed.toList(),
      graceLeftThisMonth: graceLeft(),
    );
  }

  /// The longest run in the history on the phone (09-diary D12): Nitnem days
  /// in a row, with a granted grace day bridging a gap without adding to the
  /// count, exactly as the current run is counted.
  static int longest({required Set<String> nitnemDays, required Set<String> graceDays}) {
    if (nitnemDays.isEmpty) return 0;
    final sorted = nitnemDays.toList()..sort();
    var best = 0;
    var run = 0;
    var cursor = parseLocalDateKey(sorted.first);
    final end = parseLocalDateKey(sorted.last);
    while (!cursor.isAfter(end)) {
      final key = localDateKey(cursor);
      if (nitnemDays.contains(key)) {
        run++;
        if (run > best) best = run;
      } else if (!graceDays.contains(key)) {
        run = 0;
      }
      cursor = cursor.add(const Duration(days: 1));
    }
    return best;
  }
}
