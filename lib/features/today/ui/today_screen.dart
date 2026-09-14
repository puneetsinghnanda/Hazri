import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/db/content_db.dart' show BaniSlot, CalendarEventRow;
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
import '../../reminders/data/reminders_controller.dart';
import '../data/today_controller.dart';
import '../domain/today_state.dart';
import 'elder_today.dart';
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
              const _DayArcCard(),
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

class _DayArcCard extends ConsumerWidget {
  const _DayArcCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final dates = HazriDates.of(context);
    final now = ref.watch(clockProvider).now();
    final banis = ref.watch(banisProvider).value ?? const <Bani>[];
    final progress = ref.watch(dayProgressProvider).value;
    final slotTimes = ref.watch(slotTimesProvider).value;
    final cta = ref.watch(todayCtaProvider);

    if (progress == null || slotTimes == null || banis.isEmpty) {
      return const HazriCard(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final (done, total) = TodayLogic.morningCount(banis: banis, progress: progress);
    final active = TodayLogic.activeSlot(progress: progress, slotTimes: slotTimes, now: now);

    final morningAt = slotTimes[BaniSlot.morning]!;
    final eveningAt = slotTimes[BaniSlot.evening]!;
    final bedtimeAt = slotTimes[BaniSlot.bedtime]!;

    ArcNodeState stateFor(BaniSlot slot) => progress.isDone(slot)
        ? ArcNodeState.done
        : (slot == active ? ArcNodeState.active : ArcNodeState.todo);

    final subline = switch (cta?.kind) {
      TodayCtaKind.continueBani => l.arcBaniInProgress(cta!.bani!.name(l.localeName)),
      TodayCtaKind.allDone => l.ctaAllDone,
      TodayCtaKind.startBani => l.arcBaniAt(
        cta!.bani!.name(l.localeName),
        dates.timeCompact(slotTimes[cta.bani!.defaultSlot] ?? eveningAt),
      ),
      _ => progress.isDone(BaniSlot.morning) ? l.arcMorningComplete : l.arcNothingYet,
    };

    return HazriCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) => DayArc(
              width: constraints.maxWidth.clamp(200.0, 300.0),
              now: now,
              windowStart: morningAt.subtract(const Duration(minutes: 30)),
              windowEnd: bedtimeAt.add(const Duration(minutes: 30)),
              nodes: [
                DayArcNode(
                  label: l.slotAmritVela,
                  at: morningAt,
                  state: stateFor(BaniSlot.morning),
                ),
                DayArcNode(
                  label: l.diaryStatRehras,
                  at: eveningAt,
                  state: stateFor(BaniSlot.evening),
                ),
                DayArcNode(
                  label: l.diaryStatSohila,
                  at: bedtimeAt,
                  state: stateFor(BaniSlot.bedtime),
                ),
              ],
              centre: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l.nOfM(done, total), style: HazriText.display34.copyWith(color: c.ink)),
                  Text(
                    subline,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HazriText.bodySmall.copyWith(color: c.ink2, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l.slotAmritVela,
                style: HazriText.captionStrong.copyWith(
                  color: active == BaniSlot.morning ? c.kesriInk : c.muted,
                ),
              ),
              Text(
                '${l.diaryStatRehras} · ${dates.timeCompact(eveningAt)}',
                style: HazriText.captionStrong.copyWith(color: c.muted),
              ),
              Text(
                '${l.diaryStatSohila} · ${dates.timeCompact(bedtimeAt)}',
                style: HazriText.captionStrong.copyWith(color: c.muted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _CtaButton(cta: cta),
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
    final name = next == null
        ? null
        : switch (lang) {
            'pa' => next.namePa,
            'hi' => next.nameHi,
            _ => next.nameEn,
          };

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
