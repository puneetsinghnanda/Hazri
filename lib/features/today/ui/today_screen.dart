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
import '../../hazri/ui/hazri_banner.dart';
import '../domain/today_state.dart';
import '../../diary/ui/diary_screen.dart' show hazriStreakProvider;
import '../../../core/db/user_repository.dart' show HazriStreak;
import '../../../core/widgets/app_mark.dart';
import 'package:intl/intl.dart';
import '../../goals/data/goals_controller.dart';
import '../../goals/domain/day_verdict.dart';
import '../../goals/ui/set_goal_card.dart';
import '../../saakhi/ui/saakhi_library_screen.dart';
import '../../vichar/ui/vichar_card.dart';
import '../../profile/data/profile_controller.dart';
import '../../profile/ui/profile_banner.dart';
import '../../../core/db/user_db.dart' show GoalItem, ItemType;
import '../../../core/widgets/progress_ring.dart';

/// The Today tab (Design 09/10), or its elder-mode variant (Design 11).
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // T5: elder mode is a mode, not a screen. Sizes come from the elder
    // theme; the secondary cards (Vichar, Gurpurab) step aside.
    final elder = ref.watch(settingsProvider.select((s) => s.elderMode));
    final c = context.colors;
    final profile = ref.watch(profileControllerProvider);
    final hasBanner = profile is ProfileNone || profile is ProfileUnavailable;
    final streak = ref.watch(hazriStreakProvider).value;

    return Scaffold(
      backgroundColor: c.bg,
      body: PhoneWidth(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const _TodayAppBar(),
            // T11: the first card overlaps the band by 32 dp.
            Transform.translate(
              offset: const Offset(0, -32),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: HazriSize.gutter),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (hasBanner) ...[
                      const ProfileBanner(),
                      const SizedBox(height: 12),
                    ],
                    const HazriBanner(),
                    // T12: only at 2 days or more; nothing said below that.
                    if (streak != null && streak.current >= 2) ...[
                      _StreakCard(streak: streak),
                      const SizedBox(height: 12),
                    ],
                    const _GoalsCard(),
                    const SizedBox(height: 12),
                    _CtaButton(cta: ref.watch(todayCtaProvider)),
                    if (!elder) ...[
                      // 13-saakhi SK11, option 1A: after the button, before ਅੱਜ ਦਾ ਵਿਚਾਰ.
                      const SizedBox(height: 18),
                      const SaakhiTodayRow(),
                      const SizedBox(height: 12),
                      const VicharCard(),
                      const SizedBox(height: 12),
                      const _GurpurabCard(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// T11, canvas option D: the navy band on Today only. Menu, the sunrise
/// mark and "Hazri", the person button; then the greeting and the date,
/// Gregorian and Nanakshahi.
class _TodayAppBar extends ConsumerWidget {
  const _TodayAppBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final dates = HazriDates.of(context);
    final now = ref.watch(clockProvider).now();
    final dark = Theme.of(context).brightness == Brightness.dark;
    final band = dark ? c.card2 : c.primary;
    const white = Colors.white;
    final calendar = ref.watch(nanakshahiCalendarProvider).value;
    final ns = calendar?.dateFor(DateTime(now.year, now.month, now.day));
    final date = [dates.longDate(now), ?ns?.labelWithYear(l.localeName)].join(' · ');

    Widget round(Widget child, String tooltip, VoidCallback onTap, {bool circle = false}) => Tooltip(
          message: tooltip,
          child: Material(
            color: white.withValues(alpha: 0.12),
            shape: circle ? const CircleBorder() : RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: InkWell(
              customBorder: circle ? const CircleBorder() : null,
              borderRadius: circle ? null : BorderRadius.circular(14),
              onTap: onTap,
              child: SizedBox.square(dimension: 44, child: Center(child: child)),
            ),
          ),
        );

    return Container(
      decoration: BoxDecoration(
        color: band,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(HazriSize.gutter, MediaQuery.paddingOf(context).top + 10, HazriSize.gutter, 52),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              round(AppIcon(HazriIconData.menu, size: 20, color: white), l.menuTooltip, () => showMenuDrawer(context)),
              const SizedBox(width: 12),
              const AppMark(size: 28, arcColor: white, sunColor: Color(0xFFF2A24E)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l.appBarTitle,
                  style: HazriText.brand.copyWith(fontSize: 22, color: white),
                ),
              ),
              round(const Icon(Icons.person, size: 22, color: white), l.profileTitle,
                  () => context.push(Routes.profile), circle: true),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            greeting(l, ref.watch(profileControllerProvider)),
            style: HazriText.display22.copyWith(color: white, fontSize: 24),
          ),
          const SizedBox(height: 2),
          Text(date, style: HazriText.caption.copyWith(color: white.withValues(alpha: 0.78), fontSize: 13)),
        ],
      ),
    );
  }
}

/// T12, canvas option Streak 3: the number over its caption, and the last
/// seven days, saffron for a day that counts, today ringed. Opens the Diary.
class _StreakCard extends ConsumerWidget {
  const _StreakCard({required this.streak});

  final HazriStreak streak;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final today = ref.watch(clockProvider).today();
    final days = [for (var i = 6; i >= 0; i--) today.subtract(Duration(days: i))];
    String initial(DateTime d) {
      try {
        return DateFormat('EEEEE', l.localeName).format(d);
      } on Object {
        return DateFormat('EEEEE').format(d);
      }
    }

    return HazriCard(
      onTap: () => context.go(Routes.diary),
      child: Row(
        children: [
          Flexible(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.todayStreakDays(streak.current),
                    style: HazriText.display22.copyWith(color: c.kesri, fontSize: 30, height: 1.1)),
                Text(l.todayStreakCaption,
                    maxLines: 3, style: HazriText.caption.copyWith(color: c.muted)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final d in days)
                  Column(
                    children: [
                      Text(initial(d), style: HazriText.caption.copyWith(color: c.muted, fontSize: 11)),
                      const SizedBox(height: 4),
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: streak.days.contains(localDateKey(d)) ? c.kesri : c.rule,
                          border: d == today ? Border.all(color: c.ink, width: 1.5) : null,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
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

    if (cta!.kind == TodayCtaKind.simran) {
      return PrimaryButton(
        label: l.simranBeginMinutes(cta!.minutes),
        icon: HazriIconData.simranDots,
        onPressed: () => context.go(Routes.simran),
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
