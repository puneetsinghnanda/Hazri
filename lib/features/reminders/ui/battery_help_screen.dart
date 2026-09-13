import 'package:flutter/material.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/widgets/surfaces.dart';
import '../../settings/ui/screen_scaffold.dart';

/// "Reminders not arriving?" — the per-maker battery guidance (PRD 1.10).
///
/// It explains what to change and stops there: the app never asks for a
/// battery exemption on its own.
class BatteryHelpScreen extends StatelessWidget {
  const BatteryHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);

    return HazriScreen(
      title: l.batteryHelpTitle,
      children: [
        Text(l.batteryHelpBody, style: HazriText.body.copyWith(color: c.ink2)),
        const SizedBox(height: 16),
        for (final tip in [
          l.batteryHelpSamsung,
          l.batteryHelpXiaomi,
          l.batteryHelpVivo,
          l.batteryHelpOppo,
          l.batteryHelpOnePlus,
        ]) ...[
          HazriCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Text(tip, style: HazriText.bodySmall.copyWith(color: c.ink2)),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}
