import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/content_db.dart' show BaniSlot;
import '../../../core/db/content_repository.dart';
import '../../../core/db/user_db.dart';
import '../../../core/db/user_repository.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/time/clock.dart';
import '../../../core/time/solar.dart';
import '../../gurpurab/domain/calendar_display.dart';
import '../../nitnem/domain/bani.dart';
import '../domain/reminder_plan.dart';
import 'notification_switches.dart';
import 'reminder_service.dart';

/// Where a place is, for sunrise and sunset.
@immutable
class SunLocation {
  const SunLocation({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

/// The place sunrise and sunset are worked out for. New Delhi until the
/// profile's city replaces the Settings city in step 4 (03-first-run CY1).
final sunLocationProvider = FutureProvider<SunLocation>((ref) async {
  final cityId = ref.watch(settingsProvider.select((s) => s.cityId));
  final city = await ref.watch(contentRepositoryProvider).city(cityId);
  return SunLocation(latitude: city?.lat ?? 28.6139, longitude: city?.lon ?? 77.2090);
});

/// When each slot of the day begins, for the Nitnem list and Today's call to
/// action (05-today T4). Amrit Vela is 90 minutes before sunrise, the evening
/// slot at sunset, bedtime three and a half hours after it, held between
/// 21:00 and 23:30; fixed fallbacks where the sun does not rise or set.
final slotTimesProvider = FutureProvider<Map<BaniSlot, DateTime>>((ref) async {
  final at = await ref.watch(sunLocationProvider.future);
  final today = ref.watch(clockProvider).today();
  DateTime fixed(int h, int m) => DateTime(today.year, today.month, today.day, h, m);
  final sunrise = SolarService.sunrise(today, at.latitude, at.longitude)?.toLocal();
  final sunset = SolarService.sunset(today, at.latitude, at.longitude)?.toLocal();
  final morning = sunrise == null
      ? fixed(4, 30)
      : roundToNearestMinutes(sunrise.subtract(const Duration(minutes: 90)), 5);
  final evening = sunset == null ? fixed(18, 30) : roundToNearestMinutes(sunset, 5);
  var bedtime = sunset == null
      ? fixed(22, 0)
      : roundToNearestMinutes(sunset.add(const Duration(hours: 3, minutes: 30)), 5);
  if (bedtime.isBefore(fixed(21, 0))) bedtime = fixed(21, 0);
  if (bedtime.isAfter(fixed(23, 30))) bedtime = fixed(23, 30);
  return {BaniSlot.morning: morning, BaniSlot.evening: evening, BaniSlot.bedtime: bedtime};
});

final reminderSchedulerProvider = Provider<ReminderScheduler>((ref) {
  final scheduler = ReminderScheduler(ref);
  // RM3, CM2: every completion, sitting, Diary edit and goal change re-plans.
  ref.read(userRepositoryProvider).onChanged = scheduler.requestReschedule;
  return scheduler;
});

/// Turns the day's state into pending notifications (02-notifications §6).
class ReminderScheduler {
  ReminderScheduler(this._ref);

  final Ref _ref;
  Timer? _debounce;

  /// While a Simran sitting runs, nothing fires before it ends (CM5).
  DateTime? _quietUntil;

  void setQuietUntil(DateTime? until) {
    _quietUntil = until;
    requestReschedule();
  }

  /// Coalesces a burst of writes (a Diary − and its outbox row, a goal edit)
  /// into one re-plan.
  void requestReschedule() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => unawaited(reschedule()));
  }

  /// Re-plans the whole rolling window (CM2). Asks for the permission first:
  /// Android shows its dialog only while it has no recorded answer (F6).
  Future<void> reschedule() async {
    final service = _ref.read(reminderServiceProvider);
    if (!await service.notificationsAllowed()) {
      await service.requestNotificationPermission();
    }
    if (!await service.notificationsAllowed()) {
      // Still refused. Nothing can arrive; the Notifications screen says so.
      await service.cancelAll();
      return;
    }

    final input = await buildInput();
    final l = await L.delegate.load(_ref.read(settingsProvider).locale);
    final planned = ReminderPlanner.plan(l, input);
    await service.replaceSchedule(planned, channelNames: channelNames(l));
  }

  static Map<NotificationKind, String> channelNames(L l) => {
        NotificationKind.amritVela: l.notifChannelAmritVela,
        NotificationKind.goalBani: l.notifChannelGoals,
        NotificationKind.calendar: l.notifChannelCalendar,
        NotificationKind.hazriNudge: l.notifChannelHazri,
        NotificationKind.sangat: l.notifChannelSangat,
      };

  /// Everything [ReminderPlanner.plan] reads, from the databases and settings.
  Future<PlannerInput> buildInput() async {
    final repo = _ref.read(userRepositoryProvider);
    final content = _ref.read(contentRepositoryProvider);
    final clock = _ref.read(clockProvider);
    final lang = _ref.read(settingsProvider).locale.languageCode;
    final today = clock.today();

    final banis = await content.banis();
    final names = {for (final Bani b in banis) b.id: b.name(lang)};
    final todayCompletions = await repo.completionsOn(today);
    final rows = await repo.dayRows(today);

    final overrides = await repo.eventOverrides();
    final events = [
      for (final e in await content.calendarEvents())
        PlannerEvent(
          id: e.id,
          date: e.date,
          kind: e.kind,
          name: e.nameFor(lang),
          remind: overrides[e.id] ?? e.defaultRemind,
        ),
    ];

    // CM4: the streak through today, only once today's Nitnem is done.
    final nitnemToday = todayCompletions.any((c) => c.slot != BaniSlotValue.none);
    final streak = nitnemToday ? (await repo.nitnemStreak()).current : null;

    return PlannerInput(
      now: clock.now(),
      enabled: _ref.read(notificationSwitchesProvider),
      items: rows.items,
      todayCompletions: rows.completions,
      todaySittings: rows.sittings,
      banis: names,
      events: events,
      streakThroughToday: streak,
      quietUntil: _quietUntil,
    );
  }
}
