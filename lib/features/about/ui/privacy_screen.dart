import 'package:flutter/material.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/widgets/surfaces.dart';
import '../../settings/ui/screen_scaffold.dart';

/// Privacy (PRD 1.17, §13.1).
///
/// The words here are the reader's copy of PRD §13.1 and are not allowed to
/// run ahead of it. Until Phase 2 this screen said the app made no network
/// requests at all; that stopped being true the moment somebody could join
/// the sangat, so it now says what is actually true of this build — nothing
/// leaves the phone unless you join, and analytics are off.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);

    return HazriScreen(
      title: l.privacyTitle,
      children: [
        Text(l.privacyBody, style: HazriText.body.copyWith(color: c.ink2)),
        const SizedBox(height: 16),
        HazriCard(
          colour: c.sageSoft,
          child: Text(
            l.privacyNoAnalytics,
            style: HazriText.bodySmall.copyWith(color: c.sage),
          ),
        ),
        const SizedBox(height: 16),
        HazriCard(
          colour: c.card2,
          child: Text(
            l.privacySangat,
            style: HazriText.bodySmall.copyWith(color: c.ink2),
          ),
        ),
        const SizedBox(height: 16),
        HazriCard(
          colour: c.card2,
          child: Text(
            '${l.chipWorksOffline} · ${l.chipNoLogin} · ${l.chipNoAdsOnGurbani}',
            textAlign: TextAlign.center,
            style: HazriText.bodySmall.copyWith(color: c.ink2),
          ),
        ),
      ],
    );
  }
}
