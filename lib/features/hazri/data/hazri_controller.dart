import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/db/user_db.dart';
import '../../../core/db/user_repository.dart';
import '../../../core/time/clock.dart';
import '../../../core/settings/settings_controller.dart';
import '../../goals/data/goals_controller.dart';
import '../../goals/domain/day_verdict.dart';
import '../../goals/domain/goal_constants.dart';
import '../domain/hazri.dart';

/// The live completions on one day, for the Diary's day screen.
final completionsOnProvider =
    StreamProvider.family<List<Completion>, DateTime>((ref, day) {
  return ref.watch(userRepositoryProvider).watchCompletionsOn(day);
});

/// The live sittings on one day.
final sittingsOnProvider =
    StreamProvider.family<List<SimranSession>, DateTime>((ref, day) {
  return ref.watch(userRepositoryProvider).watchSittingsOn(day);
});

/// Today's hazri: whether somebody has turned up, and with what (HZ1).
///
/// Derived, never stored: any live completion, or a sitting of 300 s or more.
final hazriTodayProvider = Provider<Hazri>((ref) {
  final rows = ref.watch(todayRowsProvider).value;
  if (rows == null) return Hazri.none;
  return Hazri.from(
    completions: [
      for (final c in rows.completions) (at: c.completedAt.toLocal(), baniId: c.baniId),
    ],
    completedSimran: [
      for (final s in rows.sittings)
        if (s.durationS >= GoalConstants.hazriSimranMinSeconds)
          s.startedAt.toLocal().add(Duration(seconds: s.durationS)),
    ],
  );
});

/// Whether today's goal is met: the cue for design 61 (CE1). Separate from
/// [hazriTodayProvider] — hazri and goals are two different things.
final goalsAllDoneTodayProvider = Provider<bool>(
  (ref) => ref.watch(todayVerdictProvider).goalState == GoalState.met,
);

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
