import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/db/content_repository.dart';
import '../../../core/time/clock.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/surfaces.dart';
import '../data/hazri_controller.dart';
import 'hazri_banner.dart';

/// Design 61 — the day's goals are all met.
///
/// Shown when the last one is ticked and never otherwise: the reader asked
/// that this appear only on reaching the goal, not on finishing a paath. A
/// day where hazri was marked but the goal was not is a good day and gets no
/// sheet, because a sheet that appears every day stops meaning anything.
Future<void> showGoalCompleteSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _GoalCompleteSheet(),
    );

class _GoalCompleteSheet extends ConsumerWidget {
  const _GoalCompleteSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final hazri = ref.watch(hazriTodayProvider);
    final lang = l.localeName;
    final calendar = ref.watch(nanakshahiCalendarProvider).value;
    final nanakshahi = calendar?.dateFor(ref.watch(clockProvider).today());

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: c.rule,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: c.sageSoft, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: AppIcon(HazriIconData.check, size: 30, color: c.sage),
            ),
            const SizedBox(height: 14),
            Text(
              l.hazriGoalsAllDone,
              textAlign: TextAlign.center,
              style: HazriText.display22.copyWith(color: c.ink),
            ),
            if (nanakshahi != null)
              Text(
                nanakshahi.labelWithYear(lang),
                style: HazriText.caption.copyWith(color: c.muted),
              ),
            const SizedBox(height: 16),
            // Hazri and the goal are separate achievements and this sheet
            // says both: the goal in the heading, the hazri underneath with
            // the time it happened.
            if (hazri.isMarked)
              HazriCard(
                colour: c.card2,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    AppIcon(HazriIconData.sunArc, size: 19, color: c.kesriInk),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        hazriLine(context, ref, hazri),
                        style: HazriText.caption.copyWith(color: c.ink2),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: l.hazriSeeDiary,
              secondary: true,
              onPressed: () {
                Navigator.of(context).pop();
                context.go(Routes.diary);
              },
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l.actionDone,
                  style: HazriText.captionStrong.copyWith(color: c.muted)),
            ),
          ],
        ),
      ),
    );
  }
}
