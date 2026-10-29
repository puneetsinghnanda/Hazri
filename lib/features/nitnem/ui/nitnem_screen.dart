import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/db/content_db.dart' show BaniSlot;
import '../../../core/db/content_repository.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/time/date_format.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/progress_ring.dart';
import '../../../core/widgets/surfaces.dart';
import '../../audio/data/audio_controller.dart';
import '../../goals/data/goals_controller.dart';
import '../../reminders/data/reminders_controller.dart';
import '../../today/data/today_controller.dart';
import '../data/nitnem_controller.dart';
import '../domain/bani.dart';
import '../../../app/menu_sheet.dart';
import '../../../core/widgets/tab_header.dart';

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
    final hasAnyAudio = ref.watch(hasAudioProvider);

    String? subtitleFor(BaniSlot slot) {
      if (slot == BaniSlot.morning) {
        final banis = sections[slot] ?? const [];
        final minutes = banis.fold<int>(0, (sum, b) => sum + b.estMinutes);
        return l.nitnemSectionSummary(banis.length, minutes);
      }
      // Rehras at sunset; the per-slot reminders and their own times went
      // with 02-notifications N-2, so bedtime carries no time of its own.
      final at = slotTimes?[slot];
      if (at == null || slot != BaniSlot.evening) return null;
      return l.nitnemAtSunset(dates.time(at));
    }

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: PhoneWidth(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(HazriSize.gutter, 0, HazriSize.gutter, 20),
            children: [
              // Design 12: the version line once, under the title, and the
              // audio chip to the right.
              TabHeader(
                title: l.nitnemTitle,
                subtitle: l.nitnemVersionLine,
                onMenu: () => showMenuDrawer(context),
                trailing: Padding(
                  padding: const EdgeInsets.only(left: 8, top: 6),
                  child: HazriChip(
                    icon: hasAnyAudio ? HazriIconData.check : HazriIconData.headphones,
                    label: hasAnyAudio ? l.nitnemAudioSavedOffline : l.nitnemAudioNotAvailable,
                    background: hasAnyAudio ? c.sageSoft : c.card2,
                    foreground: hasAnyAudio ? c.sage : c.muted,
                    minHeight: 30,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const _GoalsSummaryCard(),
              const SizedBox(height: 14),
              for (final slot in [BaniSlot.morning, BaniSlot.evening, BaniSlot.bedtime, BaniSlot.none])
                if ((sections[slot] ?? const []).isNotEmpty)
                  _Section(
                    slot: slot,
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
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: c.kesriSoft, borderRadius: BorderRadius.circular(12)),
              child: Center(child: AppIcon(HazriIconData.sparkle, size: 20, color: c.kesriInk)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(l.goalsSetOne, style: HazriText.bodyStrong.copyWith(color: c.ink, fontSize: 16)),
            ),
            AppIcon(HazriIconData.chevronRight, size: 18, color: c.muted),
          ],
        ),
      );
    }

    return HazriCard(
      onTap: () => context.push(Routes.goals),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Design 12: a soft kesri square with the goal mark.
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: c.kesriSoft, borderRadius: BorderRadius.circular(12)),
            child: Center(child: AppIcon(HazriIconData.sparkle, size: 20, color: c.kesriInk)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.goalsSummaryCard, style: HazriText.bodyStrong.copyWith(color: c.ink, fontSize: 16)),
                Text(
                  l.goalsSummaryLine(summary.doneToday, summary.total),
                  style: HazriText.caption.copyWith(color: c.muted),
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

class _Section extends ConsumerWidget {
  const _Section({required this.slot, required this.title, required this.subtitle, required this.banis});

  final BaniSlot slot;
  final String title;
  final String? subtitle;
  final List<Bani> banis;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    // "Play all" queues every bani in the slot that has a recitation, gapless
    // (PRD 1.4).
    final playable = ref.watch(audioTracksProvider).value ?? const {};
    final canPlayAll =
        ref.watch(audioHandlerProvider) != null && banis.where((b) => playable.containsKey(b.id)).length > 1;
    final icon = switch (slot) {
      BaniSlot.morning => HazriIconData.sunArc,
      BaniSlot.evening => HazriIconData.sunset,
      BaniSlot.bedtime => HazriIconData.moon,
      BaniSlot.none => HazriIconData.book,
    };
    // Design 2A (owner, 2026-10-29): each part of the day its own card,
    // tinted by its light (dawn, sunset, a soft night that is never navy),
    // fading to the card's own colour; the header sits inside it, with its
    // icon, and Play all is a navy pill.
    final dark = Theme.of(context).brightness == Brightness.dark;
    final tint = switch (slot) {
      BaniSlot.morning => c.kesriSoft,
      BaniSlot.evening => dark ? const Color(0xFF40261C) : const Color(0xFFF8D9C4),
      BaniSlot.bedtime => dark ? const Color(0xFF262A55) : const Color(0xFFE3E4F6),
      BaniSlot.none => c.card,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: HazriCard(
        key: ValueKey('nitnem-slot-${slot.name}'),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tint, c.card],
          stops: const [0, 0.6],
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppIcon(icon, size: 22, color: c.kesriInk),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: HazriText.bodyStrong.copyWith(color: c.ink, fontSize: 16)),
                      if (subtitle != null)
                        Text(subtitle!, style: HazriText.caption.copyWith(color: c.muted, fontSize: 12)),
                    ],
                  ),
                ),
                if (canPlayAll)
                  Material(
                    color: c.primary,
                    shape: const StadiumBorder(),
                    child: InkWell(
                      customBorder: const StadiumBorder(),
                      onTap: () => ref.read(playbackControllerProvider).playSlot(slot, language: l.localeName),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          height: 36,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppIcon(HazriIconData.play, size: 14, color: c.onPrimary),
                              const SizedBox(width: 8),
                              Text(
                                l.nitnemPlayAll,
                                style: HazriText.captionStrong.copyWith(color: c.onPrimary, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            for (final b in banis) ...[Divider(height: 1, color: c.rule), BaniRow(bani: b)],
          ],
        ),
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
    final fraction = (resume == null || bani.lineCount == 0) ? 0.0 : (resume.lineIdx / bani.lineCount).clamp(0.0, 1.0);

    // A bani whose text has not shipped says so; otherwise the row shows where
    // the reader left off (design 12: "2:04 in", in kesri, from the saved
    // audio position, or the line when it was read without audio), or how
    // long the bani takes.
    final String trailing;
    var resuming = false;
    if (!bani.hasText) {
      trailing = l.comingSoonShort;
    } else if (!doneToday && resume != null && resume.audioPosMs > 0) {
      final s = resume.audioPosMs ~/ 1000;
      trailing = l.nitnemResumeAt('${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}');
      resuming = true;
    } else if (!doneToday && resume != null && resume.lineIdx > 0) {
      trailing = l.nitnemLineOf(resume.lineIdx + 1, bani.lineCount);
      resuming = true;
    } else {
      trailing = l.minutes(bani.estMinutes);
    }

    return Opacity(
      opacity: bani.hasText ? 1 : 0.55,
      child: InkWell(
        onTap: () => context.push(Routes.reader(bani.slug)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                ProgressRing(size: 36, strokeWidth: 4, progress: fraction, done: doneToday),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bani.name(l.localeName),
                        style: HazriText.body.copyWith(color: c.ink, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      Text(bani.nativeName, style: HazriText.gurmukhi(14).copyWith(color: c.ink2, height: 1.4)),
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
                    style: resuming
                        ? HazriText.captionStrong.copyWith(color: c.kesriInk)
                        : HazriText.caption.copyWith(color: c.muted),
                  ),
                ),
                const SizedBox(width: 6),
                AppIcon(HazriIconData.chevronRight, size: 18, color: c.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
