import 'package:flutter/foundation.dart';

import '../../../core/db/content_db.dart' show BaniSlot;
import '../../nitnem/domain/bani.dart';

/// Which button Today offers (PRD 1.3).
enum TodayCtaKind { startNitnem, continueBani, startBani, allDone }

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
  /// The CTA for the current state of the day.
  ///
  /// Order matters: a paath already under way is always offered before a fresh
  /// one, so "Continue" wins over "Start".
  static TodayCta cta({
    required List<Bani> banis,
    required DayProgress progress,
  }) {
    final morning = banis.where((b) => b.defaultSlot == BaniSlot.morning).toList();

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

    if (!progress.isDone(BaniSlot.morning)) {
      final remaining =
          morning.where((b) => !progress.completedBaniIds.contains(b.id)).toList();
      final next = remaining.firstOrNull ?? morning.firstOrNull;
      return TodayCta(
        kind: TodayCtaKind.startNitnem,
        bani: next,
        minutes: remaining.fold(0, (sum, b) => sum + b.estMinutes),
      );
    }

    for (final slot in [BaniSlot.evening, BaniSlot.bedtime]) {
      if (progress.isDone(slot)) continue;
      final bani = banis.where((b) => b.defaultSlot == slot).firstOrNull;
      if (bani == null) continue;
      return TodayCta(kind: TodayCtaKind.startBani, bani: bani, minutes: bani.estMinutes);
    }

    return const TodayCta(kind: TodayCtaKind.allDone);
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
