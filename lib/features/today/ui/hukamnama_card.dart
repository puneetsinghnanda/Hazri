import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/time/date_format.dart';
import '../../../core/widgets/surfaces.dart';
import '../../hukamnama/data/hukamnama_repository.dart';
import '../../hukamnama/ui/share_card.dart';

/// Today's Hukamnama card (PRD 1.3).
///
/// With no source configured — the Phase 1 position while the provider's terms
/// are undecided — the card says so plainly instead of showing an error or a
/// spinner that never resolves.
class HukamnamaCard extends ConsumerWidget {
  const HukamnamaCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final settings = ref.watch(settingsProvider);
    final repo = ref.watch(hukamnamaRepositoryProvider);
    final hukamnama = ref.watch(todayHukamnamaProvider).value;

    if (hukamnama == null) {
      return HazriCard(
        onTap: () => context.push(Routes.hukamnama),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.todayHukamnama, style: HazriText.bodyStrong.copyWith(color: c.ink)),
            const SizedBox(height: 6),
            Text(
              repo.isConfigured ? l.hukamnamaOfflineEmpty : l.hukamnamaNotConfigured,
              style: HazriText.bodySmall.copyWith(color: c.muted),
            ),
          ],
        ),
      );
    }

    final first = hukamnama.lines.firstOrNull;
    final dates = HazriDates.of(context);
    final meaning = first?.meanings[settings.meaningsLang];

    return HazriCard(
      onTap: () => context.push(Routes.hukamnama),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  l.todayHukamnama,
                  style: HazriText.bodyStrong.copyWith(color: c.ink),
                ),
              ),
              Text(
                [
                  if (hukamnama.ang != null) 'Ang ${hukamnama.ang}',
                  if (hukamnama.raag != null) hukamnama.raag!,
                ].join(' · '),
                style: HazriText.captionStrong.copyWith(color: c.muted),
              ),
            ],
          ),
          if (first != null) ...[
            const SizedBox(height: 8),
            Text(
              first.textFor(settings.script),
              style: _scriptStyle(settings.script).copyWith(color: c.ink),
            ),
          ],
          if (meaning != null) ...[
            const SizedBox(height: 6),
            Text(meaning, style: HazriText.bodySmall.copyWith(color: c.ink2)),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              HazriChip(
                icon: HazriIconData.share,
                label: l.actionShareCard,
                onTap: () => showShareCardPreview(context, hukamnama),
              ),
              HazriChip(
                icon: HazriIconData.book,
                label: l.actionRead,
                onTap: () => context.push(Routes.hukamnama),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l.hukamnamaSavedOn(dates.shortDate(hukamnama.date)),
            style: HazriText.caption.copyWith(color: c.muted),
          ),
        ],
      ),
    );
  }

  static TextStyle _scriptStyle(GurbaniScript script) => switch (script) {
    GurbaniScript.gurmukhi => HazriText.gurmukhi(18),
    GurbaniScript.devanagari => HazriText.devanagari(17),
    GurbaniScript.roman => HazriText.roman(16),
  };
}
