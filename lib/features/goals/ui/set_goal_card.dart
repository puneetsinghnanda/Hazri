import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/surfaces.dart';
import '../data/goals_controller.dart';
import 'add_goal_sheet.dart';

/// The Set Goal card (04-goals §7.1, GL1): shown whenever no goal is active.
/// The first time it invites; after a goal completes it says so. Not
/// dismissible.
class SetGoalCard extends ConsumerWidget {
  const SetGoalCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final again = ref.watch(hadGoalProvider).value ?? false;
    return HazriCard(
      onTap: () => showGoalItemSheet(context),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: c.kesriSoft, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: AppIcon(HazriIconData.sparkle, size: 20, color: c.kesriInk),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.goalSetCardTitle, style: HazriText.bodyStrong.copyWith(color: c.ink)),
                const SizedBox(height: 2),
                Text(
                  again ? l.goalSetCardSubtitleAgain : l.goalSetCardSubtitleFirst,
                  style: HazriText.bodySmall.copyWith(color: c.ink2),
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
