import 'package:flutter/foundation.dart';

import '../../../core/db/user_db.dart';
import '../../../core/time/solar.dart';

/// The five things a reminder can be set on, plus one per paath goal.
abstract final class ReminderIds {
  static const amritVela = 'slot:morning';
  static const evening = 'slot:evening';
  static const bedtime = 'slot:bedtime';
  static const simran = 'simran';
  static const gurpurab = 'gurpurab';

  static String goal(String goalId) => 'goal:$goalId';

  /// The rows created on first run, before the user changes anything
  /// (PRD 1.2, step 3).
  static const defaults = [amritVela, evening, bedtime, simran, gurpurab];
}

/// One reminder due at one instant.
@immutable
class ReminderOccurrence {
  const ReminderOccurrence({
    required this.reminderId,
    required this.at,
    required this.notificationId,
  });

  final String reminderId;
  final DateTime at;

  /// Stable within a scheduling window so re-planning replaces rather than
  /// duplicates.
  final int notificationId;

  @override
  bool operator ==(Object other) =>
      other is ReminderOccurrence &&
      other.reminderId == reminderId &&
      other.at == at &&
      other.notificationId == notificationId;

  @override
  int get hashCode => Object.hash(reminderId, at, notificationId);
}

/// Where a place is, for the Auto times.
@immutable
class SunLocation {
  const SunLocation({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

/// Works out when each reminder should next fire.
///
/// Occurrences are planned for a rolling window and capped at 60 pending, which
/// keeps the same scheduler usable on iOS later, where 64 is the hard limit
/// (PRD §17.2).
abstract final class ReminderPlanner {
  static const int windowDays = 7;
  static const int maxPending = 60;

  /// Amrit Vela is 90 minutes before sunrise, rounded to five minutes.
  static DateTime? amritVelaFor(DateTime date, SunLocation at) {
    final sunrise = SolarService.sunrise(date, at.latitude, at.longitude)?.toLocal();
    if (sunrise == null) return null;
    return roundToNearestMinutes(sunrise.subtract(const Duration(minutes: 90)), 5);
  }

  /// Rehras is at sunset, rounded to five minutes.
  static DateTime? eveningFor(DateTime date, SunLocation at) {
    final sunset = SolarService.sunset(date, at.latitude, at.longitude)?.toLocal();
    if (sunset == null) return null;
    return roundToNearestMinutes(sunset, 5);
  }

  /// Kirtan Sohila is three and a half hours after sunset, held between 21:00
  /// and 23:30 so it never lands at an odd hour in high latitudes.
  static DateTime? bedtimeFor(DateTime date, SunLocation at) {
    final sunset = SolarService.sunset(date, at.latitude, at.longitude)?.toLocal();
    if (sunset == null) return null;
    final raw = roundToNearestMinutes(
      sunset.add(const Duration(hours: 3, minutes: 30)),
      5,
    );
    final day = DateTime(date.year, date.month, date.day);
    final earliest = day.add(const Duration(hours: 21));
    final latest = day.add(const Duration(hours: 23, minutes: 30));
    if (raw.isBefore(earliest)) return earliest;
    if (raw.isAfter(latest)) return latest;
    return raw;
  }

  /// The Auto time for [reminderId] on [date], or null where there is no Auto
  /// rule (or the sun does not rise or set there that day).
  static DateTime? autoTimeFor(String reminderId, DateTime date, SunLocation at) =>
      switch (reminderId) {
        ReminderIds.amritVela => amritVelaFor(date, at),
        ReminderIds.evening => eveningFor(date, at),
        ReminderIds.bedtime => bedtimeFor(date, at),
        _ => null,
      };

  /// The time a reminder is due on [date], honouring its mode and repeat days.
  static DateTime? timeOn(Reminder r, DateTime date, SunLocation at) {
    if (r.mode == ReminderMode.off) return null;
    // daysMask bit 0 is Monday.
    if ((r.daysMask & (1 << (date.weekday - 1))) == 0) return null;

    if (r.mode == ReminderMode.auto) {
      final auto = autoTimeFor(r.id, date, at);
      if (auto == null) return null;
      return r.offsetMin == null ? auto : auto.add(Duration(minutes: r.offsetMin!));
    }

    final hhmm = r.timeHhmm;
    if (hhmm == null) return null;
    final parts = hhmm.split(':');
    return DateTime(date.year, date.month, date.day, int.parse(parts[0]), int.parse(parts[1]));
  }

  /// Every occurrence due in the next [windowDays], in time order.
  ///
  /// [completedToday] names the reminders whose slot is already done, so those
  /// are suppressed for today only (PRD 1.10).
  static List<ReminderOccurrence> plan({
    required List<Reminder> reminders,
    required DateTime from,
    required SunLocation at,
    Set<String> completedToday = const {},
  }) {
    final out = <ReminderOccurrence>[];
    final today = DateTime(from.year, from.month, from.day);

    for (var d = 0; d < windowDays; d++) {
      final date = today.add(Duration(days: d));
      for (final r in reminders) {
        if (d == 0 && completedToday.contains(r.id)) continue;
        final time = timeOn(r, date, at);
        if (time == null || !time.isAfter(from)) continue;
        out.add(ReminderOccurrence(
          reminderId: r.id,
          at: time,
          notificationId: notificationIdFor(r.id, date),
        ));
      }
    }

    out.sort((a, b) => a.at.compareTo(b.at));
    return out.length <= maxPending ? out : out.sublist(0, maxPending);
  }

  /// A small, stable integer per reminder per day.
  ///
  /// The day-of-year term keeps the seven days of a window distinct while
  /// letting the next window reuse ids that have already fired.
  static int notificationIdFor(String reminderId, DateTime date) {
    final dayOfYear = date.difference(DateTime(date.year)).inDays;
    return (reminderId.hashCode.abs() % 100000) * 400 + dayOfYear + 1;
  }
}
