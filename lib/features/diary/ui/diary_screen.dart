import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
import '../../../core/widgets/surfaces.dart';
import '../../nitnem/domain/bani.dart';
import '../domain/streak.dart';

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
            padding: const EdgeInsets.fromLTRB(HazriSize.gutter, 20, HazriSize.gutter, 20),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l.diaryTitle,
                      style: HazriText.display26.copyWith(color: c.ink),
                    ),
                  ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$days', style: HazriText.display44.copyWith(color: c.kesriInk)),
              Text(
                days == 1 ? l.diaryStreakOne : l.diaryStreakDays(days),
                style: HazriText.caption.copyWith(color: c.muted),
              ),
            ],
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  days == 0 ? l.diaryStreakNone : l.diaryGentleStreak,
                  style: HazriText.bodyStrong.copyWith(color: c.ink),
                ),
                const SizedBox(height: 4),
                Text(
                  l.diaryGrace(streak?.graceLeftThisMonth ?? StreakCalculator.gracePerMonth),
                  style: HazriText.bodySmall.copyWith(color: c.ink2),
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
                onTap: () => _showTickSheet(context, ref, day),
              );
            },
          ),
          const SizedBox(height: 10),
          // A Wrap rather than a Row: the three slot names are much longer in
          // Punjabi and Hindi than in English.
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 4,
            children: [
              for (final (label, colour) in [
                (l.slotAmritVela, c.kesri),
                (l.diaryStatRehras, c.teal),
                (l.diaryStatSohila, c.sage),
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

  /// Today and the last seven days can be ticked by hand (PRD 1.9).
  Future<void> _showTickSheet(BuildContext context, WidgetRef ref, DiaryDay day) async {
    final today = ref.read(clockProvider).today();
    final age = today.difference(day.date).inDays;
    final l = L.of(context);
    if (age < 0 || age > 7) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.diaryTickTooOld)),
      );
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (_) => _TickSheet(day: day),
    );
    ref.invalidate(diaryDaysProvider);
    ref.invalidate(streakProvider);
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
    final segments = [
      (BaniSlotValue.morning, c.kesri),
      (BaniSlotValue.evening, c.teal),
      (BaniSlotValue.bedtime, c.sage),
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
                  for (final (slot, colour) in segments)
                    Container(
                      width: 6,
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: day.slots.contains(slot) ? colour : c.rule,
                        borderRadius: BorderRadius.circular(2),
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

class _TickSheet extends ConsumerWidget {
  const _TickSheet({required this.day});

  final DiaryDay day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final dates = HazriDates.of(context);
    final banis = ref.watch(banisProvider).value ?? const <Bani>[];
    final nitnem = banis.where((b) => b.category == 'nitnem').toList();
    final repo = ref.read(userRepositoryProvider);

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(HazriSize.gutter, 12, HazriSize.gutter, 20),
        child: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: c.rule,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                dates.longDate(day.date),
                style: HazriText.display22.copyWith(color: c.ink),
              ),
              const SizedBox(height: 4),
              Text(l.diaryTickHint, style: HazriText.bodySmall.copyWith(color: c.muted)),
              const SizedBox(height: 12),
              for (final bani in nitnem)
                _TickRow(
                  label: bani.name(l.localeName),
                  checked: day.slots.contains(_slotValue(bani.defaultSlot)),
                  onChanged: (value) async {
                    final slot = _slotValue(bani.defaultSlot);
                    if (value) {
                      await repo.logCompletion(
                        baniId: bani.id,
                        slot: slot,
                        source: CompletionSource.manual,
                        on: day.date,
                      );
                      day.slots.add(slot);
                    } else {
                      await repo.removeCompletion(
                        baniId: bani.id,
                        slot: slot,
                        on: day.date,
                      );
                      day.slots.remove(slot);
                    }
                    setState(() {});
                  },
                ),
              _TickRow(
                label: l.simranTitle,
                checked: day.simran,
                onChanged: (value) async {
                  if (value) {
                    await repo.logSimran(
                      duration: const Duration(minutes: 5),
                      count: 0,
                      completed: true,
                      on: day.date,
                    );
                  } else {
                    await repo.removeSimranOn(day.date);
                  }
                  setState(() {});
                },
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: l.actionDone,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
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
  const _TickRow({required this.label, required this.checked, required this.onChanged});

  final String label;
  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: () => onChanged(!checked),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(child: Text(label, style: HazriText.body.copyWith(color: c.ink))),
            Checkbox(value: checked, onChanged: (v) => onChanged(v ?? false)),
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

    final morning = days.where((d) => d.slots.contains(BaniSlotValue.morning)).length;
    final evening = days.where((d) => d.slots.contains(BaniSlotValue.evening)).length;
    final bedtime = days.where((d) => d.slots.contains(BaniSlotValue.bedtime)).length;
    final simran = days.where((d) => d.simran).length;

    final stats = [
      (morning, l.diaryStatJapji),
      (evening, l.diaryStatRehras),
      (bedtime, l.diaryStatSohila),
      (simran, l.diaryStatSimran),
    ];

    return HazriCard(
      child: Row(
        children: [
          for (final (value, label) in stats)
            Expanded(
              child: Column(
                children: [
                  Text('$value', style: HazriText.display22.copyWith(color: c.ink)),
                  Text(label, style: HazriText.caption.copyWith(color: c.muted)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
