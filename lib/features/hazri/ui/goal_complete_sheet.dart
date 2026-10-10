import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/db/content_repository.dart';
import '../../../core/db/user_db.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/time/clock.dart';
import '../../../core/time/date_format.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/app_mark.dart';
import '../../diary/ui/diary_screen.dart' show hazriStreakProvider;
import '../../goals/data/goals_controller.dart';
import '../../nitnem/domain/bani.dart';
import '../data/hazri_controller.dart';
import 'hazri_banner.dart';

/// Design 61 — the day's goals are all met.
///
/// Shown when the last one is met and never otherwise: the reader asked that
/// this appear only on reaching the goal, not on finishing a paath. A day
/// where hazri was marked but the goal was not is a good day and gets no
/// screen, because one that appears every day stops meaning anything.
///
/// A full screen, always dark, over whatever is showing (05-today T9: "from
/// wherever the last item was met").
Future<void> showGoalCompleteSheet(BuildContext context) => showGeneralDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, _, _) => const _GoalComplete(),
      transitionBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
    );

const _night = Color(0xFF070A1A);
const _green = Color(0xFF6FE3A6);
const _white = Colors.white;

class _GoalComplete extends ConsumerWidget {
  const _GoalComplete();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final dates = HazriDates.of(context);
    final now = ref.watch(clockProvider).now();
    final hazri = ref.watch(hazriTodayProvider);
    final calendar = ref.watch(nanakshahiCalendarProvider).value;
    final nanakshahi = calendar?.dateFor(DateTime(now.year, now.month, now.day));
    final items = ref.watch(itemsInScopeTodayProvider);
    final rows = ref.watch(todayRowsProvider).value;
    final banis = ref.watch(banisProvider).value ?? const <Bani>[];
    final streak = ref.watch(hazriStreakProvider).value?.current ?? 0;
    final date = [dates.longDate(now), ?nanakshahi?.labelWithYear(l.localeName)].join('  ·  ');

    // Each item met today: a bani with the time of its latest paath, Simran
    // with its minutes.
    final lines = <(String, String)>[
      for (final item in items)
        if (item.itemType == ItemType.simran)
          (l.goalNaamSimran, l.goalSimranMinutes(itemToday(item, rows).done))
        else
          (
            banis.where((b) => b.id == item.baniId).firstOrNull?.name(l.localeName) ?? item.baniId ?? '',
            () {
              final latest = (rows?.completions ?? const <Completion>[])
                  .where((c) => c.baniId == item.baniId)
                  .map((c) => c.completedAt.toLocal())
                  .fold<DateTime?>(null, (a, b) => a == null || b.isAfter(a) ? b : a);
              return latest == null ? '' : dates.time(latest);
            }(),
          ),
    ];

    return Material(
      color: _night,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.62),
            radius: 0.9,
            colors: [Color(0xFF14352B), _night],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 36, 24, 16),
            child: Column(
              children: [
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _green, width: 3),
                  ),
                  alignment: Alignment.center,
                  child: const AppMark(size: 56, arcColor: _white, sunColor: _green),
                ),
                const SizedBox(height: 24),
                Text(
                  l.hazriGoalsAllDone,
                  textAlign: TextAlign.center,
                  style: HazriText.display26.copyWith(color: _white, fontSize: 27),
                ),
                const SizedBox(height: 10),
                Text(
                  date,
                  textAlign: TextAlign.center,
                  style: HazriText.caption.copyWith(color: _white.withValues(alpha: 0.55)),
                ),
                const SizedBox(height: 24),
                if (lines.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: _white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _white.withValues(alpha: 0.10)),
                    ),
                    child: Column(
                      children: [
                        for (final (name, at) in lines)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            child: Row(
                              children: [
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: const BoxDecoration(color: _green, shape: BoxShape.circle),
                                  child: const Center(child: AppIcon(HazriIconData.check, size: 13, color: _night)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(name, style: HazriText.bodyStrong.copyWith(color: _white, fontSize: 14.5)),
                                ),
                                Text(at, style: HazriText.caption.copyWith(color: _white.withValues(alpha: 0.6))),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 18),
                // Hazri and the goal are separate achievements and this
                // screen says both: the goal in the heading, the hazri
                // underneath with the time it happened.
                if (hazri.isMarked)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const AppIcon(HazriIconData.sunArc, size: 16, color: Color(0xFFF2A24E)),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          hazriLine(context, ref, hazri),
                          style: HazriText.caption.copyWith(color: _white.withValues(alpha: 0.65)),
                        ),
                      ),
                    ],
                  ),
                const Spacer(),
                if (streak >= 2)
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(
                        text: l.diaryStreakDays(streak),
                        style: HazriText.captionStrong.copyWith(color: _green),
                      ),
                      TextSpan(
                        text: '  ·  ${l.diaryGentleStreak.toLowerCase()}',
                        style: HazriText.caption.copyWith(color: _white.withValues(alpha: 0.55)),
                      ),
                    ]),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: _green,
                      foregroundColor: _night,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const AppIcon(HazriIconData.calendar, size: 18, color: _night),
                    label: Text(l.hazriSeeDiary, style: HazriText.bodyStrong.copyWith(color: _night)),
                    onPressed: () {
                      Navigator.of(context).pop();
                      GoRouter.of(context).go(Routes.diary);
                    },
                  ),
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l.actionDone, style: HazriText.captionStrong.copyWith(color: _white.withValues(alpha: 0.6))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
