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

/// Works out each goal's state for a given day.
abstract final class GoalCalculator {
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

    final complete = totalDays != null && dayNumber > totalDays;
    return GoalProgress(
      goal: goal,
      doneToday: done,
      dayNumber: dayNumber,
      totalDays: totalDays,
      isComplete: complete,
    );
  }
}
