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
import '../../goals/domain/goal_progress.dart';
import '../../sangat/data/account_repository.dart';
import '../../sangat/ui/join_sangat_sheet.dart';
import '../../vichar/ui/vichar_card.dart';
import '../../../core/db/user_db.dart' show kSimranGoalId;
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
              // One or the other, never both: the join banner until somebody
              // has set up, the hazri banner after. The reader was explicit
              // about not stacking two.
              const _JoinSangatBanner(),
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

/// Design 30 — the banner that invites somebody into the sangat.
///
/// It shows only while they have not joined, and it is the whole of the
/// sangat's presence on Today until they do. There is no second nag: tap Not
/// now on the sheet and this stays as it is, which is the difference between
/// an invitation and a demand.
class _JoinSangatBanner extends ConsumerWidget {
  const _JoinSangatBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(hasJoinedSangatProvider)) return const SizedBox.shrink();

    final c = context.colors;
    final l = L.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => showJoinSangatSheet(context),
          borderRadius: BorderRadius.circular(HazriRadius.card),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(HazriRadius.card),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [c.kesri, const Color(0xFFB8560A)],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .18),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: AppIcon(HazriIconData.sangat,
                            size: 20, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.sangatBannerTitle,
                              style: HazriText.bodyStrong
                                  .copyWith(color: Colors.white)),
                          Text(
                            l.sangatBannerBody,
                            style: HazriText.caption.copyWith(
                                color: Colors.white.withValues(alpha: .9)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // Expanded, not bare: "Takes a couple of seconds" is
                    // longer in Punjabi and longer again at a large text
                    // size, and a bare Text in a Row overflows rather than
                    // wrapping. The widget tests caught exactly that.
                    Expanded(
                      child: Text(
                        l.sangatBannerTime,
                        style: HazriText.caption.copyWith(
                            color: Colors.white.withValues(alpha: .85)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    HazriChip(
                      label: l.sangatBannerCta,
                      background: Colors.white,
                      foreground: const Color(0xFF9A4F00),
                    ),
                  ],
                ),
              ],
            ),
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

    String nameOf(String baniId) => baniId == kSimranGoalId
        ? l.hazriSimran
        : (banis
                .where((b) => b.id == baniId)
                .map((b) => b.name(l.localeName))
                .firstOrNull ??
            '');

    // Timed goals in clock order, then the untimed ones. A goal with no time
    // is not a lesser goal; it simply has nothing to sort by.
    final sorted = [...live]..sort((a, b) {
        final at = _at(a.goal.reminderTime, now);
        final bt = _at(b.goal.reminderTime, now);
        if (at == null && bt == null) return 0;
        if (at == null) return 1;
        if (bt == null) return -1;
        return at.compareTo(bt);
      });

    final done = live.where((p) => p.isDoneToday).length;
    // Part-done counts: three of five paath is more than nothing, and the
    // headline ring says so even though the row count does not.
    var ticks = 0;
    var target = 0;
    for (final p in live) {
      ticks += p.doneToday.clamp(0, p.goal.timesPerDay);
      target += p.goal.timesPerDay;
    }
    final fraction = target == 0 ? 0.0 : ticks / target;

    return HazriCard(
      onTap: () => context.push(Routes.goals),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Eyebrow(l.goalsCardTitle),
                    Text(
                      l.goalsDoneOf(done, live.length),
                      style: HazriText.display22.copyWith(color: c.ink, fontSize: 20),
                    ),
                  ],
                ),
              ),
              ProgressRing(
                progress: fraction,
                size: 56,
                strokeWidth: 7,
                child: Text(
                  '${(fraction * 100).round()}%',
                  style: HazriText.captionStrong.copyWith(color: c.ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Divider(height: 1, color: c.rule),
          const SizedBox(height: 11),
          for (var i = 0; i < sorted.length; i++) ...[
            if (i > 0) const SizedBox(height: 9),
            _GoalRow(
              name: nameOf(sorted[i].goal.baniId),
              progress: sorted[i],
              at: _at(sorted[i].goal.reminderTime, now),
              dates: dates,
            ),
          ],
        ],
      ),
    );
  }
}

/// One goal on design 30's card: a small ring, its name, and when or how much.
class _GoalRow extends StatelessWidget {
  const _GoalRow({
    required this.name,
    required this.progress,
    required this.at,
    required this.dates,
  });

  final String name;
  final GoalProgress progress;
  final DateTime? at;
  final HazriDates dates;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    final target = progress.goal.timesPerDay;
    final fraction = target == 0 ? 0.0 : (progress.doneToday / target).clamp(0.0, 1.0);

    return Row(
      children: [
        ProgressRing(
          progress: fraction,
          size: 26,
          strokeWidth: 4,
          done: progress.isDoneToday,
        ),
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
          // The time it is due if it has one, otherwise how many of how many.
          at != null ? dates.timeCompact(at!) : l.nOfM(progress.doneToday, target),
          style: HazriText.caption.copyWith(color: c.muted, fontWeight: FontWeight.w600),
        ),
      ],
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
