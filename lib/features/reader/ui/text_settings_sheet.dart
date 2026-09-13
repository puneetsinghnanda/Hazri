import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/widgets/surfaces.dart';

/// The reader's text settings sheet (PRD 1.5). Everything is live: changes
/// apply to the page behind the sheet as they are made.
Future<void> showTextSettingsSheet(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => const _TextSettingsSheet(),
);

class _TextSettingsSheet extends ConsumerWidget {
  const _TextSettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
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
            Text(l.readerTextSettings, style: HazriText.display22.copyWith(color: c.ink)),
            const SizedBox(height: 16),
            Text(l.textSize, style: HazriText.bodyStrong.copyWith(color: c.ink)),
            Row(
              children: [
                Text('A', style: HazriText.body.copyWith(fontSize: 14, color: c.muted)),
                Expanded(
                  child: Slider(
                    value: s.readerFontSize,
                    min: ReaderType.min,
                    max: ReaderType.max,
                    divisions: (ReaderType.max - ReaderType.min).round(),
                    label: '${s.readerFontSize.round()}',
                    onChanged: n.setReaderFontSize,
                  ),
                ),
                Text('A', style: HazriText.body.copyWith(fontSize: 26, color: c.ink)),
              ],
            ),
            const SizedBox(height: 8),
            _SwitchRow(
              title: l.readerShowMeanings,
              value: s.meaningsOn,
              onChanged: n.setMeaningsOn,
            ),
            if (s.meaningsOn)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Wrap(
                  spacing: 8,
                  children: [
                    for (final lang in MeaningLanguage.values)
                      HazriChip(
                        label: switch (lang) {
                          MeaningLanguage.pa => l.langPunjabi,
                          MeaningLanguage.hi => l.langHindi,
                          MeaningLanguage.en => l.langEnglish,
                        },
                        background: s.meaningsLang == lang ? c.kesriSoft : c.card2,
                        foreground: s.meaningsLang == lang ? c.kesriInk : c.ink2,
                        onTap: () => n.setMeaningsLang(lang),
                      ),
                  ],
                ),
              ),
            _SwitchRow(
              title: l.readerRomanUnder,
              value: s.showRomanUnderGurmukhi,
              onChanged: n.setShowRomanUnder,
              enabled: s.script != GurbaniScript.roman,
            ),
            _SwitchRow(
              title: l.readerPauseMarks,
              subtitle: l.readerPauseMarksSub,
              value: s.visraamOn,
              onChanged: n.setVisraam,
            ),
            _SwitchRow(
              title: l.readerLarivaar,
              subtitle: l.readerLarivaarSub,
              value: s.larivaarOn,
              onChanged: n.setLarivaar,
            ),
            _SwitchRow(
              title: l.readerKeepScreenOn,
              value: s.keepScreenOn,
              onChanged: n.setKeepScreenOn,
            ),
            _SwitchRow(
              title: l.readerFollowAudio,
              subtitle: l.readerFollowAudioSub,
              value: s.followAudio,
              onChanged: n.setFollowAudio,
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: l.actionDone,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.enabled = true,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: HazriText.body.copyWith(color: c.ink)),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: HazriText.caption.copyWith(color: c.muted),
                    ),
                ],
              ),
            ),
            Switch(value: value, onChanged: enabled ? onChanged : null),
          ],
        ),
      ),
    );
  }
}
