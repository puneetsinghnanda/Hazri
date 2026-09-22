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
import '../../../core/settings/settings_controller.dart';
import '../../goals/data/goals_controller.dart';
import '../../goals/domain/goal_progress.dart';
import '../../hazri/data/hazri_controller.dart';
import '../../nitnem/domain/bani.dart';
import 'diary_screen.dart';

/// One day in the diary (design 56).
///
/// A pushed screen inside the Diary branch, not a bottom sheet: design 56 is
/// a whole screen with the bottom nav still under it, and a sheet cut the
/// stats and the note off the bottom of a small phone.
class DiaryDayScreen extends ConsumerWidget {
  const DiaryDayScreen({super.key, required this.date});

  final DateTime date;

  /// Today and the last seven days can be ticked by hand (PRD 1.9).
  static bool isEditable(DateTime date, DateTime today) {
    final age = today.difference(DateTime(date.year, date.month, date.day)).inDays;
    return age >= 0 && age <= 7;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final dates = HazriDates.of(context);
    final today = ref.watch(clockProvider).today();
    final day = ref.watch(diaryDayProvider(date)).value;
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
              if (day != null) ...[
                _HazriBanner(day: day),
                const SizedBox(height: 14),
                Eyebrow(l.diaryHazriAndGoals),
                const SizedBox(height: 4),
                Text(
                  l.diaryTickGoals,
                  style: HazriText.caption.copyWith(color: c.muted),
                ),
                const SizedBox(height: 8),
                _TickCard(day: day, editable: isEditable(date, today)),
                const SizedBox(height: 14),
                _DayStats(day: day),
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

/// Design 56's banner: kesri and filled when the day was marked, quiet and
/// grey when it was not, because a day without one is not a day to be shouted
/// at about.
class _HazriBanner extends ConsumerWidget {
  const _HazriBanner({required this.day});

  final DiaryDay day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final dates = HazriDates.of(context);
    final marked = day.hazri;
    final ink = marked ? Colors.white : c.ink;

    // What marked the day, and when. Read from the completions rather than
    // the day summary, which knows that something happened and not what.
    final banis = ref.watch(banisProvider).value ?? const <Bani>[];
    final completions =
        ref.watch(completionsOnProvider(day.date)).value ?? const <Completion>[];
    final sessions = (ref.watch(simranSessionsProvider).value ?? const [])
        .where((x) => x.localDate == localDateKey(day.date) && x.completed);
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
                  marked ? l.hazriMarked : l.hazriNotYet,
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

/// The goals that were running on one day, with that day's ticks.
///
/// Worked out against [date] rather than today, so a goal that ended last
/// week still shows on the days it covered and a goal made yesterday is not
/// on the days before it. Every goal with a start date on or before the day
/// counts, paused or not, which is the same rule the month grid's second dot
/// uses in `diaryMonth`.
final diaryGoalsProvider =
    StreamProvider.family<List<GoalProgress>, DateTime>((ref, date) {
  final key = localDateKey(date);
  return ref.watch(userRepositoryProvider).watchGoalsAndTicks(date).map((data) => [
        for (final g in data.goals)
          if (g.startDate.compareTo(key) <= 0)
            GoalCalculator.progressFor(goal: g, ticksToday: data.ticks, today: date),
      ]..removeWhere((p) => p.isComplete));
});

/// The hazri and the goals, and nothing else.
///
/// This card used to list every nitnem bani with a tick beside it, which made
/// the diary a checklist of seven paaths nobody had set themselves. The reader
/// asked for the diary to be about two things: whether the day's hazri was
/// marked -- which any paath or sitting of simran does -- and whether the
/// goals they chose were met. So the first row is the hazri, and the rows
/// under it are the goals that were running that day.
///
/// The hazri row can be ticked by hand for a paath read away from the phone;
/// once a real paath or sitting has marked the day it is shown and not
/// offered, because unticking it would mean deleting that record.
class _TickCard extends ConsumerWidget {
  const _TickCard({required this.day, required this.editable});

  final DiaryDay day;
  final bool editable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final dates = HazriDates.of(context);
    final repo = ref.read(userRepositoryProvider);
    final today = ref.watch(clockProvider).today();
    final banis = ref.watch(banisProvider).value ?? const <Bani>[];
    final completions =
        ref.watch(completionsOnProvider(day.date)).value ?? const <Completion>[];
    final sessions = (ref.watch(simranSessionsProvider).value ?? const [])
        .where((x) => x.localDate == localDateKey(day.date) && x.completed)
        .toList();
    final goals = ref.watch(diaryGoalsProvider(day.date)).value ?? const [];

    void refresh() {
      ref.invalidate(diaryDayProvider);
      ref.invalidate(diaryDaysProvider);
      ref.invalidate(streakProvider);
    }

    // ---------------------------------------------------------------- hazri

    // What marked the day, if anything did, and whether a real paath or
    // sitting is among it -- the hand mark is the one thing this row is
    // allowed to take back.
    final byPaathOrSimran =
        completions.any((x) => x.baniId != kHazriMarkId) || sessions.isNotEmpty;
    DateTime? markedAt;
    for (final x in completions) {
      final at = x.completedAt.toLocal();
      if (markedAt == null || at.isBefore(markedAt)) markedAt = at;
    }
    for (final x in sessions) {
      final at = x.startedAt.toLocal();
      if (markedAt == null || at.isBefore(markedAt)) markedAt = at;
    }

    Future<void> setHazri(bool value) async {
      if (value) {
        await repo.logCompletion(
          baniId: kHazriMarkId,
          slot: BaniSlotValue.none,
          source: CompletionSource.manual,
          on: day.date,
        );
      } else {
        await repo.removeCompletion(
            baniId: kHazriMarkId, slot: BaniSlotValue.none, on: day.date);
      }
      refresh();
    }

    // ---------------------------------------------------------------- goals

    String nameOf(Goal goal) => goal.baniId == kSimranGoalId
        ? l.hazriSimran
        : (banis
                .where((b) => b.id == goal.baniId)
                .map((b) => b.name(l.localeName))
                .firstOrNull ??
            '');

    /// When the goal asks to be sat, on this day, or null.
    DateTime? dueAt(Goal goal) => HazriDates.atOnDay(goal.reminderTime, day.date);

    String metaFor(GoalProgress p) {
      final goal = p.goal;
      if (goal.timesPerDay > 1) return l.nOfM(p.doneToday, goal.timesPerDay);
      if (p.isDoneToday) {
        if (goal.baniId == kSimranGoalId) {
          final minutes =
              (sessions.fold<int>(0, (sum, x) => sum + x.durationS) / 60).round();
          if (minutes > 0) return l.minutes(minutes);
          if (sessions.isNotEmpty) {
            return dates.time(sessions.first.startedAt.toLocal());
          }
        }
        final at = completions
            .where((x) => x.baniId == goal.baniId)
            .map((x) => x.completedAt.toLocal())
            .fold<DateTime?>(null, (a, b) => a == null || b.isBefore(a) ? b : a);
        if (at != null) return dates.time(at);
        return l.goalStatusDone;
      }
      final due = dueAt(goal);
      return due == null ? l.diaryNotYet : l.diaryNotYetAt(dates.time(due));
    }

    // A sitting ticked by hand says that it happened, not how long it was.
    // The goal's own length is the best guess there is.
    final tickedLength = ref.watch(simranGoalMinutesProvider) ??
        ref.watch(settingsProvider).simranMinutes;

    Future<void> tickGoal(GoalProgress p) async {
      final goal = p.goal;
      if (goal.baniId == kSimranGoalId) {
        // logSimran credits the goal itself.
        await repo.logSimran(
          duration: Duration(minutes: goal.minutes ?? tickedLength),
          count: 0,
          completed: true,
          on: day.date,
        );
      } else {
        final bani = banis.where((b) => b.id == goal.baniId).firstOrNull;
        // The paath is recorded as read, which is what marks the hazri, and
        // this one goal gets its tick -- not every goal for the bani, which
        // is what reading it does and what somebody tapping one row did not
        // ask for.
        await repo.logCompletion(
          baniId: goal.baniId,
          slot: bani == null ? BaniSlotValue.none : _slotValue(bani.defaultSlot),
          source: CompletionSource.manual,
          on: day.date,
        );
        await repo.tickGoal(goal.id, on: day.date);
      }
      refresh();
    }

    Future<void> untickGoal(GoalProgress p) async {
      final goal = p.goal;
      if (goal.baniId == kSimranGoalId) {
        await repo.removeSimranOn(day.date);
      } else {
        await repo.untickGoal(goal.id, on: day.date);
        // The last tick going takes the paath's record with it, so the hazri
        // is not left standing on a day with nothing behind it. Another goal
        // for the same bani still ticked keeps it.
        final othersTicked = goals.any((q) =>
            q.goal.id != goal.id &&
            q.goal.baniId == goal.baniId &&
            q.doneToday > 0);
        if (p.doneToday <= 1 && !othersTicked) {
          final bani = banis.where((b) => b.id == goal.baniId).firstOrNull;
          await repo.removeCompletion(
            baniId: goal.baniId,
            slot: bani == null ? BaniSlotValue.none : _slotValue(bani.defaultSlot),
            on: day.date,
          );
        }
      }
      refresh();
    }

    return HazriCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          _TickRow(
            label: l.diaryHazriDot,
            meta: markedAt == null ? l.diaryNotYet : dates.time(markedAt),
            checked: day.hazri,
            // Offered only while the hand mark is all there is to take back.
            onChanged: editable && !byPaathOrSimran ? setHazri : null,
          ),
          Divider(height: 1, color: c.rule),
          for (final p in goals)
            _TickRow(
              label: nameOf(p.goal),
              meta: metaFor(p),
              checked: p.isDoneToday,
              onChanged: !editable
                  ? null
                  : (v) => v ? tickGoal(p) : untickGoal(p),
              // A goal sat more than once a day counts up on each tap and
              // needs a way back down that does not go through "done".
              onRemove: editable && p.goal.timesPerDay > 1 && p.doneToday > 0
                  ? () => untickGoal(p)
                  : null,
            ),
          if (goals.isEmpty)
            day.date == today
                ? InkWell(
                    onTap: () => context.push(Routes.goals),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              l.goalsEmptyTitle,
                              style: HazriText.bodyStrong.copyWith(
                                  fontSize: 14.5, color: c.kesriInk),
                            ),
                          ),
                          AppIcon(HazriIconData.chevronRight,
                              size: 18, color: c.muted),
                        ],
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      l.diaryNoGoalsThatDay,
                      style: HazriText.caption.copyWith(color: c.muted),
                    ),
                  ),
          if (!editable)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 12),
              child: Text(
                l.diaryTickTooOld,
                style: HazriText.caption.copyWith(color: c.muted),
              ),
            ),
        ],
      ),
    );
  }

  static BaniSlotValue _slotValue(BaniSlot slot) => switch (slot) {
        BaniSlot.morning => BaniSlotValue.morning,
        BaniSlot.evening => BaniSlotValue.evening,
        BaniSlot.bedtime => BaniSlotValue.bedtime,
        BaniSlot.none => BaniSlotValue.none,
      };
}

class _TickRow extends StatelessWidget {
  const _TickRow({
    required this.label,
    required this.meta,
    required this.checked,
    required this.onChanged,
    this.onRemove,
  });

  final String label;
  final String meta;
  final bool checked;
  final ValueChanged<bool>? onChanged;

  /// One step back for a goal counted more than once a day.
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      checked: checked,
      child: InkWell(
        onTap: onChanged == null ? null : () => onChanged!(!checked),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: checked ? c.sage : null,
                  shape: BoxShape.circle,
                  border: checked ? null : Border.all(color: c.rule, width: 2),
                ),
                alignment: Alignment.center,
                child: checked
                    ? const AppIcon(HazriIconData.check,
                        size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: HazriText.bodyStrong.copyWith(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: checked ? c.ink : c.muted,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                meta,
                style: HazriText.captionStrong
                    .copyWith(color: c.muted, fontSize: 12.5),
              ),
              if (onRemove != null) ...[
                const SizedBox(width: 6),
                // The same glyph the goal stepper uses, since the design
                // system has no minus icon of its own.
                Tooltip(
                  message: L.of(context).actionRemove,
                  child: Material(
                    color: c.card2,
                    borderRadius: BorderRadius.circular(9),
                    child: InkWell(
                      onTap: onRemove,
                      borderRadius: BorderRadius.circular(9),
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: Center(
                          child: Text(
                            '−',
                            style: HazriText.bodyStrong.copyWith(color: c.ink),
                          ),
                        ),
                      ),
                    ),
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

/// The day's two numbers: the goals met, and the run of days.
///
/// Design 56 had three -- paath, simran minutes, days in a row -- and the
/// first two counted things the diary no longer lists. What is left is what
/// the two dots on the month grid say, one number each.
class _DayStats extends ConsumerWidget {
  const _DayStats({required this.day});

  final DiaryDay day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final streak = ref.watch(streakProvider).value;
    final goals = ref.watch(diaryGoalsProvider(day.date)).value ?? const [];
    final met = goals.where((p) => p.isDoneToday).length;

    final stats = [
      (goals.isEmpty ? '—' : l.nOfM(met, goals.length), l.diaryStatGoalsMet),
      ('${streak?.days ?? 0}', l.diaryStatDaysInRow),
    ];

    return HazriCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < stats.length; i++) ...[
              if (i > 0) VerticalDivider(width: 1, thickness: 1, color: c.rule),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      stats[i].$1,
                      style: HazriText.display22.copyWith(color: c.ink, fontSize: 21),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      stats[i].$2,
                      textAlign: TextAlign.center,
                      style: HazriText.captionStrong
                          .copyWith(color: c.muted, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
