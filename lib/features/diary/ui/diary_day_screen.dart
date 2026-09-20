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
                Eyebrow(l.diaryWhatYouDid),
                const SizedBox(height: 4),
                Text(
                  l.diaryTickAnything,
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

/// The nitnem banis and simran, each with what the diary knows about it.
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
    final banis = ref.watch(banisProvider).value ?? const <Bani>[];
    final nitnem = banis.where((b) => b.category == 'nitnem').toList();
    final completions =
        ref.watch(completionsOnProvider(day.date)).value ?? const <Completion>[];
    final sessions = (ref.watch(simranSessionsProvider).value ?? const [])
        .where((x) => x.localDate == localDateKey(day.date) && x.completed)
        .toList();
    final goals = ref.watch(goalProgressProvider).value ?? const [];

    /// When a goal for this bani asks to be sat, or null. The design's
    /// "not yet · 6:40 PM" — the only time the app actually knows for a bani
    /// it has no record of.
    String? dueAt(String baniId) => goals
        .where((g) => g.goal.baniId == baniId && g.goal.active)
        .map((g) => g.goal.reminderTime)
        .whereType<String>()
        .firstOrNull;

    String metaFor(String baniId) {
      final at = completions
          .where((x) => x.baniId == baniId)
          .map((x) => x.completedAt.toLocal())
          .fold<DateTime?>(null, (a, b) => a == null || b.isBefore(a) ? b : a);
      if (at != null) return dates.time(at);
      final due = dueAt(baniId);
      final asTime = HazriDates.atOnDay(due, day.date);
      return asTime == null ? l.diaryNotYet : l.diaryNotYetAt(dates.time(asTime));
    }

    final simranMinutes =
        (sessions.fold<int>(0, (sum, x) => sum + x.durationS) / 60).round();

    Future<void> setBani(Bani bani, bool value) async {
      final slot = _slotValue(bani.defaultSlot);
      if (value) {
        await repo.logCompletion(
          baniId: bani.id,
          slot: slot,
          source: CompletionSource.manual,
          on: day.date,
        );
        // Ticking a bani here counts towards its goals exactly as reading or
        // listening to it does.
        await repo.creditGoalsFor(bani.id, on: day.date);
      } else {
        await repo.removeCompletion(baniId: bani.id, slot: slot, on: day.date);
        await repo.removeGoalCreditFor(bani.id, on: day.date);
      }
      ref.invalidate(diaryDayProvider);
      ref.invalidate(diaryDaysProvider);
      ref.invalidate(streakProvider);
    }

    // A sitting ticked by hand says that it happened, not how long it was.
    // The goal's length is the best guess there is, and a hardcoded five
    // minutes was wrong for everybody who set a goal of eleven.
    final tickedLength = ref.watch(simranGoalMinutesProvider) ??
        ref.watch(settingsProvider).simranMinutes;

    Future<void> setSimran(bool value) async {
      if (value) {
        await repo.logSimran(
          duration: Duration(minutes: tickedLength),
          count: 0,
          completed: true,
          on: day.date,
        );
      } else {
        await repo.removeSimranOn(day.date);
      }
      ref.invalidate(diaryDayProvider);
      ref.invalidate(diaryDaysProvider);
      ref.invalidate(streakProvider);
    }

    return HazriCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          for (final bani in nitnem)
            _TickRow(
              label: bani.name(l.localeName),
              meta: metaFor(bani.id),
              checked: day.slots.contains(_slotValue(bani.defaultSlot)),
              onChanged: editable ? (v) => setBani(bani, v) : null,
            ),
          _TickRow(
            label: l.hazriSimran,
            meta: day.simran && simranMinutes > 0
                ? l.minutes(simranMinutes)
                : (day.simran ? dates.time(sessions.first.startedAt.toLocal()) : l.diaryNotYet),
            checked: day.simran,
            onChanged: editable ? setSimran : null,
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
  });

  final String label;
  final String meta;
  final bool checked;
  final ValueChanged<bool>? onChanged;

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
            ],
          ),
        ),
      ),
    );
  }
}

/// Design 56's three numbers, divided rather than carded separately.
class _DayStats extends ConsumerWidget {
  const _DayStats({required this.day});

  final DiaryDay day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final streak = ref.watch(streakProvider).value;
    final minutes = ((ref.watch(simranSessionsProvider).value ?? const [])
                .where((x) => x.localDate == localDateKey(day.date) && x.completed)
                .fold<int>(0, (sum, x) => sum + x.durationS) /
            60)
        .round();

    final stats = [
      ('${day.slots.length}', l.diaryStatPaath),
      ('$minutes', l.diaryStatSimranMinutes),
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
