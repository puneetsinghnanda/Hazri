import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/db/content_db.dart' show BaniSlot;
import '../../../core/db/user_db.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/time/date_format.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/progress_ring.dart';
import '../../../core/widgets/surfaces.dart';
import '../../goals/data/goals_controller.dart';
import '../../reminders/data/reminders_controller.dart';
import '../../reminders/domain/reminder_plan.dart';
import '../../today/data/today_controller.dart';
import '../data/nitnem_controller.dart';
import '../domain/bani.dart';

/// The Nitnem list (Design 12).
class NitnemScreen extends ConsumerWidget {
  const NitnemScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final sections = ref.watch(nitnemSectionsProvider);
    final slotTimes = ref.watch(slotTimesProvider).value;
    final dates = HazriDates.of(context);
    final reminders = ref.watch(remindersProvider).value ?? const <Reminder>[];

    String? subtitleFor(BaniSlot slot) {
      if (slot == BaniSlot.morning) {
        final banis = sections[slot] ?? const [];
        final minutes = banis.fold<int>(0, (sum, b) => sum + b.estMinutes);
        return l.nitnemSectionSummary(banis.length, minutes);
      }
      final at = slotTimes?[slot];
      if (at == null) return null;
      final id = slot == BaniSlot.evening ? ReminderIds.evening : ReminderIds.bedtime;
      final mode = reminders.where((r) => r.id == id).firstOrNull?.mode;
      return mode == ReminderMode.auto
          ? l.nitnemAtSunset(dates.time(at))
          : l.nitnemYourTime(dates.time(at));
    }

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: PhoneWidth(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(HazriSize.gutter, 20, HazriSize.gutter, 20),
            children: [
              Text(l.nitnemTitle, style: HazriText.display26.copyWith(color: c.ink)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l.nitnemVersionLine,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: HazriText.bodySmall.copyWith(color: c.muted),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: HazriChip(
                      icon: HazriIconData.headphones,
                      label: l.nitnemAudioNotAvailable,
                      background: c.card2,
                      foreground: c.muted,
                      minHeight: 30,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const _GoalsSummaryCard(),
              const SizedBox(height: 14),
              for (final slot in [
                BaniSlot.morning,
                BaniSlot.evening,
                BaniSlot.bedtime,
                BaniSlot.none,
              ])
                if ((sections[slot] ?? const []).isNotEmpty)
                  _Section(
                    title: switch (slot) {
                      BaniSlot.morning => l.slotAmritVela,
                      BaniSlot.evening => l.slotEvening,
                      BaniSlot.bedtime => l.slotBedtime,
                      BaniSlot.none => l.slotMoreBanis,
                    },
                    subtitle: subtitleFor(slot),
                    banis: sections[slot]!,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalsSummaryCard extends ConsumerWidget {
  const _GoalsSummaryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final summary = ref.watch(goalsSummaryProvider);

    if (summary.total == 0) {
      return HazriCard(
        onTap: () => context.push(Routes.goals),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            AppIcon(HazriIconData.flag, size: 20, color: c.muted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(l.goalsSetOne, style: HazriText.body.copyWith(color: c.ink2)),
            ),
            AppIcon(HazriIconData.chevronRight, size: 18, color: c.muted),
          ],
        ),
      );
    }

    return HazriCard(
      onTap: () => context.push(Routes.goals),
      child: Row(
        children: [
          ProgressRing(
            size: 38,
            progress: summary.total == 0 ? 0 : summary.doneToday / summary.total,
            done: summary.doneToday == summary.total,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.goalsSummaryCard, style: HazriText.bodyStrong.copyWith(color: c.ink)),
                Text(
                  l.goalsSummaryLine(summary.doneToday, summary.total),
                  style: HazriText.bodySmall.copyWith(color: c.muted),
                ),
              ],
            ),
          ),
          AppIcon(HazriIconData.chevronRight, size: 18, color: c.muted),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.subtitle, required this.banis});

  final String title;
  final String? subtitle;
  final List<Bani> banis;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: HazriText.sectionTitle.copyWith(color: c.ink)),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: HazriText.caption.copyWith(color: c.muted),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          HazriCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < banis.length; i++) ...[
                  BaniRow(bani: banis[i]),
                  if (i != banis.length - 1)
                    Padding(
                      padding: const EdgeInsets.only(left: 64),
                      child: Divider(height: 1, color: c.rule),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One bani row: its progress, its names, and what it costs in time.
class BaniRow extends ConsumerWidget {
  const BaniRow({super.key, required this.bani});

  final Bani bani;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final progressMap = ref.watch(progressByVersionProvider).value ?? const {};
    final dayProgress = ref.watch(dayProgressProvider).value;

    final doneToday = dayProgress?.completedBaniIds.contains(bani.id) ?? false;
    final resume = bani.versionId == null ? null : progressMap[bani.versionId];
    final fraction = (resume == null || bani.lineCount == 0)
        ? 0.0
        : (resume.lineIdx / bani.lineCount).clamp(0.0, 1.0);

    // A bani whose text has not shipped says so; otherwise the row shows where
    // the reader left off, or how long the bani takes.
    final String trailing;
    if (!bani.hasText) {
      trailing = l.comingSoonShort;
    } else if (!doneToday && resume != null && resume.lineIdx > 0) {
      trailing = l.nitnemLineOf(resume.lineIdx + 1, bani.lineCount);
    } else {
      trailing = l.minutes(bani.estMinutes);
    }

    return Opacity(
      opacity: bani.hasText ? 1 : 0.55,
      child: InkWell(
        onTap: () => context.push(Routes.reader(bani.slug)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              ProgressRing(size: 34, progress: fraction, done: doneToday),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bani.name(l.localeName),
                      style: HazriText.bodyStrong.copyWith(color: c.ink),
                    ),
                    Text(
                      bani.nativeName,
                      style: HazriText.gurmukhi(14).copyWith(color: c.muted, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 96),
                child: Text(
                  trailing,
                  maxLines: 2,
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  style: HazriText.caption.copyWith(color: c.muted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
