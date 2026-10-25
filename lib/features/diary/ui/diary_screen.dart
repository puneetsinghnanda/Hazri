import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/db/user_repository.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/time/clock.dart';
import '../../../core/time/date_format.dart';
import '../../../core/widgets/surfaces.dart';
import '../../goals/domain/day_verdict.dart';
import '../../../app/menu_sheet.dart';
import '../../../core/widgets/tab_header.dart';

/// The month being shown in the diary.
final diaryMonthProvider = StateProvider<DateTime>((ref) {
  final today = ref.watch(clockProvider).today();
  return DateTime(today.year, today.month);
});

/// The month's live rows; both dots of every day come from
/// [MonthRows.verdict] (09-diary D4).
final diaryMonthRowsProvider = StreamProvider<MonthRows>(
  (ref) => ref.watch(userRepositoryProvider).watchMonth(ref.watch(diaryMonthProvider)),
);

/// The streak card's two numbers (D12), recomputed whenever a completion is
/// written.
final hazriStreakProvider = FutureProvider<HazriStreak>((ref) async {
  ref.watch(_completionsTick);
  // A sitting of 5 minutes marks hazri too (D9).
  ref.watch(_sittingsTick);
  return ref.watch(userRepositoryProvider).hazriStreak();
});

final _sittingsTick = StreamProvider<int>(
  (ref) => ref.watch(userRepositoryProvider).watchSittings().map((s) => s.length),
);

final _completionsTick = StreamProvider<int>(
  (ref) => ref.watch(userRepositoryProvider).watchCompletions().map((c) => c.length),
);

/// DV3: no dots before the first recorded day.
final firstRecordedDayProvider = FutureProvider<String?>((ref) async {
  ref.watch(_completionsTick);
  return ref.watch(userRepositoryProvider).firstRecordedDay();
});

/// Grace days spent, for the grid's quiet label (Y-j).
final graceDaysProvider = FutureProvider<Set<String>>((ref) async {
  await ref.watch(hazriStreakProvider.future);
  return ref.watch(userRepositoryProvider).graceDayKeys();
});

/// The Nitnem Diary (Design 26).
///
/// The streak is gentle by design: grace days quietly bridge a missed day and
/// nothing here ever scolds (PRD 1.9).
class DiaryScreen extends ConsumerWidget {
  const DiaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final dates = HazriDates.of(context);
    final month = ref.watch(diaryMonthProvider);
    final rows = ref.watch(diaryMonthRowsProvider).value;
    final streak = ref.watch(hazriStreakProvider).value ?? HazriStreak.zero;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: PhoneWidth(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(HazriSize.gutter, 0, HazriSize.gutter, 20),
            children: [
              TabHeader(
                title: l.diaryTitle,
                subtitle: l.diarySubtitle,
                onMenu: () => showMenuDrawer(context),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  // The screen's name is in the header above; this row is
                  // only the month picker, and the month is already in the
                  // middle of it.
                  const Spacer(),
                  CardIconButton(
                    icon: HazriIconData.chevronLeft,
                    iconSize: 18,
                    size: 36,
                    background: c.card2,
                    tooltip: l.actionBack,
                    onPressed: () => ref.read(diaryMonthProvider.notifier).state =
                        DateTime(month.year, month.month - 1),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      dates.monthYear(month),
                      style: HazriText.captionStrong.copyWith(color: c.ink),
                    ),
                  ),
                  CardIconButton(
                    icon: HazriIconData.chevronRight,
                    iconSize: 18,
                    size: 36,
                    background: c.card2,
                    tooltip: l.actionNext,
                    onPressed: () => ref.read(diaryMonthProvider.notifier).state =
                        DateTime(month.year, month.month + 1),
                  ),
                ],
              ),
              // D12: hidden while both numbers are under 2.
              if (streak.longest >= 2) ...[
                const SizedBox(height: 14),
                DiaryStreakCard(streak: streak),
              ],
              const SizedBox(height: 14),
              if (rows != null) ...[
                _MonthGrid(month: month, rows: rows),
                const SizedBox(height: 14),
                _MonthStats(month: month, rows: rows),
              ],
              const SizedBox(height: 14),
              Text(
                l.diaryFooter,
                textAlign: TextAlign.center,
                style: HazriText.caption.copyWith(color: c.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Design 87: now and longest, divided by a rule (09-diary D12). Only the
/// longest half while the run now is under 2; nothing ever says a streak
/// ended, and grace days are never mentioned.
class DiaryStreakCard extends StatelessWidget {
  const DiaryStreakCard({super.key, required this.streak});

  final HazriStreak streak;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    Widget half(int n, String label, Color colour) => Expanded(
          child: Column(
            children: [
              Text('$n', style: HazriText.display22.copyWith(color: colour, fontSize: 30)),
              const SizedBox(height: 2),
              Text(label,
                  textAlign: TextAlign.center,
                  style: HazriText.caption.copyWith(color: c.muted, fontWeight: FontWeight.w600)),
            ],
          ),
        );
    return HazriCard(
      child: Row(
        children: [
          if (streak.current >= 2) ...[
            half(streak.current, l.diaryStreakNow, c.kesri),
            Container(width: 1, height: 44, color: c.rule),
          ],
          half(streak.longest, l.diaryStreakLongest, c.ink),
        ],
      ),
    );
  }
}

class _MonthGrid extends ConsumerWidget {
  const _MonthGrid({required this.month, required this.rows});

  final DateTime month;
  final MonthRows rows;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final today = ref.watch(clockProvider).today();
    final first = ref.watch(firstRecordedDayProvider).value;
    final grace = ref.watch(graceDaysProvider).value ?? const <String>{};
    final length = DateTime(month.year, month.month + 1, 0).day;
    final labels = [l.dayMon, l.dayTue, l.dayWed, l.dayThu, l.dayFri, l.daySat, l.daySun];

    // Monday-first grid, with blanks before the first of the month.
    final leading = DateTime(month.year, month.month, 1).weekday - 1;

    return HazriCard(
      child: Column(
        children: [
          Row(
            children: [
              for (final label in labels)
                Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: HazriText.caption.copyWith(color: c.muted),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.78,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: leading + length,
            itemBuilder: (context, i) {
              if (i < leading) return const SizedBox.shrink();
              final date = DateTime(month.year, month.month, i - leading + 1);
              final key = localDateKey(date);
              final future = date.isAfter(today);
              final beforeFirst = first == null || key.compareTo(first) < 0;
              return _DayCell(
                date: date,
                verdict: future || beforeFirst ? null : rows.verdict(date),
                isGrace: grace.contains(key),
                isToday: date == today,
                isFuture: future,
                onTap: () => _openDay(context, ref, date),
              );
            },
          ),
          const SizedBox(height: 10),
          // A Wrap rather than a Row: the names are much longer in Punjabi
          // and Hindi than in English. The goals entry appears only if some
          // day this month actually had a goal, so the legend explains the
          // dots that are on screen rather than one that is not.
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 4,
            children: [
              for (final (label, colour) in [
                (l.diaryLegendHazri, c.kesri),
                if (rows.anyGoalDay) (l.diaryLegendGoal, c.sage),
              ])
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: colour, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Text(label, style: HazriText.caption.copyWith(color: c.muted)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Opens design 56 — a pushed screen, not a sheet.
  ///
  /// A day older than a week still opens: it is a diary, and a day worth
  /// looking back at is not a day to be refused with a snackbar. What it
  /// cannot do is change, and the screen says so rather than a toast saying
  /// it on the way in (PRD 1.9).
  void _openDay(BuildContext context, WidgetRef ref, DateTime date) {
    final today = ref.read(clockProvider).today();
    if (date.isAfter(today)) return;
    context.push(Routes.diaryDay(date));
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.verdict,
    required this.isGrace,
    required this.isToday,
    required this.isFuture,
    required this.onTap,
  });

  final DateTime date;

  /// Null for a day with no dots: future, or before the first recorded day.
  final DayVerdict? verdict;
  final bool isGrace;
  final bool isToday;
  final bool isFuture;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // One dot for hazri -- did somebody turn up at all -- and a second only
    // on a day that actually had goals. A day before anybody set one, or
    // after the last one ran out, is not a day anybody failed, and a grey
    // second dot on it says the opposite. So: one dot means nothing was
    // asked, two mean something was, lit or not.
    final v = verdict;
    final dots = [
      if (v != null) (v.hazri, c.kesri),
      if (v != null && v.goalState != GoalState.none) (v.goalState == GoalState.met, c.sage),
    ];

    return InkWell(
      onTap: isFuture ? null : onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: isToday ? Border.all(color: c.kesri, width: 1.5) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: HazriText.caption.copyWith(
                color: isFuture ? c.muted.withValues(alpha: 0.5) : c.ink,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 3),
            if (isGrace && !(v?.hazri ?? false))
              Text(
                L.of(context).diaryGraceLabel,
                style: HazriText.caption.copyWith(fontSize: 7, color: c.muted),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final (lit, colour) in dots)
                    Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: lit ? colour : c.rule,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _MonthStats extends ConsumerWidget {
  const _MonthStats({required this.month, required this.rows});

  final DateTime month;
  final MonthRows rows;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);

    // The same two things the dots count, so the month reads one way.
    final today = ref.watch(clockProvider).today();
    final verdicts = [
      for (var d = 1; d <= DateTime(month.year, month.month + 1, 0).day; d++)
        if (!DateTime(month.year, month.month, d).isAfter(today))
          rows.verdict(DateTime(month.year, month.month, d)),
    ];
    final hazriDays = verdicts.where((v) => v.hazri).length;
    final goalsMet = verdicts.where((v) => v.goalState == GoalState.met).length;

    final stats = [
      (hazriDays, l.diaryStatHazriDays, c.kesri),
      (goalsMet, l.diaryStatGoalsMet, c.sage),
    ];

    return HazriCard(
      child: Row(
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            if (i > 0)
              Container(width: 1, height: 38, color: c.rule),
            Expanded(
              child: Column(
                children: [
                  Text(
                    '${stats[i].$1}',
                    style: HazriText.display22.copyWith(
                        color: stats[i].$3, fontSize: 21),
                  ),
                  Text(
                    stats[i].$2,
                    textAlign: TextAlign.center,
                    style: HazriText.caption
                        .copyWith(color: c.muted, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
