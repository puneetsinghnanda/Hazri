import 'package:flutter/foundation.dart';

import '../../../core/db/user_db.dart';
import '../../../core/time/clock.dart';

/// Where one goal stands today.
@immutable
class GoalProgress {
  const GoalProgress({
    required this.goal,
    required this.doneToday,
    required this.dayNumber,
    required this.totalDays,
    required this.isComplete,
  });

  final Goal goal;
  final int doneToday;

  /// Which day of the goal today is, counting from its start date.
  final int dayNumber;

  /// The goal's length in days, or null for an open-ended one.
  final int? totalDays;

  /// True once the goal has run its course.
  final bool isComplete;

  bool get isDoneToday => doneToday >= goal.timesPerDay;

  double get fraction =>
      goal.timesPerDay == 0 ? 0 : (doneToday / goal.timesPerDay).clamp(0.0, 1.0);
}

/// What the goals came to on one day.
///
/// Both numbers matter and they answer different questions. [inScope] is
/// whether the day had any goals at all, which is what decides one dot or two
/// in the diary: a day before anybody set a goal, or after the last one ran
/// out, was not a day anybody failed. [met] is how many of them were finished.
@immutable
class GoalDay {
  const GoalDay({required this.inScope, required this.met});

  static const none = GoalDay(inScope: 0, met: 0);

  final int inScope;
  final int met;

  /// Whether this day asked anything of anybody. The diary draws its second
  /// dot only when this is true.
  bool get hasGoals => inScope > 0;

  /// Every goal the day asked for was finished on it.
  bool get allMet => inScope > 0 && met == inScope;
}

/// Works out each goal's state for a given day.
///
/// **One rule, used everywhere.** Today's card, the diary's month grid and the
/// diary's day screen all ask "were the goals met" and used to answer it three
/// different ways -- the grid counted a goal met on a single tick, ignoring
/// `timesPerDay`, and judged every goal that had ever started against every
/// later day. A goal of three paath a day lit the green dot after one, and a
/// goal that ended a fortnight ago darkened every day since. Anything that
/// needs the answer calls [outcomeOn] or [appliesOn]; nothing re-derives it.
abstract final class GoalCalculator {
  /// The last day [g] asks anything of, or null if it never stops.
  ///
  /// Three things can end a goal and the earliest of them wins: its length in
  /// days, the date it was set to run until, and somebody stopping it.
  static DateTime? lastDayOf(Goal g) {
    final start = parseLocalDateKey(g.startDate);
    DateTime? end = switch (g.durationType) {
      // A seven-day goal starting on the 1st ends on the 7th, not the 8th.
      GoalDuration.days => g.days == null
          ? null
          : DateTime(start.year, start.month, start.day + g.days! - 1),
      GoalDuration.until =>
        g.untilDate == null ? null : parseLocalDateKey(g.untilDate!),
      GoalDuration.everyDay => null,
    };
    final stopped = g.endedOn == null ? null : parseLocalDateKey(g.endedOn!);
    if (stopped != null && (end == null || stopped.isBefore(end))) end = stopped;
    return end;
  }

  /// Whether [g] asked anything of [day].
  ///
  /// Outside this window the goal is not unmet, it is absent -- which is the
  /// difference between a grey second dot and no second dot at all.
  static bool appliesOn(Goal g, DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    if (d.isBefore(parseLocalDateKey(g.startDate))) return false;
    final last = lastDayOf(g);
    return last == null || !d.isAfter(last);
  }

  /// How [day] went, given every goal and that day's tick counts by goal id.
  static GoalDay outcomeOn({
    required Iterable<Goal> goals,
    required Map<String, int> ticks,
    required DateTime day,
  }) {
    var inScope = 0;
    var met = 0;
    for (final g in goals) {
      if (!appliesOn(g, day)) continue;
      inScope++;
      // The same bar Today's card uses: a goal of three is met at three.
      if ((ticks[g.id] ?? 0) >= g.timesPerDay) met++;
    }
    return GoalDay(inScope: inScope, met: met);
  }

  static GoalProgress progressFor({
    required Goal goal,
    required List<GoalTick> ticksToday,
    required DateTime today,
  }) {
    final done = ticksToday.where((t) => t.goalId == goal.id).length;
    final start = parseLocalDateKey(goal.startDate);
    final dayNumber = today.difference(start).inDays + 1;

    final int? totalDays = switch (goal.durationType) {
      GoalDuration.days => goal.days,
      GoalDuration.until => goal.untilDate == null
          ? null
          : parseLocalDateKey(goal.untilDate!).difference(start).inDays + 1,
      GoalDuration.everyDay => null,
    };

    // The same window every other screen uses, rather than a second opinion.
    final complete = !appliesOn(goal, today);
    return GoalProgress(
      goal: goal,
      doneToday: done,
      dayNumber: dayNumber,
      totalDays: totalDays,
      isComplete: complete,
    );
  }
}
