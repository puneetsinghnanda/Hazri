import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/content_db.dart' show BaniSlot;
import '../../../core/db/content_repository.dart';
import '../../../core/db/user_db.dart';
import '../../../core/db/user_repository.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/time/clock.dart';
import '../../goals/data/goals_controller.dart';
import '../../goals/domain/goal_progress.dart';
import '../../gurpurab/domain/calendar_display.dart';
import '../domain/reminder_plan.dart';
import 'reminder_service.dart';

/// Every reminder row, seeded with the defaults on first run.
final remindersProvider = StreamProvider<List<Reminder>>((ref) async* {
  final repo = ref.watch(userRepositoryProvider);
  await _seedDefaults(repo);
  yield* repo.watchReminders();
});

/// The reminder defaults from PRD 1.2, step 3.
Future<void> _seedDefaults(UserRepository repo) async {
  final existing = await repo.reminders();
  if (existing.isNotEmpty) return;
  final now = DateTime.now().toUtc();

  Future<void> add(String id, ReminderTarget type, ReminderMode mode, {String? time}) =>
      repo.saveReminder(RemindersCompanion.insert(
        id: id,
        targetType: type,
        targetId: id,
        mode: mode,
        timeHhmm: Value(time),
        updatedAt: now,
      ));

  await add(ReminderIds.amritVela, ReminderTarget.slot, ReminderMode.auto);
  await add(ReminderIds.evening, ReminderTarget.slot, ReminderMode.auto);
  await add(ReminderIds.bedtime, ReminderTarget.slot, ReminderMode.fixed, time: '22:00');
  await add(ReminderIds.simran, ReminderTarget.simran, ReminderMode.fixed, time: '06:00');
  await add(ReminderIds.gurpurab, ReminderTarget.gurpurab, ReminderMode.fixed, time: '20:00');
}

/// The user's chosen location for the Auto times.
final sunLocationProvider = FutureProvider<SunLocation>((ref) async {
  final cityId = ref.watch(settingsProvider.select((s) => s.cityId));
  final city = await ref.watch(contentRepositoryProvider).city(cityId);
  // New Delhi, the default the setup screen starts from.
  return SunLocation(latitude: city?.lat ?? 28.6139, longitude: city?.lon ?? 77.2090);
});

/// Today's Auto times, for the rows that show "Auto · 4:30 AM".
final autoTimesProvider = FutureProvider<Map<String, DateTime?>>((ref) async {
  final at = await ref.watch(sunLocationProvider.future);
  final today = ref.watch(clockProvider).today();
  return {
    ReminderIds.amritVela: ReminderPlanner.amritVelaFor(today, at),
    ReminderIds.evening: ReminderPlanner.eveningFor(today, at),
    ReminderIds.bedtime: ReminderPlanner.bedtimeFor(today, at),
  };
});

/// The time each slot happens today, whatever its reminder mode — the day arc
/// and the Nitnem list use these even when a reminder is switched off
/// (PRD 1.3).
final slotTimesProvider = FutureProvider<Map<BaniSlot, DateTime>>((ref) async {
  final at = await ref.watch(sunLocationProvider.future);
  final today = ref.watch(clockProvider).today();
  final reminders = ref.watch(remindersProvider).value ?? const <Reminder>[];
  final byId = {for (final r in reminders) r.id: r};

  DateTime resolve(String id, DateTime? auto, int fallbackHour, int fallbackMinute) {
    final r = byId[id];
    if (r != null && r.mode == ReminderMode.fixed && r.timeHhmm != null) {
      final parts = r.timeHhmm!.split(':');
      return DateTime(today.year, today.month, today.day, int.parse(parts[0]), int.parse(parts[1]));
    }
    return auto ??
        DateTime(today.year, today.month, today.day, fallbackHour, fallbackMinute);
  }

  return {
    BaniSlot.morning: resolve(
      ReminderIds.amritVela,
      ReminderPlanner.amritVelaFor(today, at),
      4,
      30,
    ),
    BaniSlot.evening: resolve(ReminderIds.evening, ReminderPlanner.eveningFor(today, at), 18, 30),
    BaniSlot.bedtime: resolve(ReminderIds.bedtime, ReminderPlanner.bedtimeFor(today, at), 22, 0),
  };
});

final reminderSchedulerProvider = Provider<ReminderScheduler>(
  (ref) => ReminderScheduler(ref),
);

/// Turns reminder rows into pending notifications.
class ReminderScheduler {
  ReminderScheduler(this._ref);

  final Ref _ref;

  /// Re-plans the whole rolling window.
  ///
  /// Called on app start, after any reminder change, and after the city
  /// changes (PRD 1.10).
  Future<void> reschedule() async {
    final service = _ref.read(reminderServiceProvider);
    if (!await service.notificationsAllowed()) {
      await service.cancelAll();
      return;
    }

    final repo = _ref.read(userRepositoryProvider);
    final clock = _ref.read(clockProvider);
    final at = await _ref.read(sunLocationProvider.future);

    // Seed here rather than relying on somebody having opened a screen that
    // lists reminders. `remindersProvider` used to be the only thing that
    // seeded, so on a phone where that screen was never opened this read came
    // back empty and the app scheduled nothing, silently, for ever.
    await _seedDefaults(repo);
    final reminders = [...await repo.reminders(), ...await _goalReminders(repo)];
    final l = await L.delegate.load(_ref.read(settingsProvider).locale);

    // A slot already finished today does not need reminding about.
    final completions = await repo.completionsOn(clock.today());
    final completed = <String>{
      for (final c in completions)
        if (c.slot == BaniSlotValue.morning)
          ReminderIds.amritVela
        else if (c.slot == BaniSlotValue.evening)
          ReminderIds.evening
        else if (c.slot == BaniSlotValue.bedtime)
          ReminderIds.bedtime,
    };

    final events = await _remindedEvents();
    final occurrences = ReminderPlanner.plan(
      reminders: reminders,
      from: clock.now(),
      at: at,
      completedToday: completed,
      gurpurabDates: events.keys.toSet(),
    );

    final content = _ref.read(contentRepositoryProvider);
    final banis = await content.banis();
    final bySlot = <BaniSlot, List<String>>{};
    for (final b in banis) {
      bySlot.putIfAbsent(b.defaultSlot, () => []).add(b.name(l.localeName));
    }
    final sunrise = ReminderPlanner.amritVelaFor(clock.today(), at);
    final summary = _ref.read(goalsSummaryProvider);
    final goalsDone = (summary.doneToday, summary.total);

    final notifications = <ScheduledNotification>[
      for (final o in occurrences)
        _describe(l, o,
            bySlot: bySlot,
            sunriseLabel: sunrise,
            banis: banis,
            events: events,
            goalsDone: goalsDone),
    ];
    await service.replaceSchedule(notifications);
  }

  /// One reminder per goal that carries a time, built in memory.
  ///
  /// `Goals.reminderTime` was shown on the Goals screen, on Today's card and
  /// on the Diary's day screen, and scheduled nowhere: a goal set for 6:40 PM
  /// said 6:40 PM in three places and never notified. These rows are derived
  /// rather than stored, so adding, retiming or stopping a goal changes the
  /// schedule at the next re-plan with nothing to keep in step.
  Future<List<Reminder>> _goalReminders(UserRepository repo) async {
    final today = _ref.read(clockProvider).today();
    final goals = await repo.activeGoals();
    final now = DateTime.now().toUtc();
    return [
      for (final g in goals)
        if (g.reminderTime != null && GoalCalculator.appliesOn(g, today))
          Reminder(
            id: ReminderIds.goal(g.id),
            targetType: ReminderTarget.goal,
            targetId: g.id,
            mode: ReminderMode.fixed,
            timeHhmm: g.reminderTime,
            daysMask: 0x7F,
            updatedAt: now,
          ),
    ];
  }

  /// The days that carry an event the reader has asked to be reminded about,
  /// mapped to the name to put in the notification.
  ///
  /// `default_remind` is the calendar's own judgement -- 52 of its 147 events
  /// -- and a per-event switch in the app overrides it either way. Where two
  /// events share a day the first one named wins, because a notification has
  /// room for one.
  Future<Map<DateTime, String>> _remindedEvents() async {
    final l10n = _ref.read(settingsProvider).locale.languageCode;
    final rows = await _ref.read(contentRepositoryProvider).calendarEvents();
    final overrides = await _ref.read(userRepositoryProvider).eventOverrides();

    final out = <DateTime, String>{};
    for (final e in rows) {
      if (!(overrides[e.id] ?? e.defaultRemind)) continue;
      final date = DateTime.tryParse(e.date);
      if (date == null) continue;
      out.putIfAbsent(
        DateTime(date.year, date.month, date.day),
        () => e.nameFor(l10n),
      );
    }
    return out;
  }

  ScheduledNotification _describe(
    L l,
    ReminderOccurrence o, {
    required Map<BaniSlot, List<String>> bySlot,
    required DateTime? sunriseLabel,
    required List<dynamic> banis,
    required Map<DateTime, String> events,
    required (int, int) goalsDone,
  }) {
    final hhmm = '${o.at.hour.toString().padLeft(2, '0')}:'
        '${o.at.minute.toString().padLeft(2, '0')}';

    switch (o.reminderId) {
      case ReminderIds.amritVela:
        final first = bySlot[BaniSlot.morning]?.firstOrNull ?? l.slotAmritVela;
        return ScheduledNotification(
          id: o.notificationId,
          at: o.at,
          title: l.notifAmritVelaTitle,
          body: l.notifAmritVelaBody(first, hhmm),
          channel: ReminderChannel.nitnem,
          channelName: l.notifChannelNitnem,
          payload: '/reader/japji-sahib',
        );
      case ReminderIds.evening:
        return ScheduledNotification(
          id: o.notificationId,
          at: o.at,
          title: l.diaryStatRehras,
          body: l.notifRehrasBody(18),
          channel: ReminderChannel.nitnem,
          channelName: l.notifChannelNitnem,
          payload: '/reader/rehras-sahib',
        );
      case ReminderIds.bedtime:
        return ScheduledNotification(
          id: o.notificationId,
          at: o.at,
          title: l.diaryStatSohila,
          body: l.notifBaniBody(l.diaryStatSohila, 5),
          channel: ReminderChannel.nitnem,
          channelName: l.notifChannelNitnem,
          payload: '/reader/kirtan-sohila',
        );
      case ReminderIds.simran:
        return ScheduledNotification(
          id: o.notificationId,
          at: o.at,
          title: l.notifSimranTitle,
          body: l.notifSimranBody,
          channel: ReminderChannel.simran,
          channelName: l.notifChannelSimran,
          payload: '/simran',
        );
      case ReminderIds.gurpurab:
        // The occurrence is the eve, so the day being named is the next one.
        // The planner only emits these for days that are in `events`, so the
        // fallback is unreachable rather than a guess about the calendar.
        final day = DateTime(o.at.year, o.at.month, o.at.day)
            .add(const Duration(days: 1));
        return ScheduledNotification(
          id: o.notificationId,
          at: o.at,
          title: l.notifGurpurabTitle,
          body: events[day] ?? l.gurpurabTitle,
          channel: ReminderChannel.gurpurab,
          channelName: l.notifChannelGurpurab,
          payload: '/gurpurab',
        );
      default:
        // A goal reminder. `goalsDone` is filled in by reschedule() before the
        // notification is described, so the body says where the day stands
        // rather than a hardcoded nought.
        return ScheduledNotification(
          id: o.notificationId,
          at: o.at,
          title: l.goalsTitle,
          body: l.notifGoalBody(goalsDone.$1, goalsDone.$2),
          channel: ReminderChannel.goals,
          channelName: l.notifChannelGoals,
          payload: '/goals',
        );
    }
  }
}
