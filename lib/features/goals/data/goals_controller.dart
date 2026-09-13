import 'package:flutter_riverpod/flutter_riverpod.dart';

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
