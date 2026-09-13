import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/user_repository.dart';
import '../../../core/time/clock.dart';
import '../domain/goal_progress.dart';

/// Every goal with today's progress attached.
final goalProgressProvider = StreamProvider<List<GoalProgress>>((ref) async* {
  final repo = ref.watch(userRepositoryProvider);
  final clock = ref.watch(clockProvider);

  await for (final goals in repo.watchGoals()) {
    final today = clock.today();
    final ticks = await repo.goalTicksOn(today);
    yield [
      for (final g in goals)
        GoalCalculator.progressFor(goal: g, ticksToday: ticks, today: today),
    ];
  }
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
