import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/time/date_format.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/surfaces.dart';
import '../../settings/ui/screen_scaffold.dart';
import '../data/hukamnama_repository.dart';
import '../domain/hukamnama.dart';
import 'share_card.dart';

/// The daily Hukamnama (Design 24).
class HukamnamaScreen extends ConsumerWidget {
  const HukamnamaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final settings = ref.watch(settingsProvider);
    final repo = ref.watch(hukamnamaRepositoryProvider);
    final hukamnama = ref.watch(todayHukamnamaProvider).value;
    final dates = HazriDates.of(context);

    if (hukamnama == null) {
      return HazriScreen(
        title: l.hukamnamaTitle,
        children: [
          const SizedBox(height: 40),
          Center(child: AppIcon(HazriIconData.book, size: 40, color: c.muted)),
          const SizedBox(height: 20),
          Text(
            repo.isConfigured ? l.hukamnamaOfflineEmpty : l.hukamnamaNotConfigured,
            textAlign: TextAlign.center,
            style: HazriText.bodyStrong.copyWith(color: c.ink),
          ),
          const SizedBox(height: 8),
          Text(
            l.hukamnamaNotConfiguredBody,
            textAlign: TextAlign.center,
            style: HazriText.bodySmall.copyWith(color: c.muted),
          ),
        ],
      );
    }

    return HazriScreen(
      title: l.hukamnamaTitle,
      actions: const [_ScriptSwitchCompact()],
      children: [
        HazriCard(
          colour: c.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.hukamnamaSource,
                style: HazriText.bodyStrong.copyWith(color: c.onPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                [
                  dates.longDate(hukamnama.date),
                  if (hukamnama.ang != null) 'Ang ${hukamnama.ang}',
                  if (hukamnama.raag != null) hukamnama.raag!,
                  if (hukamnama.writer != null) hukamnama.writer!,
                ].join(' · '),
                style: HazriText.bodySmall.copyWith(
                  color: c.onPrimary.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (final line in hukamnama.lines) _HukamnamaLineView(line: line, settings: settings),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          children: [
            HazriChip(
              icon: HazriIconData.share,
              label: l.actionShareCard,
              background: c.kesriSoft,
              foreground: c.kesriInk,
              minHeight: 40,
              onTap: () => showShareCardPreview(context, hukamnama),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          l.hukamnamaSavedOffline,
          style: HazriText.caption.copyWith(color: c.muted),
        ),
      ],
    );
  }
}

class _HukamnamaLineView extends StatelessWidget {
  const _HukamnamaLineView({required this.line, required this.settings});

  final HukamnamaLine line;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    final meaning = line.meanings[settings.meaningsLang];
    final style = switch (settings.script) {
      GurbaniScript.gurmukhi => HazriText.gurmukhi(settings.effectiveReaderFontSize),
      GurbaniScript.devanagari => HazriText.devanagari(settings.effectiveReaderFontSize - 1),
      GurbaniScript.roman => HazriText.roman(settings.effectiveReaderFontSize - 4),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (line.isRahao)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Eyebrow(l.hukamnamaRahao, colour: c.kesriInk),
            ),
          Text(
            line.textFor(settings.script),
            style: style.copyWith(
              color: c.ink,
              fontWeight: line.isRahao ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          if (meaning != null) ...[
            const SizedBox(height: 4),
            Text(
              meaning,
              style: HazriText.body.copyWith(fontSize: 14.5, height: 1.45, color: c.ink2),
            ),
          ],
        ],
      ),
    );
  }
}

class _ScriptSwitchCompact extends ConsumerWidget {
  const _ScriptSwitchCompact();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final current = ref.watch(settingsProvider.select((s) => s.script));
    final options = <(GurbaniScript, String, TextStyle)>[
      (GurbaniScript.gurmukhi, 'ਅ', HazriText.gurmukhi(15, weight: FontWeight.w600)),
      (GurbaniScript.devanagari, 'अ', HazriText.devanagari(15, weight: FontWeight.w600)),
      (GurbaniScript.roman, 'A', HazriText.bodyStrong.copyWith(fontSize: 15)),
    ];

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.card2,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (script, label, style) in options)
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => ref.read(settingsProvider.notifier).setScript(script),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: current == script ? c.card : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: style.copyWith(
                      color: current == script ? c.ink : c.muted,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
