import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/db/user_db.dart';
import '../../../core/db/user_repository.dart';
import '../../../core/time/clock.dart';
import '../../../core/settings/settings_controller.dart';
import '../../goals/data/goals_controller.dart';
import '../domain/hazri.dart';

/// Today's completions, and every simran session, as two plain streams.
///
/// Two subscriptions rather than one loop that queries the other inside
/// itself. The nested version worked and then hung under `flutter_test`'s
/// fake clock, which does not advance the real event loop drift needs: the
/// first event arrived and the `await` inside it never returned. Combining
/// two independent streams has no such await and is simpler to read besides.
final _completionsTodayProvider = StreamProvider<List<Completion>>((ref) {
  final repo = ref.watch(userRepositoryProvider);
  return repo.watchCompletionsOn(ref.watch(clockProvider).today());
});

final _simranSessionsProvider = StreamProvider<List<SimranSession>>(
  (ref) => ref.watch(userRepositoryProvider).watchSimranSessions(),
);

/// Today's hazri: whether somebody has turned up, and with what.
///
/// Derived, never stored. A hazri row would be a second source of truth for
/// something the completions and simran sessions already say, and the two
/// would drift the first time a diary entry was edited by hand.
final hazriTodayProvider = Provider<Hazri>((ref) {
  final todayKey = localDateKey(ref.watch(clockProvider).today());
  final completions = ref.watch(_completionsTodayProvider).value ?? const [];
  final sessions = ref.watch(_simranSessionsProvider).value ?? const [];

  return Hazri.from(
    completions: [
      for (final c in completions) (at: c.completedAt.toLocal(), baniId: c.baniId),
    ],
    completedSimran: [
      for (final s in sessions)
        if (s.localDate == todayKey && s.completed) s.startedAt.toLocal(),
    ],
  );
});

/// Whether every active goal has been met today.
///
/// The cue for design 61, and deliberately separate from [hazriTodayProvider]:
/// the reader was explicit that hazri and goals are two different things and
/// one does not imply the other.
final goalsAllDoneTodayProvider = Provider<bool>((ref) {
  final summary = ref.watch(goalsSummaryProvider);
  return summary.total > 0 && summary.doneToday >= summary.total;
});

/// Shows design 61 once, on the day the goals are all met.
///
/// "Once" is the point. The sheet celebrates something that happened; a sheet
/// that reappears every time Today rebuilds, or every time the app is opened
/// that evening, turns a moment into an interruption. The day it last showed
/// is kept in shared preferences, so it survives a restart and rolls over at
/// midnight on its own.
class GoalCompleteCue {
  GoalCompleteCue(this._prefs);

  final SharedPreferences _prefs;

  static const _key = 'goal_complete_sheet_shown_on';

  bool shouldShowFor(DateTime today) =>
      _prefs.getString(_key) != localDateKey(today);

  Future<void> markShown(DateTime today) =>
      _prefs.setString(_key, localDateKey(today));
}

final goalCompleteCueProvider = Provider<GoalCompleteCue>(
  (ref) => GoalCompleteCue(ref.watch(sharedPreferencesProvider)),
);
