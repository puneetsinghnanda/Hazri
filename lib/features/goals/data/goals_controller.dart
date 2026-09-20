import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/user_db.dart';
import '../../../core/db/user_repository.dart';
import '../../../core/time/clock.dart';
import '../domain/goal_progress.dart';

/// Every goal with today's progress attached.
final goalProgressProvider = StreamProvider<List<GoalProgress>>((ref) {
  final repo = ref.watch(userRepositoryProvider);
  final today = ref.watch(clockProvider).today();

  // Goals and today's ticks arrive together, so finishing a bani moves the
  // count while the screen is open.
  return repo.watchGoalsAndTicks(today).map((data) => [
        for (final g in data.goals)
          GoalCalculator.progressFor(goal: g, ticksToday: data.ticks, today: today),
      ]);
});

/// The one-line summary shown on the Nitnem list.
typedef GoalsSummary = ({int doneToday, int total});

final goalsSummaryProvider = Provider<GoalsSummary>((ref) {
  final progress = ref.watch(goalProgressProvider).value ?? const <GoalProgress>[];
  final active = progress.where((p) => p.goal.active && !p.isComplete).toList();
  return (
    doneToday: active.where((p) => p.isDoneToday).length,
    total: active.length,
  );
});

/// The length of an open Naam Simran goal, or null when there is none.
///
/// A simran goal carries the minutes somebody chose for it, and the Simran
/// screen used the five-minute default whatever the goal said — so an eleven
/// minute goal started an eleven minute recitation that stopped at five and
/// was logged as five. The goal wins where there is one; Settings is what
/// somebody who has not set a goal gets.
final simranGoalMinutesProvider = Provider<int?>((ref) {
  final progress = ref.watch(goalProgressProvider).value ?? const <GoalProgress>[];
  return progress
      .where((p) => p.goal.baniId == kSimranGoalId && p.goal.active && !p.isComplete)
      .map((p) => p.goal.minutes)
      .whereType<int>()
      .firstOrNull;
});
