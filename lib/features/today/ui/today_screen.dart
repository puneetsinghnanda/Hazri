import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/db/content_db.dart' show CalendarEventRow;
import '../../gurpurab/domain/calendar_display.dart';
import '../../../core/db/content_repository.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/time/clock.dart';
import '../../../core/time/date_format.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/day_arc.dart';
import '../../../core/widgets/surfaces.dart';
import '../../nitnem/domain/bani.dart';
import '../data/today_controller.dart';
import '../domain/today_state.dart';
import 'elder_today.dart';
import '../../goals/data/goals_controller.dart';
import '../../goals/domain/goal_progress.dart';
import '../../vichar/ui/vichar_card.dart';

/// The Today tab (Design 09/10), or its elder-mode variant (Design 11).
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(settingsProvider.select((s) => s.elderMode))) {
      return const ElderTodayScreen();
    }

    final c = context.colors;
    final l = L.of(context);
    final dates = HazriDates.of(context);
    final now = ref.watch(clockProvider).now();

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: PhoneWidth(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(HazriSize.gutter, 20, HazriSize.gutter, 20),
            children: [
              Text(
                dates.longDate(now),
                style: HazriText.body.copyWith(
                  fontSize: 14,
                  color: c.muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(l.greeting, style: HazriText.display26.copyWith(color: c.ink)),
              const SizedBox(height: 12),
              const _GoalsCard(),
              const SizedBox(height: 12),
              _CtaButton(cta: ref.watch(todayCtaProvider)),
              const SizedBox(height: 12),
              const VicharCard(),
              const SizedBox(height: 12),
              const _Tiles(),
              const SizedBox(height: 12),
              const _GurpurabCard(),
            ],
          ),
        ),
      ),
    );
  }
}

/// The goals card: the day's paath goals on the arc, by the time they are set
/// for (PRD 1.15).
///
/// The first thing on Today, because a goal someone set for themselves is a
/// stronger call than a schedule the app chose. With no goals it asks for one
/// rather than showing an empty curve.
class _GoalsCard extends ConsumerWidget {
  const _GoalsCard();

  /// "HH:mm" against [day], or null when the goal has no time set.
  static DateTime? _at(String? hhmm, DateTime day) {
    if (hhmm == null) return null;
    final parts = hhmm.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return DateTime(day.year, day.month, day.day, h, m);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final dates = HazriDates.of(context);
    final now = ref.watch(clockProvider).now();
    final banis = ref.watch(banisProvider).value ?? const <Bani>[];
    final progress = ref.watch(goalProgressProvider);

    if (progress.isLoading) {
      return const HazriCard(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final live = (progress.value ?? const <GoalProgress>[])
        .where((p) => p.goal.active && !p.isComplete)
        .toList();

    if (live.isEmpty) return const _NoGoalsCard();

    String nameOf(String baniId) => banis
        .where((b) => b.id == baniId)
        .map((b) => b.name(l.localeName))
        .firstOrNull ?? '';

    final timed = <(GoalProgress, DateTime)>[];
    final untimed = <GoalProgress>[];
    for (final p in live) {
      final at = _at(p.goal.reminderTime, now);
      at == null ? untimed.add(p) : timed.add((p, at));
    }
    timed.sort((a, b) => a.$2.compareTo(b.$2));

    final done = live.where((p) => p.isDoneToday).length;

    // The next goal still outstanding is the one the arc calls active.
    DateTime? activeAt;
    for (final (p, at) in timed) {
      if (!p.isDoneToday) {
        activeAt = at;
        break;
      }
    }

    return HazriCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        children: [
          if (timed.isNotEmpty) ...[
            LayoutBuilder(
              builder: (context, constraints) => DayArc(
                width: constraints.maxWidth.clamp(200.0, 300.0),
                now: now,
                windowStart: timed.first.$2.subtract(const Duration(minutes: 30)),
                windowEnd: timed.last.$2.add(const Duration(minutes: 30)),
                nodes: [
                  for (final (p, at) in timed)
                    DayArcNode(
                      label: nameOf(p.goal.baniId),
                      at: at,
                      state: p.isDoneToday
                          ? ArcNodeState.done
                          : (at == activeAt ? ArcNodeState.active : ArcNodeState.todo),
                    ),
                ],
                centre: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l.nOfM(done, live.length),
                      style: HazriText.display22.copyWith(color: c.ink),
                    ),
                    Text(
                      l.goalsTitle,
                      style: HazriText.caption.copyWith(color: c.muted),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            // The times, spelled out under the arc where the nodes are too
            // small to carry them.
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 4,
              children: [
                for (final (p, at) in timed)
                  Text(
                    '${nameOf(p.goal.baniId)} · ${dates.timeCompact(at)}',
                    style: HazriText.captionStrong.copyWith(
                      color: p.isDoneToday
                          ? c.sage
                          : (at == activeAt ? c.kesriInk : c.muted),
                    ),
                  ),
              ],
            ),
          ] else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                l.goalsSubtitle(done, live.length),
                style: HazriText.bodyStrong.copyWith(color: c.ink),
              ),
            ),
          // Goals with no time cannot sit on a clock, so they sit under it.
          if (untimed.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in untimed)
                  HazriChip(
                    label: '${nameOf(p.goal.baniId)} · '
                        '${l.nOfM(p.doneToday, p.goal.timesPerDay)}',
                    background: p.isDoneToday ? c.sageSoft : c.card2,
                    foreground: p.isDoneToday ? c.sage : c.ink2,
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          PrimaryButton(
            label: l.settingsPaathGoals,
            secondary: true,
            onPressed: () => context.push(Routes.goals),
          ),
        ],
      ),
    );
  }
}

/// What Today shows before any goal exists.
class _NoGoalsCard extends StatelessWidget {
  const _NoGoalsCard();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    return HazriCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: c.sageSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: AppIcon(HazriIconData.flag, size: 22, color: c.sage),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.goalsEmptyTitle,
                        style: HazriText.bodyStrong.copyWith(color: c.ink)),
                    const SizedBox(height: 2),
                    Text(l.goalsEmptyBody,
                        style: HazriText.bodySmall.copyWith(color: c.ink2)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            label: l.goalsAdd,
            icon: HazriIconData.check,
            onPressed: () => context.push(Routes.goals),
          ),
        ],
      ),
    );
  }
}

class _CtaButton extends ConsumerWidget {
  const _CtaButton({required this.cta});

  final TodayCta? cta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    if (cta == null) {
      return const SizedBox(height: HazriSize.buttonMinHeight);
    }

    if (cta!.kind == TodayCtaKind.allDone) {
      return PrimaryButton(
        label: l.ctaAllDone,
        icon: HazriIconData.check,
        secondary: true,
        onPressed: () => context.go(Routes.diary),
      );
    }

    final bani = cta!.bani;
    final label = switch (cta!.kind) {
      TodayCtaKind.startNitnem => l.ctaStartNitnem,
      TodayCtaKind.continueBani => l.ctaContinueBani(bani!.name(l.localeName)),
      _ => l.ctaStartBani(bani!.name(l.localeName)),
    };
    final trailing = cta!.kind == TodayCtaKind.continueBani
        ? l.minutesLeft(cta!.minutes)
        : l.minutes(cta!.minutes);

    return PrimaryButton(
      label: label,
      icon: HazriIconData.play,
      trailing: trailing,
      onPressed: bani == null
          ? null
          : () => context.push(Routes.reader(bani.slug, line: cta!.line)),
    );
  }
}

class _Tiles extends ConsumerWidget {
  const _Tiles();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final settings = ref.watch(settingsProvider);
    final simranDone = ref.watch(simranDoneTodayProvider).value ?? false;
    final simranMinutes = ref.watch(simranMinutesTodayProvider).value ?? 0;

    return _Tile(
      icon: HazriIconData.simranDots,
      iconBg: c.sageSoft,
      iconFg: c.sage,
      title: l.simranTitle,
      subtitle: simranDone
          ? l.simranTileDone
          : l.simranTileProgress(simranMinutes, settings.simranMinutes),
      onTap: () => context.go(Routes.simran),
    );
  }
}

/// The Gurpurab calendar, full width on Today (PRD 1.3).
///
/// A card rather than half a row: it has both the next event and today's
/// Nanakshahi date to show, and neither fits in a tile without truncating.
class _GurpurabCard extends ConsumerWidget {
  const _GurpurabCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final today = ref.watch(clockProvider).today();
    final events = ref.watch(calendarEventsProvider).value ?? const <CalendarEventRow>[];
    final calendar = ref.watch(nanakshahiCalendarProvider).value;

    // The next event within a week, else today's Nanakshahi date (PRD 1.3).
    CalendarEventRow? next;
    for (final e in events) {
      final d = DateTime.parse(e.date);
      final days = d.difference(today).inDays;
      if (days >= 0 && days <= 7) {
        next = e;
        break;
      }
    }

    final ns = calendar?.dateFor(today);
    final when = next == null
        ? null
        : switch (DateTime.parse(next.date).difference(today).inDays) {
            0 => l.gurpurabTileToday,
            1 => l.gurpurabTileTomorrow,
            _ => l.gurpurabTileUpcoming,
          };
    final name = next?.nameFor(lang);

    return HazriCard(
      onTap: () => context.push(Routes.gurpurab),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: c.kesriSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: AppIcon(HazriIconData.calendar, size: 22, color: c.kesriInk),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  when ?? l.gurpurabTitle,
                  style: HazriText.caption.copyWith(
                    color: next == null ? c.muted : c.kesriInk,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name ?? ns?.labelWithYear(lang) ?? l.gurpurabNoData,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: HazriText.bodyStrong.copyWith(color: c.ink),
                ),
                // With an event on the card, today's Nanakshahi date still has
                // somewhere to go.
                if (next != null && ns != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    ns.labelWithYear(lang),
                    style: HazriText.caption.copyWith(color: c.muted),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          AppIcon(HazriIconData.chevronRight, size: 18, color: c.muted),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String icon;
  final Color iconBg;
  final Color iconFg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return HazriCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Center(child: AppIcon(icon, size: 22, color: iconFg)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: HazriText.bodyStrong.copyWith(fontSize: 14, color: c.ink),
                ),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: HazriText.caption.copyWith(color: c.ink2, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
