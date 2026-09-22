import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/menu_sheet.dart';
import '../../../app/router.dart';
import '../../../core/db/content_db.dart' show BaniSlot;
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/time/clock.dart';
import '../../../core/time/date_format.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/progress_ring.dart';
import '../../../core/widgets/surfaces.dart';
import '../../../core/widgets/tab_header.dart';
import '../../../core/db/content_repository.dart';
import '../../nitnem/domain/bani.dart';
import '../../reminders/data/reminders_controller.dart';
import '../data/today_controller.dart';
import '../domain/today_state.dart';

/// Elder mode Today (Design 11): fewer, larger cards and no small chips.
///
/// Nothing is hidden — Simran and the Diary stay reachable from here and from
/// Settings (PRD 1.12).
class ElderTodayScreen extends ConsumerWidget {
  const ElderTodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final dates = HazriDates.of(context);
    final now = ref.watch(clockProvider).now();
    final banis = ref.watch(banisProvider).value ?? const <Bani>[];
    final progress = ref.watch(dayProgressProvider).value;
    final cta = ref.watch(todayCtaProvider);
    final slotTimes = ref.watch(slotTimesProvider).value;
    final vichar = ref.watch(todayVicharProvider).value;

    final (done, total) =
        progress == null ? (0, 5) : TodayLogic.morningCount(banis: banis, progress: progress);

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: PhoneWidth(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(HazriSize.gutter, 0, HazriSize.gutter, 20),
            children: [
              // The same header as the other tabs, menu button included.
              // Elder mode has three tabs and Settings is not one of them, so
              // without this the menu -- settings, notifications, the
              // account, privacy, about -- had no door at all in elder mode.
              TabHeader(
                title: l.navToday,
                subtitle: dates.longDate(now),
                onMenu: () => showMenuSheet(context),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: HazriChip(
                  icon: HazriIconData.eye,
                  label: l.elderMode,
                  background: c.kesriSoft,
                  foreground: c.kesriInk,
                  minHeight: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(l.greeting, style: HazriText.display26.copyWith(fontSize: 34, color: c.ink)),
              Text(
                dates.longDate(now),
                style: HazriText.body.copyWith(fontSize: 18, color: c.muted),
              ),
              const SizedBox(height: 20),
              if (cta != null && cta.bani != null)
                HazriCard(
                  colour: c.primary,
                  onTap: () => context.push(Routes.reader(cta.bani!.slug, line: cta.line)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                  child: Row(
                    children: [
                      AppIcon(HazriIconData.play, size: 32, color: c.onPrimary),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cta.kind == TodayCtaKind.continueBani
                                  ? l.ctaContinueBani(cta.bani!.name(l.localeName))
                                  : l.ctaStartNitnem,
                              style: HazriText.display22.copyWith(
                                fontSize: 24,
                                color: c.onPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${cta.bani!.name(l.localeName)} · ${l.minutes(cta.minutes)}',
                              style: HazriText.body.copyWith(
                                fontSize: 17,
                                color: c.onPrimary.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                HazriCard(
                  colour: c.sageSoft,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                  onTap: () => context.go(Routes.diary),
                  child: Row(
                    children: [
                      AppIcon(HazriIconData.check, size: 30, color: c.sage),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          l.ctaAllDone,
                          style: HazriText.display22.copyWith(fontSize: 23, color: c.sage),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 14),
              _ElderCard(
                icon: HazriIconData.sparkle,
                title: l.vicharTitle,
                subtitle: vichar?.gurmukhi ?? l.vicharNone,
                onTap: () => context.push(Routes.vichar),
              ),
              const SizedBox(height: 14),
              HazriCard(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                onTap: () => context.go(Routes.nitnem),
                child: Row(
                  children: [
                    ProgressRing(
                      size: 64,
                      strokeWidth: 6,
                      progress: total == 0 ? 0 : done / total,
                      done: total > 0 && done == total,
                      child: Text(
                        '$done/$total',
                        style: HazriText.captionStrong.copyWith(fontSize: 15, color: c.ink),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.slotAmritVela,
                            style: HazriText.display22.copyWith(fontSize: 22, color: c.ink),
                          ),
                          Text(
                            l.introBanisCount(total),
                            style: HazriText.body.copyWith(fontSize: 17, color: c.ink2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _ElderCard(
                icon: HazriIconData.sunset,
                title: l.diaryStatRehras,
                subtitle: slotTimes == null
                    ? '—'
                    : dates.time(slotTimes[BaniSlot.evening] ?? now),
                onTap: () => context.push(Routes.reader('rehras-sahib')),
              ),
              const SizedBox(height: 14),
              _ElderCard(
                icon: HazriIconData.simranDots,
                title: l.simranTitle,
                subtitle: l.simranSubtitle,
                onTap: () => context.go(Routes.simran),
              ),
              const SizedBox(height: 14),
              _ElderCard(
                icon: HazriIconData.calendar,
                title: l.diaryTitle,
                subtitle: l.diaryFooter,
                onTap: () => context.go(Routes.diary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ElderCard extends StatelessWidget {
  const _ElderCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return HazriCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: c.kesriSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(child: AppIcon(icon, size: 28, color: c.kesriInk)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: HazriText.display22.copyWith(fontSize: 21, color: c.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: HazriText.body.copyWith(fontSize: 16, color: c.ink2),
                ),
              ],
            ),
          ),
          AppIcon(HazriIconData.chevronRight, size: 24, color: c.muted),
        ],
      ),
    );
  }
}
