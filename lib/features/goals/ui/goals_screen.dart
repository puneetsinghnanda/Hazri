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

    // A screen reached from a notification has nothing beneath it, so back
    // goes to Today rather than closing the app.
    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(Routes.today);
      },
      child: Scaffold(
        backgroundColor: c.bg,
        body: SafeArea(
          child: PhoneWidth(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                // Design 19: a bare back arrow and "My paath goals".
                Row(
                  children: [
                    IconButton(
                      tooltip: l.actionBack,
                      icon: AppIcon(HazriIconData.chevronLeft, size: 22, color: c.ink),
                      onPressed: () => context.canPop() ? context.pop() : context.go(Routes.today),
                    ),
                    const SizedBox(width: 4),
                    Text(l.goalsSummaryCard, style: HazriText.bodyStrong.copyWith(color: c.ink, fontSize: 17)),
                  ],
                ),
                const SizedBox(height: 10),
                // "1 of 3 done today", large, with the date beside it.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Text(
                        items.isEmpty ? l.goalsSummaryCard : l.goalsSummaryLine(verdict.itemsMet, verdict.itemsInScope),
                        style: HazriText.display26.copyWith(color: c.ink),
                      ),
                    ),
                    Text(dates.shortDate(today), style: HazriText.caption.copyWith(color: c.muted)),
                  ],
                ),
                const SizedBox(height: 16),
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
                if (items.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _AddButton(label: l.goalsAdd, onTap: () => showGoalItemSheet(context)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Design 19's add button: soft kesri, a dashed kesri edge.
class _AddButton extends StatelessWidget {
  const _AddButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return CustomPaint(
      foregroundPainter: _DashedBorder(color: c.kesri, radius: 16),
      child: Material(
        color: c.kesriSoft,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: SizedBox(
            height: 52,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppIcon(HazriIconData.sparkle, size: 18, color: c.kesriInk),
                const SizedBox(width: 10),
                Text(label, style: HazriText.bodyStrong.copyWith(color: c.kesriInk)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorder extends CustomPainter {
  _DashedBorder({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)).deflate(0.75));
    for (final metric in path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 9) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) => old.color != color;
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
    // Design 19: "Once a day", "5 times a day", "For 40 days · 1 extra paath
    // a day", "Until 31 Dec"; Simran by its minutes.
    final target = isSimran
        ? l.goalSimranMinutes(item.simranMinutes ?? 5)
        : (item.timesPerDay == 1 ? l.goalRuleOnce : l.goalRuleTimes(item.timesPerDay));
    final String rule;
    final end = item.endDate;
    int? dayN;
    int? dayTotal;
    if (end == null) {
      rule = target;
    } else if (item.durationType == DurationType.days) {
      final start = parseLocalDateKey(item.startDate);
      dayN = today.difference(start).inDays + 1;
      dayTotal = parseLocalDateKey(end).difference(start).inDays + 1;
      rule = isSimran ? '$target · ${l.goalDurationDays(dayTotal)}' : l.goalRuleForDays(dayTotal, item.timesPerDay);
    } else {
      rule = '$target · ${l.goalRuleUntil(dates.shortDate(parseLocalDateKey(end)))}';
    }

    // Design 19's footer: how today stands, and the reminder time.
    final String status;
    final Color statusColour;
    if (p.met) {
      status = l.goalStatusDone;
      statusColour = c.sage;
    } else if (isSimran) {
      status = '${l.goalSimranMinutes(p.done)} / ${l.goalSimranMinutes(p.target)}';
      statusColour = c.kesriInk;
    } else if (dayN != null && dayTotal != null && p.target == 1) {
      status = l.goalStatusDay(dayN, dayTotal);
      statusColour = c.kesriInk;
    } else {
      status = l.goalStatusProgress(p.done, p.target);
      statusColour = c.kesriInk;
    }

    void play() => isSimran
        ? context.go(Routes.simran)
        : (bani == null ? null : context.push(Routes.reader(bani.slug, autoplay: true)));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: HazriCard(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
        onTap: () => isSimran
            ? context.go(Routes.simran)
            : (bani == null ? null : context.push(Routes.reader(bani.slug))),
        child: Column(
          children: [
            Row(
              children: [
                if (p.met)
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: c.sage, shape: BoxShape.circle),
                    child: const Center(child: Icon(Icons.check, color: Colors.white, size: 26)),
                  )
                else
                  ProgressRing(
                    size: 48,
                    strokeWidth: 5,
                    progress: p.target == 0 ? 0 : (p.done / p.target).clamp(0.0, 1.0),
                  ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: HazriText.bodyStrong.copyWith(color: c.ink, fontSize: 16)),
                      if (bani != null)
                        Text(bani.nativeName, style: HazriText.gurmukhi(13).copyWith(color: c.ink2, height: 1.5)),
                      Text(rule, style: HazriText.caption.copyWith(color: c.ink2, fontSize: 13)),
                    ],
                  ),
                ),
                // Design 19: play it now.
                Tooltip(
                  message: l.goalPlayNow,
                  child: Material(
                    color: c.primary,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: play,
                      child: SizedBox.square(
                        dimension: 44,
                        child: Center(child: AppIcon(HazriIconData.play, size: 18, color: c.onPrimary)),
                      ),
                    ),
                  ),
                ),
                // Edit and Remove (§7.3, GI7).
                _ItemMenu(item: item, name: name),
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: c.rule),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(status, style: HazriText.captionStrong.copyWith(color: statusColour, fontSize: 12.5)),
                  ),
                  if (item.reminderTime != null) ...[
                    AppIcon(HazriIconData.bell, size: 14, color: c.muted),
                    const SizedBox(width: 4),
                    Text(
                      dates.time(_at(today, item.reminderTime!)),
                      style: HazriText.caption.copyWith(color: c.muted, fontSize: 12.5),
                    ),
                  ],
                ],
              ),
            ),
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
