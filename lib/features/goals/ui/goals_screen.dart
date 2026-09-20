import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
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
import '../../../core/widgets/progress_ring.dart';
import '../../../core/widgets/surfaces.dart';
import '../../nitnem/domain/bani.dart';
import '../../settings/ui/screen_scaffold.dart';
import '../data/goals_controller.dart';
import '../domain/goal_progress.dart';
import 'add_goal_sheet.dart';

/// Paath goals (Design 19).
///
/// No badges, no points and no streak pressure — a goal is a quiet count that
/// appears in the Diary (PRD 1.15).
class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final dates = HazriDates.of(context);
    final today = ref.watch(clockProvider).today();
    final progress = ref.watch(goalProgressProvider).value ?? const <GoalProgress>[];
    final summary = ref.watch(goalsSummaryProvider);

    return HazriScreen(
      title: l.goalsTitle,
      subtitle: summary.total == 0
          ? dates.shortDate(today)
          : '${l.goalsSubtitle(summary.doneToday, summary.total)} · ${dates.shortDate(today)}',
      children: [
        if (progress.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Text(
              l.goalsEmpty,
              textAlign: TextAlign.center,
              style: HazriText.body.copyWith(color: c.muted),
            ),
          )
        else
          for (final p in progress) _GoalCard(progress: p),
        const SizedBox(height: 12),
        PrimaryButton(
          label: l.goalsAdd,
          icon: HazriIconData.sparkle,
          secondary: true,
          onPressed: () => showAddGoalSheet(context),
        ),
        const SizedBox(height: 16),
        Text(
          l.goalsFooter,
          textAlign: TextAlign.center,
          style: HazriText.caption.copyWith(color: c.muted),
        ),
      ],
    );
  }
}

class _GoalCard extends ConsumerWidget {
  const _GoalCard({required this.progress});

  final GoalProgress progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final goal = progress.goal;
    final banis = ref.watch(banisProvider).value ?? const <Bani>[];
    final bani = banis.where((b) => b.id == goal.baniId).firstOrNull;
    final isSimran = goal.baniId == kSimranGoalId;
    // Naam Simran has no row in content.db, and this used to return an empty
    // box for it -- so a simran goal counted on Today and was invisible on
    // the screen that lists goals. Only a goal for something that is neither
    // a bani nor simran disappears now, which is a goal that should not
    // exist.
    if (bani == null && !isSimran) return const SizedBox.shrink();
    final name = isSimran ? l.hazriSimran : bani!.name(l.localeName);

    final rule = switch (goal.durationType) {
      // A simran goal is a length, not a count: "11 min" says more than
      // "once a day" about a sitting.
      GoalDuration.everyDay when isSimran => l.minutes(goal.minutes ?? 5),
      GoalDuration.everyDay =>
        goal.timesPerDay == 1 ? l.goalRuleOnce : l.goalRuleTimes(goal.timesPerDay),
      GoalDuration.days => l.goalRuleForDays(goal.days ?? 0, goal.timesPerDay),
      GoalDuration.until => l.goalRuleUntil(goal.untilDate ?? ''),
    };

    final status = progress.isComplete
        ? l.goalStatusComplete
        : progress.isDoneToday
            ? l.goalStatusDone
            : progress.totalDays != null
                ? l.goalStatusDay(progress.dayNumber, progress.totalDays!)
                : l.goalStatusProgress(progress.doneToday, goal.timesPerDay);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: HazriCard(
        onTap: () => isSimran
            ? context.go(Routes.simran)
            : context.push(Routes.reader(bani!.slug)),
        child: Row(
          children: [
            ProgressRing(
              size: 44,
              progress: progress.fraction,
              done: progress.isDoneToday,
              child: progress.isDoneToday
                  ? null
                  : Text(
                      '${progress.doneToday}/${goal.timesPerDay}',
                      style: HazriText.caption.copyWith(fontSize: 10, color: c.ink),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: HazriText.bodyStrong.copyWith(color: c.ink),
                  ),
                  // The Gurmukhi name under the English one, where there is
                  // one. Simran's name is not a bani's name and the content
                  // database does not carry it, so nothing is invented here.
                  if (bani != null)
                    Text(
                      bani.nativeName,
                      style: HazriText.gurmukhi(13)
                          .copyWith(color: c.muted, height: 1.5),
                    ),
                  const SizedBox(height: 4),
                  Text(rule, style: HazriText.caption.copyWith(color: c.ink2)),
                  Text(
                    status,
                    style: HazriText.captionStrong.copyWith(
                      color: progress.isDoneToday ? c.sage : c.muted,
                    ),
                  ),
                  if (goal.reminderTime != null)
                    Text(
                      goal.reminderTime!,
                      style: HazriText.caption.copyWith(color: c.muted),
                    ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  tooltip: '+1',
                  onPressed: progress.isDoneToday
                      ? null
                      : () async {
                          await ref.read(userRepositoryProvider).tickGoal(goal.id);
                        },
                  icon: AppIcon(
                    HazriIconData.check,
                    size: 20,
                    color: progress.isDoneToday ? c.muted : c.sage,
                  ),
                ),
                _GoalMenu(goal: goal),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalMenu extends ConsumerWidget {
  const _GoalMenu({required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final repo = ref.read(userRepositoryProvider);

    return PopupMenuButton<String>(
      icon: AppIcon(HazriIconData.dots, size: 18, color: context.colors.muted),
      onSelected: (value) async {
        switch (value) {
          case 'pause':
            await repo.saveGoal(
              GoalsCompanion(
                id: Value(goal.id),
                baniId: Value(goal.baniId),
                timesPerDay: Value(goal.timesPerDay),
                durationType: Value(goal.durationType),
                days: Value(goal.days),
                untilDate: Value(goal.untilDate),
                startDate: Value(goal.startDate),
                reminderTime: Value(goal.reminderTime),
                active: Value(!goal.active),
                createdAt: Value(goal.createdAt),
                updatedAt: Value(DateTime.now().toUtc()),
              ),
            );
          case 'delete':
            await repo.deleteGoal(goal.id);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: 'pause', child: Text(goal.active ? l.goalPause : l.actionResume)),
        PopupMenuItem(value: 'delete', child: Text(l.actionDelete)),
      ],
    );
  }
}
