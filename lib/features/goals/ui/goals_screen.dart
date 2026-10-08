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
import '../../audio/data/notification_access.dart';
import '../../nitnem/domain/bani.dart';
import '../../settings/ui/screen_scaffold.dart';
import '../data/goals_controller.dart';
import 'add_goal_sheet.dart';
import 'set_goal_card.dart';

/// The Goals screen (04-goals §7.3, design 19). Items of the active goal in
/// scope today, in creation order. No "+1": completions come only from the
/// reader, the recitation and the Diary (CR1–CR4).
class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final dates = HazriDates.of(context);
    final today = ref.watch(clockProvider).today();
    final items = ref.watch(itemsInScopeTodayProvider);
    final verdict = ref.watch(todayVerdictProvider);
    final allowed = ref.watch(notificationsAllowedProvider).value ?? true;
    final anyReminder = items.any((i) => i.reminderTime != null);

    return HazriScreen(
      title: l.goalsTitle,
      subtitle: items.isEmpty
          ? dates.shortDate(today)
          : '${l.goalWidgetProgress(verdict.itemsMet, verdict.itemsInScope)} · ${dates.shortDate(today)}',
      children: [
        // RM6: a reminder that cannot arrive says so.
        if (!allowed && anyReminder) ...[
          HazriCard(
            colour: c.kesriSoft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.notificationRationale, style: HazriText.body.copyWith(color: c.kesriInk)),
                const SizedBox(height: 10),
                PrimaryButton(
                  label: l.actionAllow,
                  onPressed: () => ref.read(notificationsAllowedProvider.notifier).allow(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (items.isEmpty)
          const SetGoalCard()
        else
          for (final item in items) _ItemCard(item: item),
        const SizedBox(height: 12),
        if (items.isNotEmpty)
          PrimaryButton(
            label: l.goalsAdd,
            icon: HazriIconData.sparkle,
            secondary: true,
            onPressed: () => showGoalItemSheet(context),
          ),
      ],
    );
  }
}

class _ItemCard extends ConsumerWidget {
  const _ItemCard({required this.item});

  final GoalItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final dates = HazriDates.of(context);
    final banis = ref.watch(banisProvider).value ?? const <Bani>[];
    final rows = ref.watch(todayRowsProvider).value;
    final isSimran = item.itemType == ItemType.simran;
    final bani = isSimran ? null : banis.where((b) => b.id == item.baniId).firstOrNull;
    final name = isSimran ? l.goalNaamSimran : (bani?.name(l.localeName) ?? item.baniId ?? '');
    final today = ref.watch(clockProvider).today();
    final p = itemToday(item, rows);

    // "3 times a day · every day", "11 min · Day 4 of 40", "once a day ·
    // until 31 Dec" (§7.3).
    final target = isSimran ? l.goalSimranMinutes(item.simranMinutes ?? 5) : l.goalTimesRule(item.timesPerDay);
    final String span;
    final end = item.endDate;
    if (end == null) {
      span = l.goalDurationEveryDay;
    } else if (item.durationType == DurationType.days) {
      final start = parseLocalDateKey(item.startDate);
      span = l.goalDayOfTotal(
        today.difference(start).inDays + 1,
        parseLocalDateKey(end).difference(start).inDays + 1,
      );
    } else {
      span = l.goalDurationUntil(dates.shortDate(parseLocalDateKey(end)));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: HazriCard(
        onTap: () => isSimran
            ? context.go(Routes.simran)
            : (bani == null ? null : context.push(Routes.reader(bani.slug))),
        child: Row(
          children: [
            ProgressRing(
              size: 44,
              progress: p.target == 0 ? 0 : (p.done / p.target).clamp(0.0, 1.0),
              done: p.met,
              child: p.met
                  ? null
                  : Text('${p.done}/${p.target}',
                      style: HazriText.caption.copyWith(fontSize: 10, color: c.ink)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: HazriText.bodyStrong.copyWith(color: c.ink)),
                  if (bani != null)
                    Text(bani.nativeName,
                        style: HazriText.gurmukhi(13).copyWith(color: c.muted, height: 1.5)),
                  const SizedBox(height: 4),
                  Text('$target · $span', style: HazriText.caption.copyWith(color: c.ink2)),
                  Text(
                    isSimran
                        ? l.goalSimranMinutes(p.done)
                        : l.goalTimesOfTarget(p.done, p.target),
                    style: HazriText.captionStrong.copyWith(color: p.met ? c.sage : c.muted),
                  ),
                  if (item.reminderTime != null)
                    Text(
                      dates.time(_at(today, item.reminderTime!)),
                      style: HazriText.caption.copyWith(color: c.muted),
                    ),
                ],
              ),
            ),
            _ItemMenu(item: item, name: name),
          ],
        ),
      ),
    );
  }

  static DateTime _at(DateTime day, String hhmm) {
    final p = hhmm.split(':');
    return DateTime(day.year, day.month, day.day, int.parse(p[0]), int.parse(p[1]));
  }
}

class _ItemMenu extends ConsumerWidget {
  const _ItemMenu({required this.item, required this.name});

  final GoalItem item;
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    return PopupMenuButton<String>(
      icon: AppIcon(HazriIconData.dots, size: 18, color: context.colors.muted),
      onSelected: (value) async {
        switch (value) {
          case 'edit':
            await showGoalItemSheet(context, editing: item);
          // GI7: Remove asks first, then leaves the goal from today.
          case 'remove':
            final ok = await showDialog<bool>(
              context: context,
              builder: (dialog) => AlertDialog(
                title: Text(l.goalRemoveConfirmTitle(name)),
                content: Text(l.goalRemoveConfirmBody),
                actions: [
                  TextButton(onPressed: () => Navigator.of(dialog).pop(false), child: Text(l.actionCancel)),
                  TextButton(onPressed: () => Navigator.of(dialog).pop(true), child: Text(l.goalRemove)),
                ],
              ),
            );
            if (ok == true) await ref.read(userRepositoryProvider).removeItem(item.id);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: 'edit', child: Text(l.goalEdit)),
        PopupMenuItem(value: 'remove', child: Text(l.goalRemove)),
      ],
    );
  }
}
