import 'package:flutter/foundation.dart';

import '../../../core/db/content_db.dart' show BaniSlot;
import '../../nitnem/domain/bani.dart';

/// Which button Today offers (PRD 1.3).
enum TodayCtaKind { startNitnem, continueBani, startBani, simran, allDone }

/// The primary action on Today.
@immutable
class TodayCta {
  const TodayCta({required this.kind, this.bani, this.minutes = 0, this.line});

  final TodayCtaKind kind;
  final Bani? bani;

  /// Minutes of paath the button is offering: the whole morning for
  /// `startNitnem`, what is left for `continueBani`, the bani for `startBani`.
  final int minutes;

  /// The line to resume at, for `continueBani`.
  final int? line;
}

/// Where a bani was left off.
@immutable
class ResumePoint {
  const ResumePoint({
    required this.baniVersionId,
    required this.lineIdx,
    required this.updatedAt,
  });

  final String baniVersionId;
  final int lineIdx;
  final DateTime updatedAt;
}

/// Everything Today needs to know about the day so far.
@immutable
class DayProgress {
  const DayProgress({
    required this.completedBaniIds,
    required this.completedSlots,
    required this.resume,
  });

  final Set<String> completedBaniIds;
  final Set<BaniSlot> completedSlots;

  /// The most recent resume point from today, if any.
  final ResumePoint? resume;

  bool isDone(BaniSlot slot) => completedSlots.contains(slot);
}

/// Works out Today's button and the day-arc state.
abstract final class TodayLogic {
  /// The CTA for the current state of the day (05-today T4), in order:
  ///
  /// 1. a paath in progress today → Continue, at the saved line;
  /// 2. the first goal item in scope not yet met, in the goal's order → its
  ///    bani, or the Simran menu with the item's minutes ([unmetItems] comes
  ///    from `verdictOn`, never a count of its own);
  /// 3. the current slot's first bani not completed today;
  /// 4. the next slot's first bani.
  static TodayCta cta({
    required List<Bani> banis,
    required DayProgress progress,
    List<({String? baniId, int? simranMinutes})> unmetItems = const [],
    BaniSlot currentSlot = BaniSlot.morning,
  }) {
    final resume = progress.resume;
    if (resume != null) {
      final bani = banis
          .where((b) => b.versionId == resume.baniVersionId)
          .where((b) => !progress.completedBaniIds.contains(b.id))
          .firstOrNull;
      if (bani != null && bani.lineCount > 0) {
        final left = (bani.lineCount - resume.lineIdx) / bani.lineCount;
        return TodayCta(
          kind: TodayCtaKind.continueBani,
          bani: bani,
          minutes: (bani.estMinutes * left).ceil().clamp(1, bani.estMinutes),
          line: resume.lineIdx,
        );
      }
    }

    for (final item in unmetItems) {
      if (item.baniId == null) {
        return TodayCta(kind: TodayCtaKind.simran, minutes: item.simranMinutes ?? 5);
      }
      final bani = banis.where((b) => b.id == item.baniId).firstOrNull;
      if (bani != null) return TodayCta(kind: TodayCtaKind.startBani, bani: bani, minutes: bani.estMinutes);
    }

    const order = [BaniSlot.morning, BaniSlot.evening, BaniSlot.bedtime];
    for (final slot in order.skip(order.indexOf(currentSlot).clamp(0, 2))) {
      final remaining = banis
          .where((b) => b.defaultSlot == slot && !progress.completedBaniIds.contains(b.id))
          .toList();
      if (remaining.isEmpty) continue;
      if (slot == BaniSlot.morning) {
        return TodayCta(
          kind: TodayCtaKind.startNitnem,
          bani: remaining.first,
          minutes: remaining.fold(0, (sum, b) => sum + b.estMinutes),
        );
      }
      return TodayCta(kind: TodayCtaKind.startBani, bani: remaining.first, minutes: remaining.first.estMinutes);
    }

    return const TodayCta(kind: TodayCtaKind.allDone);
  }

  /// The slot the clock is in: bedtime from its time, evening from sunset,
  /// otherwise morning.
  static BaniSlot slotAt(DateTime now, Map<BaniSlot, DateTime> slotTimes) {
    final bed = slotTimes[BaniSlot.bedtime];
    final eve = slotTimes[BaniSlot.evening];
    if (bed != null && !now.isBefore(bed)) return BaniSlot.bedtime;
    if (eve != null && !now.isBefore(eve)) return BaniSlot.evening;
    return BaniSlot.morning;
  }

  /// How many of the morning banis are finished, and how many there are.
  static (int done, int total) morningCount({
    required List<Bani> banis,
    required DayProgress progress,
  }) {
    final morning = banis.where((b) => b.defaultSlot == BaniSlot.morning).toList();
    final done = morning.where((b) => progress.completedBaniIds.contains(b.id)).length;
    return (done, morning.length);
  }

  /// The slot the day is currently in: the first one not finished yet.
  static BaniSlot activeSlot({
    required DayProgress progress,
    required Map<BaniSlot, DateTime> slotTimes,
    required DateTime now,
  }) {
    for (final slot in [BaniSlot.morning, BaniSlot.evening, BaniSlot.bedtime]) {
      if (!progress.isDone(slot)) return slot;
    }
    return BaniSlot.bedtime;
  }
}
