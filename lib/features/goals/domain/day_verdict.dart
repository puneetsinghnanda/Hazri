import 'package:flutter/foundation.dart';

import '../../../core/db/user_db.dart';
import '../../../core/time/clock.dart';
import 'goal_constants.dart';

/// `NONE`, `MET` or `NOT_MET` (04-goals §4.6).
enum GoalState { none, met, notMet }

/// What one day came to. Home, the Goals screen, the Diary grid and the Diary
/// day screen all get this from [verdictOn] and nowhere else (§4.6).
@immutable
class DayVerdict {
  const DayVerdict({
    required this.hazri,
    required this.itemsInScope,
    required this.itemsMet,
  });

  static const empty = DayVerdict(hazri: false, itemsInScope: 0, itemsMet: 0);

  final bool hazri;
  final int itemsInScope;
  final int itemsMet;

  GoalState get goalState {
    if (itemsInScope == 0) return GoalState.none;
    return itemsMet == itemsInScope ? GoalState.met : GoalState.notMet;
  }

  @override
  bool operator ==(Object other) =>
      other is DayVerdict &&
      other.hazri == hazri &&
      other.itemsInScope == itemsInScope &&
      other.itemsMet == itemsMet;

  @override
  int get hashCode => Object.hash(hazri, itemsInScope, itemsMet);

  @override
  String toString() => 'DayVerdict(hazri: $hazri, $itemsMet/$itemsInScope)';
}

/// The last day an item is in scope, or null when it is open-ended (GI3):
/// the earliest of its end date and the day before it was removed.
String? lastDayOf(GoalItem item) {
  final removed = item.removedOn;
  final beforeRemoved = removed == null
      ? null
      : localDateKey(parseLocalDateKey(removed).subtract(const Duration(days: 1)));
  final end = item.endDate;
  if (end == null) return beforeRemoved;
  if (beforeRemoved == null) return end;
  return end.compareTo(beforeRemoved) <= 0 ? end : beforeRemoved;
}

/// Whether [day] lies inside the item's window (GI3).
bool inScope(GoalItem item, String day) {
  if (day.compareTo(item.startDate) < 0) return false;
  final last = lastDayOf(item);
  return last == null || day.compareTo(last) <= 0;
}

/// The end date an item gets on save (GI4). [seriesStart] is the first
/// `startDate` of the item's series, which "for N days" counts from.
String? endDateFor({
  required DurationType type,
  required String seriesStart,
  int? durationDays,
  String? untilDate,
}) =>
    switch (type) {
      DurationType.everyDay => null,
      DurationType.days => localDateKey(
          parseLocalDateKey(seriesStart).add(Duration(days: (durationDays ?? 1) - 1))),
      DurationType.untilDate => untilDate,
    };

/// Whether one item was met on a day, from that day's live rows (§2).
bool itemMet(
  GoalItem item,
  Iterable<Completion> completions,
  Iterable<SimranSession> sittings,
) {
  switch (item.itemType) {
    case ItemType.bani:
      final n = completions
          .where((c) => c.deletedAt == null && c.baniId == item.baniId)
          .length;
      return n >= item.timesPerDay;
    case ItemType.simran:
      final need = (item.simranMinutes ?? GoalConstants.simranGoalMinutesMin) * 60;
      return sittings.any((s) => s.deletedAt == null && s.durationS >= need);
  }
}

/// How many times today an item has been done: completions of its bani, or
/// the longest sitting in seconds for Naam Simran.
int itemProgress(
  GoalItem item,
  Iterable<Completion> completions,
  Iterable<SimranSession> sittings,
) =>
    switch (item.itemType) {
      ItemType.bani => completions
          .where((c) => c.deletedAt == null && c.baniId == item.baniId)
          .length,
      ItemType.simran => sittings
          .where((s) => s.deletedAt == null)
          .fold(0, (best, s) => s.durationS > best ? s.durationS : best),
    };

/// Hazri (HZ1): any live completion, or a live sitting of 300 s or more.
bool hazriFrom(Iterable<Completion> completions, Iterable<SimranSession> sittings) =>
    completions.any((c) => c.deletedAt == null) ||
    sittings.any((s) =>
        s.deletedAt == null && s.durationS >= GoalConstants.hazriSimranMinSeconds);

/// The day verdict (§4.6). Pure: [completions] and [sittings] are that day's
/// rows; deleted rows are ignored here so callers may pass them in.
DayVerdict verdictOn(
  String day,
  Iterable<GoalItem> items,
  Iterable<Completion> completions,
  Iterable<SimranSession> sittings,
) {
  final dayCompletions = completions.where((c) => c.localDate == day).toList();
  final daySittings = sittings.where((s) => s.localDate == day).toList();
  var scope = 0;
  var met = 0;
  for (final item in items) {
    if (!inScope(item, day)) continue;
    scope++;
    if (itemMet(item, dayCompletions, daySittings)) met++;
  }
  return DayVerdict(
    hazri: hazriFrom(dayCompletions, daySittings),
    itemsInScope: scope,
    itemsMet: met,
  );
}
