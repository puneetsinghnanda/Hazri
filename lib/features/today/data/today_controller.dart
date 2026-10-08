import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/content_db.dart' show BaniSlot;
import '../../../core/db/content_repository.dart';
import '../../../core/db/user_db.dart';
import '../../../core/db/user_repository.dart';
import '../../../core/time/clock.dart';
import '../../goals/data/goals_controller.dart';
import '../../goals/domain/day_verdict.dart';
import '../../reminders/data/reminders_controller.dart';
import '../domain/today_state.dart';

/// What has been completed today and where the reader left off.
final dayProgressProvider = StreamProvider<DayProgress>((ref) async* {
  final repo = ref.watch(userRepositoryProvider);
  final clock = ref.watch(clockProvider);

  await for (final completions in repo.watchCompletionsOn(clock.today())) {
    final all = await repo.watchAllProgress().first;
    final today = clock.today();

    // Only a resume point saved today counts: yesterday's half-finished paath
    // should not become today's "Continue".
    ResumePoint? resume;
    for (final p in all) {
      final at = p.updatedAt.toLocal();
      if (DateTime(at.year, at.month, at.day) != today) continue;
      if (p.lineIdx <= 0) continue;
      if (resume == null || at.isAfter(resume.updatedAt)) {
        resume = ResumePoint(
          baniVersionId: p.baniVersionId,
          lineIdx: p.lineIdx,
          updatedAt: at,
        );
      }
    }

    final slots = <BaniSlot>{
      for (final c in completions)
        switch (c.slot) {
          BaniSlotValue.morning => BaniSlot.morning,
          BaniSlotValue.evening => BaniSlot.evening,
          BaniSlotValue.bedtime => BaniSlot.bedtime,
          BaniSlotValue.none => BaniSlot.none,
        },
    }..remove(BaniSlot.none);

    yield DayProgress(
      completedBaniIds: {for (final c in completions) c.baniId},
      completedSlots: slots,
      resume: resume,
    );
  }
});

/// Today's primary button (05-today T4).
final todayCtaProvider = Provider<TodayCta?>((ref) {
  final banis = ref.watch(banisProvider).value;
  final progress = ref.watch(dayProgressProvider).value;
  if (banis == null || progress == null) return null;
  final rows = ref.watch(todayRowsProvider).value;
  final items = ref.watch(itemsInScopeTodayProvider);
  final unmet = [
    for (final i in items)
      if (rows == null || !itemMet(i, rows.completions, rows.sittings))
        (baniId: i.itemType == ItemType.simran ? null : i.baniId, simranMinutes: i.simranMinutes),
  ];
  final slotTimes = ref.watch(slotTimesProvider).value ?? const {};
  return TodayLogic.cta(
    banis: banis,
    progress: progress,
    unmetItems: unmet,
    currentSlot: TodayLogic.slotAt(ref.watch(clockProvider).now(), slotTimes),
  );
});

/// Whether Simran has been completed today.
final simranDoneTodayProvider = StreamProvider<bool>((ref) async* {
  final repo = ref.watch(userRepositoryProvider);
  final clock = ref.watch(clockProvider);
  final todayKey = localDateKey(clock.today());
  await for (final sessions in repo.watchSimranSessions()) {
    yield sessions.any((s) => s.localDate == todayKey && s.completed);
  }
});

/// Minutes of Simran logged today (completed or not), for the Today tile.
final simranMinutesTodayProvider = StreamProvider<int>((ref) async* {
  final repo = ref.watch(userRepositoryProvider);
  final clock = ref.watch(clockProvider);
  final todayKey = localDateKey(clock.today());
  await for (final sessions in repo.watchSimranSessions()) {
    final seconds = sessions
        .where((s) => s.localDate == todayKey)
        .fold<int>(0, (sum, s) => sum + s.durationS);
    yield (seconds / 60).floor();
  }
});
