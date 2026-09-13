import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/surfaces.dart';

/// "How Hazri works" — three short tips and a link to About (PRD 1.3).
Future<void> showHelpSheet(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  useSafeArea: true,
  builder: (context) {
    final c = context.colors;
    final l = L.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(HazriSize.gutter, 12, HazriSize.gutter, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: c.rule,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(l.helpSheetTitle, style: HazriText.display22.copyWith(color: c.ink)),
            const SizedBox(height: 14),
            for (final tip in [l.helpTip1, l.helpTip2, l.helpTip3])
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: AppIcon(HazriIconData.check, size: 18, color: c.sage),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(tip, style: HazriText.body.copyWith(color: c.ink2)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            PrimaryButton(
              label: l.helpAboutLink,
              secondary: true,
              onPressed: () {
                Navigator.of(context).pop();
                context.push(Routes.about);
              },
            ),
          ],
        ),
      ),
    );
  },
);
