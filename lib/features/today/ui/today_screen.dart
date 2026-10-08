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
import '../../../core/widgets/surfaces.dart';
import '../../nitnem/domain/bani.dart';
import '../data/today_controller.dart';
import '../../../app/menu_sheet.dart';
import '../../../core/widgets/tab_header.dart';
import '../../hazri/data/hazri_controller.dart';
import '../../hazri/ui/goal_complete_sheet.dart';
import '../../hazri/ui/hazri_banner.dart';
import '../domain/today_state.dart';
import 'elder_today.dart';
import '../../goals/data/goals_controller.dart';
import '../../goals/domain/day_verdict.dart';
import '../../goals/ui/set_goal_card.dart';
import '../../vichar/ui/vichar_card.dart';
import '../../../core/db/user_db.dart' show GoalItem, ItemType;
import '../../../core/widgets/progress_ring.dart';

/// The Today tab (Design 09/10), or its elder-mode variant (Design 11).
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Design 61, on the day the last goal is ticked and once on that day.
    // It follows the state rather than the tap, because the tick can happen
    // in the reader or the diary rather than here.
    //
    // Registered **before** the elder-mode return, not after it. It used to
    // sit below, so an elder-mode phone never subscribed and the sheet that
    // marks a finished day never appeared on it at all.
    ref.listen(goalsAllDoneTodayProvider, (was, isNow) {
      if (!isNow || (was ?? false)) return;
      final cue = ref.read(goalCompleteCueProvider);
      final today = ref.read(clockProvider).today();
      if (!cue.shouldShowFor(today)) return;
      cue.markShown(today);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) showGoalCompleteSheet(context);
      });
    });

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
            padding: const EdgeInsets.fromLTRB(HazriSize.gutter, 0, HazriSize.gutter, 20),
            children: [
              // Design 30's header: the menu, the tab's name, the date.
              TabHeader(
                title: l.navToday,
                subtitle: dates.longDate(now),
                onMenu: () => showMenuSheet(context),
              ),
              const SizedBox(height: 6),
              const HazriBanner(),
              const _GoalsCard(),
              const SizedBox(height: 12),
              // No Simran tile of its own: design 30 has Simran as a row on
              // the goals card, and the tile was asking the same question in
              // two places on one screen.
              _CtaButton(cta: ref.watch(todayCtaProvider)),
              const SizedBox(height: 12),
              // Gurpurab above the Vichar, as designs 30 and 58 have it: a
              // Gurpurab is a date somebody has to plan around and the day's
              // line is there whenever they get to it.
              const _GurpurabCard(),
              const SizedBox(height: 12),
              const VicharCard(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Design 30's goals card.
///
/// A count, a ring, and one row per goal. The Phase 1 card drew a semicircular
/// day arc with the goals hung off it as nodes, which was handsome and asked
/// the reader to read a clock face to learn a number. This says the number.
///
/// Simran is one of the rows rather than a card of its own: a goal is a goal,
/// and splitting them by whether they are counted in paath or minutes put the
/// same question in two places on the same screen.
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
    final rows = ref.watch(todayRowsProvider);

    if (rows.isLoading && !rows.hasValue) {
      return const HazriCard(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // 04-goals §7.1: the Set Goal card until there is an item in scope.
    final items = ref.watch(itemsInScopeTodayProvider);
    if (items.isEmpty) return const SetGoalCard();
    final verdict = ref.watch(todayVerdictProvider);

    String nameOf(GoalItem item) => item.itemType == ItemType.simran
        ? l.goalNaamSimran
        : (banis.where((b) => b.id == item.baniId).map((b) => b.name(l.localeName)).firstOrNull ??
            '');

    // Timed items in clock order, then the untimed ones.
    final sorted = [...items]..sort((a, b) {
        final at = _at(a.reminderTime, now);
        final bt = _at(b.reminderTime, now);
        if (at == null && bt == null) return 0;
        if (at == null) return 1;
        if (bt == null) return -1;
        return at.compareTo(bt);
      });
    final fraction = verdict.itemsInScope == 0 ? 0.0 : verdict.itemsMet / verdict.itemsInScope;

    return HazriCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => context.push(Routes.goals),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Eyebrow(l.goalWidgetTitle),
                      Text(
                        l.goalWidgetProgress(verdict.itemsMet, verdict.itemsInScope),
                        style: HazriText.display22.copyWith(color: c.ink, fontSize: 20),
                      ),
                    ],
                  ),
                ),
                ProgressRing(
                  progress: fraction,
                  size: 56,
                  strokeWidth: 7,
                  done: verdict.goalState == GoalState.met,
                ),
              ],
            ),
          ),
          const SizedBox(height: 11),
          Divider(height: 1, color: c.rule),
          const SizedBox(height: 5),
          for (final item in sorted)
            _GoalRow(
              item: item,
              name: nameOf(item),
              progress: itemToday(item, rows.value),
              at: _at(item.reminderTime, now),
              dates: dates,
              onTap: () {
                if (item.itemType == ItemType.simran) {
                  context.go(Routes.simran);
                  return;
                }
                final bani = banis.where((b) => b.id == item.baniId).firstOrNull;
                if (bani != null) context.push(Routes.reader(bani.slug));
              },
            ),
        ],
      ),
    );
  }
}

/// One item on the goal widget: a small ring, its name, and how much (§7.1).
class _GoalRow extends StatelessWidget {
  const _GoalRow({
    required this.item,
    required this.name,
    required this.progress,
    required this.at,
    required this.dates,
    required this.onTap,
  });

  final GoalItem item;
  final String name;
  final ({int done, int target, bool met}) progress;
  final DateTime? at;
  final HazriDates dates;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    final fraction =
        progress.target == 0 ? 0.0 : (progress.done / progress.target).clamp(0.0, 1.0);
    final amount = item.itemType == ItemType.simran
        ? l.goalSimranMinutes(progress.done)
        : l.goalTimesOfTarget(progress.done, progress.target);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            ProgressRing(progress: fraction, size: 26, strokeWidth: 4, done: progress.met),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name,
                style: HazriText.captionStrong.copyWith(color: c.ink, fontSize: 13.5),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              at == null || progress.met ? amount : '$amount · ${dates.timeCompact(at!)}',
              style: HazriText.caption.copyWith(color: c.muted, fontWeight: FontWeight.w600),
            ),
          ],
        ),
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
