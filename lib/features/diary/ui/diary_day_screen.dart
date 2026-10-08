import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/db/content_db.dart' show BaniSlot;
import '../../../core/db/content_repository.dart';
import '../../../core/db/user_db.dart';
import '../../../core/db/user_repository.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/time/clock.dart';
import '../../../core/time/date_format.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/app_mark.dart';
import '../../../core/widgets/surfaces.dart';
import '../../goals/domain/day_verdict.dart';
import '../../goals/domain/goal_constants.dart';
import '../../nitnem/domain/bani.dart';

/// One day's live rows; the verdict is recomputed on every change, so both
/// dots and this screen update together (04-goals §7.5).
final diaryDayRowsProvider = StreamProvider.family<DayRows, DateTime>(
  (ref, date) => ref.watch(userRepositoryProvider).watchDay(date),
);

/// One day in the diary (design 56).
///
/// A pushed screen inside the Diary branch, not a bottom sheet: design 56 is
/// a whole screen with the bottom nav still under it, and a sheet cut the
/// stats and the note off the bottom of a small phone.
class DiaryDayScreen extends ConsumerWidget {
  const DiaryDayScreen({super.key, required this.date});

  final DateTime date;

  /// Today and the seven days before it can be edited (09-diary D6).
  static bool isEditable(DateTime date, DateTime today) {
    final age = today.difference(DateTime(date.year, date.month, date.day)).inDays;
    return age >= 0 && age <= GoalConstants.diaryEditWindowDays;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final dates = HazriDates.of(context);
    final today = ref.watch(clockProvider).today();
    final rows = ref.watch(diaryDayRowsProvider(date)).value;
    final calendar = ref.watch(nanakshahiCalendarProvider).value;
    final nanakshahi = calendar?.dateFor(date);

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: PhoneWidth(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                HazriSize.gutter, 8, HazriSize.gutter, 24),
            children: [
              Row(
                children: [
                  CardIconButton(
                    icon: HazriIconData.chevronLeft,
                    size: 40,
                    iconSize: 20,
                    radius: 13,
                    tooltip: l.actionBack,
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go(Routes.diary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dates.longDate(date),
                          style: HazriText.display22
                              .copyWith(color: c.ink, fontSize: 24, height: 1.15),
                        ),
                        if (nanakshahi != null)
                          Text(
                            nanakshahi.labelWithYear(l.localeName),
                            style: HazriText.caption.copyWith(color: c.muted),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
              const SizedBox(height: 14),
              if (rows != null) ...[
                _HazriBanner(rows: rows),
                // 04-goals §7.5 (2): only on a day that had a goal.
                if (rows.verdict.goalState != GoalState.none) ...[
                  const SizedBox(height: 10),
                  _GoalBlock(rows: rows),
                ],
                const SizedBox(height: 14),
                _Recited(rows: rows),
                const SizedBox(height: 14),
                Eyebrow(l.diaryAddRemove),
                const SizedBox(height: 8),
                _EditCard(rows: rows, date: date, editable: isEditable(date, today)),
                const SizedBox(height: 14),
                HazriCard(
                  colour: c.card2,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppIcon(HazriIconData.check, size: 18, color: c.muted),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l.diaryHazriNote,
                          style: HazriText.bodySmall
                              .copyWith(color: c.ink2, fontSize: 12.5, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HazriBanner extends ConsumerWidget {
  const _HazriBanner({required this.rows});

  final DayRows rows;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final dates = HazriDates.of(context);
    final marked = rows.verdict.hazri;
    final ink = marked ? Colors.white : c.ink;

    // What marked the day, and when. Read from the completions rather than
    // the day summary, which knows that something happened and not what.
    final banis = ref.watch(banisProvider).value ?? const <Bani>[];
    final completions = rows.completions.where((x) => x.deletedAt == null);
    final sessions = rows.sittings.where(
        (x) => x.deletedAt == null && x.durationS >= GoalConstants.hazriSimranMinSeconds);
    DateTime? firstAt;
    String? firstWith;
    for (final x in completions) {
      final at = x.completedAt.toLocal();
      if (firstAt == null || at.isBefore(firstAt)) {
        firstAt = at;
        firstWith = banis
            .where((b) => b.id == x.baniId)
            .map((b) => b.name(l.localeName))
            .firstOrNull;
      }
    }
    for (final x in sessions) {
      final at = x.startedAt.toLocal();
      if (firstAt == null || at.isBefore(firstAt)) {
        firstAt = at;
        firstWith = l.hazriSimran;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(HazriRadius.card),
        color: marked ? null : c.card2,
        gradient: marked
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [c.kesri, const Color(0xFFB8560A)],
              )
            : null,
        boxShadow: marked ? null : c.shadows,
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: marked ? Colors.white.withValues(alpha: 0.17) : c.card,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: AppMark(
              size: 34,
              arcColor: marked ? Colors.white : c.muted,
              sunColor: marked ? Colors.white : c.muted,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  marked ? l.diaryHazriMarked : l.diaryNoHazri,
                  style: HazriText.display22.copyWith(color: ink, fontSize: 19),
                ),
                if (firstAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      firstWith == null
                          ? l.hazriMarkedAt(dates.time(firstAt))
                          : l.hazriMarkedAtWith(dates.time(firstAt), firstWith),
                      style: HazriText.bodySmall.copyWith(
                        color: marked
                            ? Colors.white.withValues(alpha: 0.9)
                            : c.muted,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The goal block (04-goals §7.5 (2)): the summary, then each item in
/// scope that day with its count and a tick when met.
class _GoalBlock extends ConsumerWidget {
  const _GoalBlock({required this.rows});

  final DayRows rows;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final v = rows.verdict;
    final met = v.goalState == GoalState.met;
    final banis = ref.watch(banisProvider).value ?? const <Bani>[];
    final items = rows.items.where((i) => inScope(i, rows.day)).toList();

    return HazriCard(
      colour: met ? c.sageSoft : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: met ? c.sage : c.rule, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Text(
                l.diaryGoalSummary(v.itemsMet, v.itemsInScope),
                style: HazriText.body.copyWith(color: c.ink, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.itemType == ItemType.simran
                          ? l.goalNaamSimran
                          : (banis.where((b) => b.id == item.baniId).firstOrNull?.name(l.localeName) ??
                              item.baniId ??
                              ''),
                      style: HazriText.body.copyWith(color: c.ink2),
                    ),
                  ),
                  Text(
                    item.itemType == ItemType.simran
                        ? l.goalTimesOfTarget(
                            itemProgress(item, rows.completions, rows.sittings) ~/ 60,
                            item.simranMinutes ?? GoalConstants.simranGoalMinutesMin)
                        : l.goalTimesOfTarget(
                            itemProgress(item, rows.completions, rows.sittings), item.timesPerDay),
                    style: HazriText.caption.copyWith(color: c.muted),
                  ),
                  const SizedBox(width: 8),
                  if (itemMet(item, rows.completions, rows.sittings))
                    AppIcon(HazriIconData.check, size: 16, color: c.sage)
                  else
                    const SizedBox(width: 16),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Every bani with a live completion that day, in or out of the goal, with
/// each completion's time and source; then the simran sittings (§7.5 (3)).
class _Recited extends ConsumerWidget {
  const _Recited({required this.rows});

  final DayRows rows;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final dates = HazriDates.of(context);
    final banis = ref.watch(banisProvider).value ?? const <Bani>[];
    final live = rows.completions.where((x) => x.deletedAt == null).toList()
      ..sort((a, b) => a.completedAt.compareTo(b.completedAt));
    final sittings = rows.sittings.where((x) => x.deletedAt == null).toList()
      ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
    if (live.isEmpty && sittings.isEmpty) return const SizedBox.shrink();

    final byBani = <String, List<Completion>>{};
    for (final x in live) {
      byBani.putIfAbsent(x.baniId, () => []).add(x);
    }

    String source(CompletionSource s) => switch (s) {
          CompletionSource.reader => l.diarySourceRead,
          CompletionSource.audio => l.diarySourceListened,
          CompletionSource.diary => l.diarySourceDiary,
          CompletionSource.restored => l.diarySourceRestored,
          CompletionSource.migrated => l.diarySourceMigrated,
        };
    String? sittingSource(SittingSource s) => switch (s) {
          SittingSource.timer => null,
          SittingSource.diary => l.diarySourceDiary,
          SittingSource.restored => l.diarySourceRestored,
          SittingSource.migrated => l.diarySourceMigrated,
        };

    final meta = HazriText.caption.copyWith(color: c.muted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Eyebrow(l.diaryRecited),
        const SizedBox(height: 8),
        HazriCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final MapEntry(key: id, value: list) in byBani.entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${banis.where((b) => b.id == id).firstOrNull?.name(l.localeName) ?? id} '
                        '${l.diaryCountTimes(list.length)}',
                        style: HazriText.bodyStrong.copyWith(color: c.ink),
                      ),
                      for (final x in list)
                        Text('${dates.time(x.completedAt.toLocal())} · ${source(x.source)}', style: meta),
                    ],
                  ),
                ),
              for (final s in sittings)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${l.goalNaamSimran} · ${l.minutes((s.durationS / 60).round())}',
                        style: HazriText.bodyStrong.copyWith(color: c.ink),
                      ),
                      Text(
                        [
                          dates.time(s.startedAt.toLocal()),
                          ?sittingSource(s.source),
                          if (!s.completed) l.diarySimranStoppedEarly,
                        ].join(' · '),
                        style: meta,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// + and − for every bani and Naam Simran (§7.5 (4), CR3, CR4). "+" adds one
/// completion or sitting on that day; "−" undoes the newest, whatever its
/// source. Older days are read-only and say so before anybody tries.
class _EditCard extends ConsumerWidget {
  const _EditCard({required this.rows, required this.date, required this.editable});

  final DayRows rows;
  final DateTime date;
  final bool editable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final repo = ref.read(userRepositoryProvider);
    final banis = ref.watch(banisProvider).value ?? const <Bani>[];
    final live = rows.completions.where((x) => x.deletedAt == null);
    final sittings = rows.sittings.where((x) => x.deletedAt == null);

    // A sitting added by hand says that it happened, not how long it was: the
    // in-scope simran item's length, never under the hazri minimum.
    final simranItem = rows.items
        .where((i) => i.itemType == ItemType.simran && inScope(i, rows.day))
        .firstOrNull;
    final sittingSeconds = math.max(
      GoalConstants.hazriSimranMinSeconds,
      (simranItem?.simranMinutes ?? GoalConstants.simranDefaultMinutes) * 60,
    );

    return HazriCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          for (final bani in banis)
            _CountRow(
              label: bani.name(l.localeName),
              count: live.where((x) => x.baniId == bani.id).length,
              onAdd: editable
                  ? () => repo.logCompletion(
                        baniId: bani.id,
                        slot: slotValueOf(bani.defaultSlot),
                        source: CompletionSource.diary,
                        on: date,
                      )
                  : null,
              onRemove: editable ? () => repo.undoLatestCompletion(bani.id, date) : null,
            ),
          _CountRow(
            label: l.goalNaamSimran,
            count: sittings.length,
            onAdd: editable
                ? () => repo.logSitting(
                      duration: Duration(seconds: sittingSeconds),
                      completed: true,
                      source: SittingSource.diary,
                      on: date,
                    )
                : null,
            onRemove: editable ? () => repo.undoLatestSitting(date) : null,
          ),
          if (!editable)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 12),
              child: Text(l.diaryReadOnly, style: HazriText.caption.copyWith(color: c.muted)),
            ),
        ],
      ),
    );
  }
}

/// The content slot as `user.db` stores it.
BaniSlotValue slotValueOf(BaniSlot slot) => switch (slot) {
      BaniSlot.morning => BaniSlotValue.morning,
      BaniSlot.evening => BaniSlotValue.evening,
      BaniSlot.bedtime => BaniSlotValue.bedtime,
      BaniSlot.none => BaniSlotValue.none,
    };

class _CountRow extends StatelessWidget {
  const _CountRow({
    required this.label,
    required this.count,
    required this.onAdd,
    required this.onRemove,
  });

  final String label;
  final int count;
  final Future<Object?> Function()? onAdd;
  final Future<Object?> Function()? onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    final editable = onAdd != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: HazriText.bodyStrong.copyWith(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: count > 0 ? c.ink : c.muted,
              ),
            ),
          ),
          if (editable)
            IconButton(
              tooltip: l.actionRemove,
              onPressed: count == 0 ? null : onRemove,
              icon: Text('−', style: HazriText.display22.copyWith(fontSize: 20, color: count == 0 ? c.rule : c.ink)),
            ),
          SizedBox(
            width: 28,
            child: Text('$count',
                textAlign: TextAlign.center,
                style: HazriText.captionStrong.copyWith(color: count > 0 ? c.ink : c.muted, fontSize: 14)),
          ),
          if (editable)
            IconButton(
              tooltip: l.actionAdd,
              onPressed: onAdd,
              icon: Text('+', style: HazriText.display22.copyWith(fontSize: 20, color: c.kesri)),
            ),
        ],
      ),
    );
  }
}
