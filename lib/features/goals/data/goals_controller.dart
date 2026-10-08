import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/user_db.dart';
import '../../../core/db/user_repository.dart';
import '../../../core/time/clock.dart';
import '../domain/day_verdict.dart';

/// Today's rows, live: every item, today's completions and sittings.
final todayRowsProvider = StreamProvider<DayRows>((ref) {
  final today = ref.watch(clockProvider).today();
  return ref.watch(userRepositoryProvider).watchDay(today);
});

/// Today's verdict (04-goals §4.6). Today, the Goals screen and the
/// goal-complete cue all read this; nothing re-derives it.
final todayVerdictProvider = Provider<DayVerdict>(
  (ref) => ref.watch(todayRowsProvider).value?.verdict ?? DayVerdict.empty,
);

/// The items in scope today, in creation order (§7.3).
final itemsInScopeTodayProvider = Provider<List<GoalItem>>((ref) {
  final rows = ref.watch(todayRowsProvider).value;
  if (rows == null) return const [];
  return [...rows.itemsInScope]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
});

/// The active goal, or null (GL1).
final activeGoalProvider = StreamProvider<Goal?>(
  (ref) => ref.watch(userRepositoryProvider).watchActiveGoal(),
);

/// Whether any goal was ever made: the Set Goal card's two subtitles (§7.1).
final hadGoalProvider = StreamProvider<bool>(
  (ref) => ref.watch(userRepositoryProvider).watchHadGoal(),
);

/// Items met of items in scope today, for the Nitnem list's one line.
typedef GoalsSummary = ({int doneToday, int total});

final goalsSummaryProvider = Provider<GoalsSummary>((ref) {
  final v = ref.watch(todayVerdictProvider);
  return (doneToday: v.itemsMet, total: v.itemsInScope);
});

/// The Simran timer's length: the in-scope simran item's minutes, or null for
/// the 5-minute default (HZ4).
final simranGoalMinutesProvider = Provider<int?>((ref) {
  final items = ref.watch(itemsInScopeTodayProvider);
  return items.where((i) => i.itemType == ItemType.simran).firstOrNull?.simranMinutes;
});

/// How an item stands today: its progress against its target.
({int done, int target, bool met}) itemToday(GoalItem item, DayRows? rows) {
  if (rows == null) return (done: 0, target: item.timesPerDay, met: false);
  final done = itemProgress(item, rows.completions, rows.sittings);
  final met = itemMet(item, rows.completions, rows.sittings);
  return item.itemType == ItemType.simran
      ? (done: done ~/ 60, target: item.simranMinutes ?? 5, met: met)
      : (done: done, target: item.timesPerDay, met: met);
}
