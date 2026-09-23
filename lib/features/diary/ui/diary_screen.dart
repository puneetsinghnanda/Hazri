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
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/surfaces.dart';
import '../domain/streak.dart';
import '../../../app/menu_sheet.dart';
import '../../../core/widgets/tab_header.dart';

/// The month being shown in the diary.
final diaryMonthProvider = StateProvider<DateTime>((ref) {
  final today = ref.watch(clockProvider).today();
  return DateTime(today.year, today.month);
});

final diaryDaysProvider = FutureProvider<List<DiaryDay>>((ref) {
  // Rebuild whenever a completion or Simran session is written.
  ref.watch(userRepositoryProvider).watchCompletions();
  return ref.watch(userRepositoryProvider).diaryMonth(ref.watch(diaryMonthProvider));
});

final streakProvider = FutureProvider<StreakResult>(
  (ref) => ref.watch(userRepositoryProvider).streak(),
);

/// One day, for design 56.
///
/// Derived from the month it falls in rather than queried on its own, so the
/// grace day and the goals-met flag are worked out by exactly the code the
/// grid uses. It is a local SQLite read either way.
final diaryDayProvider = FutureProvider.family<DiaryDay?, DateTime>((ref, date) async {
  ref.watch(userRepositoryProvider).watchCompletions();
  final month = await ref
      .watch(userRepositoryProvider)
      .diaryMonth(DateTime(date.year, date.month));
  return month.where((d) => d.date.day == date.day).firstOrNull;
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
    final days = ref.watch(diaryDaysProvider).value ?? const <DiaryDay>[];
    final streak = ref.watch(streakProvider).value;

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
                onMenu: () => showMenuSheet(context),
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
              const SizedBox(height: 14),
              _StreakCard(streak: streak),
              const SizedBox(height: 14),
              _MonthGrid(month: month, days: days),
              const SizedBox(height: 14),
              _MonthStats(days: days),
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

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.streak});

  final StreakResult? streak;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    final days = streak?.days ?? 0;

    return HazriCard(
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: c.kesriSoft,
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: AppIcon(HazriIconData.sunArc, size: 30, color: c.kesriInk),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // The number is in the sentence rather than beside it. A
                // 44-point numeral with a caption under it read as a score.
                Text(
                  days == 0
                      ? l.diaryStreakNone
                      : (days == 1 ? l.diaryStreakOne : l.diaryStreakDays(days)),
                  style: HazriText.display22.copyWith(color: c.ink, fontSize: 23),
                ),
                const SizedBox(height: 1),
                Text(
                  '${l.diaryGentleStreak} · '
                  '${l.diaryGrace(streak?.graceLeftThisMonth ?? StreakCalculator.gracePerMonth)}',
                  style: HazriText.caption.copyWith(color: c.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthGrid extends ConsumerWidget {
  const _MonthGrid({required this.month, required this.days});

  final DateTime month;
  final List<DiaryDay> days;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final today = ref.watch(clockProvider).today();
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
            itemCount: leading + days.length,
            itemBuilder: (context, i) {
              if (i < leading) return const SizedBox.shrink();
              final day = days[i - leading];
              return _DayCell(
                day: day,
                isToday: day.date == today,
                isFuture: day.date.isAfter(today),
                onTap: () => _openDay(context, ref, day.date),
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
                (l.diaryHazriDot, c.kesri),
                if (days.any((d) => d.hasGoals)) (l.diaryGoalsDot, c.sage),
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
    required this.day,
    required this.isToday,
    required this.isFuture,
    required this.onTap,
  });

  final DiaryDay day;
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
    final dots = [
      (day.hazri, c.kesri),
      if (day.hasGoals) (day.goalsMet, c.sage),
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
              '${day.date.day}',
              style: HazriText.caption.copyWith(
                color: isFuture ? c.muted.withValues(alpha: 0.5) : c.ink,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 3),
            if (day.isGrace)
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
  const _MonthStats({required this.days});

  final List<DiaryDay> days;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);

    // The same two things the dots count, so the month reads one way.
    final hazriDays = days.where((d) => d.hazri).length;
    final goalsMet = days.where((d) => d.goalsMet).length;

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
