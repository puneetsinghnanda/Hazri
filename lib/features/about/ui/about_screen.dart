import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/widgets/app_mark.dart';
import '../../../core/widgets/surfaces.dart';
import '../../settings/ui/screen_scaffold.dart';
import '../../settings/ui/settings_screen.dart' show appVersion;

/// About and credits (PRD 1.17).
///
/// Every source of text, meanings, transliteration and calendar data is
/// credited here, straight from content.db so the credits cannot drift away
/// from what actually shipped.
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);

    return HazriScreen(
      title: l.aboutTitle,
      children: [
        Center(
          child: Column(
            children: [
              const AppMark(size: 56),
              const SizedBox(height: 10),
              Text(
                l.appName,
                style: HazriText.display26.copyWith(color: c.ink),
              ),
              Text(
                l.settingsVersion(appVersion),
                style: HazriText.caption.copyWith(color: c.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(l.aboutPurpose, style: HazriText.body.copyWith(color: c.ink2)),
        const SizedBox(height: 20),
        // Owner, 2026-11-09: no Gurbani text or meanings sections (their MIT
        // notices are on the Licences screen, main.dart), and no credits for
        // the saakhis or the quiz.
        _PlainGroup(title: l.aboutCalendarSource, body: l.aboutCalendarBody),
        _PlainGroup(title: l.aboutCityData, body: l.aboutCityDataBody),
        _PlainGroup(title: l.aboutFonts, body: l.aboutFontsBody),
        _PlainGroup(title: l.aboutAudioHeading, body: l.aboutNoAudioYet),
        _PlainGroup(title: l.vicharTitle, body: l.aboutVicharBody),
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

class _PlainGroup extends StatelessWidget {
  const _PlainGroup({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Eyebrow(title),
          const SizedBox(height: 8),
          HazriCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              body,
              style: HazriText.bodySmall.copyWith(color: c.ink2),
            ),
          ),
        ],
      ),
    );
  }
}
