import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/surfaces.dart';

/// Design 36 — the sheet that asks, over Today.
///
/// It says "Hazri works fully without this" first and means it, and Not now
/// sits next to Set up rather than below the fold. Somebody who never taps
/// either is using Phase 1's app, which is the promise CLAUDE.md rule 4
/// makes on the app's behalf.
Future<void> showJoinSangatSheet(BuildContext context) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _JoinSangatSheet(),
    );

class _JoinSangatSheet extends ConsumerWidget {
  const _JoinSangatSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);

    return Container(
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 10,
        bottom: 24 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: c.rule,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(l.sangatSheetTitle,
              style: HazriText.display22.copyWith(color: c.ink)),
          const SizedBox(height: 4),
          Text(l.sangatSheetBody,
              style: HazriText.bodySmall.copyWith(color: c.muted)),
          const SizedBox(height: 20),
          _Perk(
            icon: HazriIconData.sangat,
            title: l.sangatPerkSee,
            body: l.sangatPerkSeeSub,
          ),
          const SizedBox(height: 14),
          _Perk(
            icon: HazriIconData.globe,
            title: l.sangatPerkGoal,
            body: l.sangatPerkGoalSub,
          ),
          const SizedBox(height: 14),
          _Perk(
            icon: HazriIconData.check,
            title: l.sangatPerkDiary,
            body: l.sangatPerkDiarySub,
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: l.sangatSetUp,
            onPressed: () {
              Navigator.of(context).pop();
              context.push(Routes.sangatJoin);
            },
          ),
          const SizedBox(height: 10),
          PrimaryButton(
            label: l.sangatNotNow,
            secondary: true,
            minHeight: 48,
            onPressed: () {
              // Remembered, so Today can stop asking and show the hazri card
              // in the banner's place. Nothing else changes: the menu's
              // account card and the Sangat tab still open the door.
              ref.read(settingsProvider.notifier).setSangatDeclined(true);
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: 14),
          Text(
            l.sangatNoAds,
            textAlign: TextAlign.center,
            style: HazriText.caption.copyWith(color: c.muted),
          ),
        ],
      ),
    );
  }
}

class _Perk extends StatelessWidget {
  const _Perk({required this.icon, required this.title, required this.body});

  final String icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: c.kesriSoft,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Center(child: AppIcon(icon, size: 20, color: c.kesriInk)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: HazriText.bodyStrong.copyWith(color: c.ink)),
              Text(body, style: HazriText.caption.copyWith(color: c.muted)),
            ],
          ),
        ),
      ],
    );
  }
}
