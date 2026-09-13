import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/content_db.dart';
import '../../../core/db/content_repository.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/widgets/app_mark.dart';
import '../../../core/widgets/surfaces.dart';
import '../../hukamnama/data/hukamnama_repository.dart';
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
    final sources = ref.watch(contentSourcesProvider).value ?? const <SourceRow>[];
    final hukamnama = ref.watch(hukamnamaRepositoryProvider);

    List<SourceRow> of(String kind) => sources.where((s) => s.kind == kind).toList();

    return HazriScreen(
      title: l.aboutTitle,
      children: [
        Center(
          child: Column(
            children: [
              const AppMark(size: 56),
              const SizedBox(height: 10),
              Text(l.appName, style: HazriText.display26.copyWith(color: c.ink)),
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
        _SourceGroup(title: l.aboutTextSources, sources: [...of('text'), ...of('translit')]),
        _SourceGroup(title: l.aboutMeaningSources, sources: of('meaning')),
        _SourceGroup(title: l.aboutCalendarSource, sources: of('calendar')),
        const SizedBox(height: 12),
        _PlainGroup(
          title: l.aboutCityData,
          body: 'City names, coordinates and time zones are bundled with the app '
              'and never sent anywhere.',
        ),
        _PlainGroup(title: l.aboutFonts, body: l.aboutFontsBody),
        _PlainGroup(title: l.settingsSectionAudio, body: l.aboutNoAudioYet),
        if (!hukamnama.isConfigured)
          _PlainGroup(title: l.hukamnamaTitle, body: l.hukamnamaNotConfiguredBody),
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

class _SourceGroup extends StatelessWidget {
  const _SourceGroup({required this.title, required this.sources});

  final String title;
  final List<SourceRow> sources;

  @override
  Widget build(BuildContext context) {
    if (sources.isEmpty) return const SizedBox.shrink();
    final c = context.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Eyebrow(title),
          const SizedBox(height: 8),
          HazriCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < sources.length; i++) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sources[i].name,
                          style: HazriText.bodyStrong.copyWith(color: c.ink),
                        ),
                        for (final line in [
                          sources[i].author,
                          sources[i].publisher,
                          sources[i].pubDate,
                          sources[i].licence,
                          sources[i].url,
                          sources[i].notes,
                        ])
                          if (line != null && line.isNotEmpty)
                            Text(
                              line,
                              style: HazriText.caption.copyWith(color: c.muted),
                            ),
                      ],
                    ),
                  ),
                  if (i != sources.length - 1)
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Divider(height: 1, color: c.rule),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
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
            child: Text(body, style: HazriText.bodySmall.copyWith(color: c.ink2)),
          ),
        ],
      ),
    );
  }
}
