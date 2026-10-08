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
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/app_mark.dart';
import '../../../core/widgets/surfaces.dart';
import '../../../core/db/content_repository.dart';
import '../../nitnem/domain/bani.dart';
import '../../profile/data/incoming_link.dart';
import '../../sangat/data/sangat_device.dart';

/// Setup: language, then how you read (03-first-run F1). Nothing is required
/// except the language. Reminders are on by default and Android's permission
/// prompt comes at app start (02-notifications), so there is no reminders step.
class SetupScreen extends ConsumerWidget {
  const SetupScreen({super.key, required this.step});

  final int step;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: PhoneWidth(
          child: Column(
            children: [
              _StepHeader(step: step),
              Expanded(
                child: switch (step) {
                  2 => const _StepReading(),
                  _ => const _StepLanguage(),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final canGoBack = step > 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(HazriSize.gutter, 12, HazriSize.gutter, 4),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: canGoBack
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: CardIconButton(
                      icon: HazriIconData.chevronLeft,
                      tooltip: L.of(context).actionBack,
                      onPressed: () => context.go(Routes.setup(step - 1)),
                    ),
                  )
                : null,
          ),
          const Spacer(),
          for (var i = 1; i <= 2; i++)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 4,
              width: i == step ? 26 : 14,
              decoration: BoxDecoration(
                color: i <= step ? c.kesri : c.rule,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          const Spacer(),
          // F8: Skip on How you read is Gurmukhi at the standard size.
          SizedBox(
            width: 64,
            child: step == 2 ? const _SkipButton() : null,
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------- step 1

class _StepLanguage extends ConsumerWidget {
  const _StepLanguage();

  static const _options = [
    ('pa', 'ਪੰਜਾਬੀ', 'Punjabi'),
    ('hi', 'हिन्दी', 'Hindi'),
    ('en', 'English', 'English'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final current = ref.watch(settingsProvider).locale.languageCode;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(HazriSize.gutter, 16, HazriSize.gutter, 8),
            children: [
              Center(
                child: Column(
                  children: [
                    const AppMark(size: 56),
                    const SizedBox(height: 12),
                    Text(l.appName, style: HazriText.display26.copyWith(color: c.ink)),
                    const SizedBox(height: 4),
                    Text(
                      l.tagline,
                      textAlign: TextAlign.center,
                      style: HazriText.body.copyWith(color: c.ink2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(l.setupLanguageTitle, style: HazriText.display22.copyWith(color: c.ink)),
              const SizedBox(height: 14),
              for (final (code, name, sub) in _options) ...[
                _RadioCard(
                  title: name,
                  subtitle: sub,
                  selected: current == code,
                  titleStyle: code == 'pa'
                      ? HazriText.gurmukhi(20, weight: FontWeight.w600)
                      : code == 'hi'
                          ? HazriText.devanagari(19, weight: FontWeight.w600)
                          : HazriText.sectionTitle.copyWith(fontSize: 19),
                  onTap: () =>
                      ref.read(settingsProvider.notifier).setLocale(Locale(code)),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
        _StepFooter(
          note: l.setupLanguageNote,
          label: l.actionContinue,
          onPressed: () => context.go(Routes.setup(2)),
        ),
      ],
    );
  }
}

class _RadioCard extends StatelessWidget {
  const _RadioCard({
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.titleStyle,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return HazriCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: selected ? Border.all(color: c.primary, width: 2) : null,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: (titleStyle ?? HazriText.sectionTitle).copyWith(color: c.ink)),
                if (subtitle != null)
                  Text(subtitle!, style: HazriText.bodySmall.copyWith(color: c.muted)),
              ],
            ),
          ),
          _RadioDot(selected: selected),
        ],
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: selected ? c.primary : c.rule, width: 2),
        color: selected ? c.primary : Colors.transparent,
      ),
      child: selected
          ? Center(child: AppIcon(HazriIconData.check, size: 12, color: c.onPrimary))
          : null,
    );
  }
}

// ------------------------------------------------------------------- step 2

class _StepReading extends ConsumerWidget {
  const _StepReading();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final s = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    // F2: a real line of Gurbani, from content.db like everywhere else.
    final line = ref.watch(setupSampleLineProvider).value;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(HazriSize.gutter, 16, HazriSize.gutter, 8),
            children: [
              Text(l.setupReadingTitle, style: HazriText.display22.copyWith(color: c.ink)),
              const SizedBox(height: 16),
              _ScriptCard(
                eyebrow: 'ਗੁਰਮੁਖੀ · GURMUKHI',
                sample: line?.gurmukhi ?? '',
                style: HazriText.gurmukhi(s.readerFontSize),
                selected: s.script == GurbaniScript.gurmukhi,
                onTap: () => notifier.setScript(GurbaniScript.gurmukhi),
              ),
              const SizedBox(height: 10),
              _ScriptCard(
                eyebrow: 'हिन्दी · DEVANAGARI',
                sample: line?.devanagari ?? '',
                style: HazriText.devanagari(s.readerFontSize - 1),
                selected: s.script == GurbaniScript.devanagari,
                onTap: () => notifier.setScript(GurbaniScript.devanagari),
              ),
              const SizedBox(height: 10),
              _ScriptCard(
                eyebrow: 'ROMAN',
                sample: line?.roman ?? '',
                style: HazriText.roman(s.readerFontSize - 4),
                selected: s.script == GurbaniScript.roman,
                onTap: () => notifier.setScript(GurbaniScript.roman),
              ),
              const SizedBox(height: 18),
              HazriCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(l.textSize, style: HazriText.bodyStrong.copyWith(color: c.ink)),
                        const Spacer(),
                        Text(
                          '${s.readerFontSize.round()}',
                          style: HazriText.captionStrong.copyWith(color: c.muted),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text('A', style: HazriText.body.copyWith(fontSize: 14, color: c.muted)),
                        Expanded(
                          child: Slider(
                            value: s.readerFontSize,
                            min: ReaderType.min,
                            max: ReaderType.max,
                            divisions: (ReaderType.max - ReaderType.min).round(),
                            onChanged: notifier.setReaderFontSize,
                          ),
                        ),
                        Text('A', style: HazriText.body.copyWith(fontSize: 24, color: c.ink)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              HazriCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.elderMode, style: HazriText.bodyStrong.copyWith(color: c.ink)),
                          Text(
                            l.elderModeSetup,
                            style: HazriText.bodySmall.copyWith(color: c.muted),
                          ),
                        ],
                      ),
                    ),
                    Switch(value: s.elderMode, onChanged: notifier.setElderMode),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              HazriCard(
                colour: c.card2,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    AppIcon(HazriIconData.book, size: 18, color: c.ink2),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l.versionsNote,
                        style: HazriText.bodySmall.copyWith(color: c.ink2),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _StepFooter(
          label: l.actionContinue,
          onPressed: () => _finish(context, ref),
        ),
      ],
    );
  }
}

class _ScriptCard extends StatelessWidget {
  const _ScriptCard({
    required this.eyebrow,
    required this.sample,
    required this.style,
    required this.selected,
    required this.onTap,
  });

  final String eyebrow;
  final String sample;
  final TextStyle style;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return HazriCard(
      onTap: onTap,
      border: selected ? Border.all(color: c.primary, width: 2) : null,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Eyebrow(eyebrow),
                const SizedBox(height: 4),
                Text(sample, style: style.copyWith(color: c.ink)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _RadioDot(selected: selected),
        ],
      ),
    );
  }
}

class _StepFooter extends StatelessWidget {
  const _StepFooter({required this.label, required this.onPressed, this.note});

  final String label;
  final VoidCallback onPressed;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(HazriSize.gutter, 8, HazriSize.gutter, 16),
      child: Column(
        children: [
          if (note != null) ...[
            Text(
              note!,
              textAlign: TextAlign.center,
              style: HazriText.caption.copyWith(color: c.muted),
            ),
            const SizedBox(height: 12),
          ],
          PrimaryButton(label: label, onPressed: onPressed),
        ],
      ),
    );
  }
}

/// Formats today's Auto time for a reminder row, e.g. "4:30 AM".
String formatAutoTime(BuildContext context, DateTime? at) =>
    at == null ? '—' : HazriDates.of(context).time(at);

/// The first verse of Japji Sahib, shown on How you read (F2).
final setupSampleLineProvider = FutureProvider<GurbaniLine?>((ref) async {
  final banis = await ref.watch(banisProvider.future);
  final japji = banis.where((b) => b.id == 'JAPJ').firstOrNull;
  if (japji?.versionId == null) return null;
  final lines = await ref.watch(baniLinesProvider(japji!.versionId!).future);
  return lines.where((x) => !x.isHeading).firstOrNull;
});

class _SkipButton extends ConsumerWidget {
  const _SkipButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    return TextButton(
      onPressed: () async {
        final n = ref.read(settingsProvider.notifier);
        await n.setScript(GurbaniScript.gurmukhi);
        await n.setReaderFontSize(ReaderType.gurmukhiDefault);
        if (context.mounted) await _finish(context, ref);
      },
      child: Text(
        L.of(context).actionSkip,
        style: HazriText.bodyStrong.copyWith(color: c.muted),
      ),
    );
  }
}

/// Ends setup and opens Today, then whatever waited for it (F7): a link
/// opened before setup, else an invite carried through the Play install.
/// The notification prompt has already come at app start (F6).
Future<void> _finish(BuildContext context, WidgetRef ref) async {
  // Read before Today replaces this screen and its ref goes with it.
  final prefs = ref.read(sharedPreferencesProvider);
  final invite = ref.read(installInviteProvider);
  await ref.read(settingsProvider.notifier).setOnboardingDone(true);
  if (!context.mounted) return;
  final router = GoRouter.of(context);
  router.go(Routes.today);
  final held = await takeHeldLink(prefs);
  final code = held == null ? await invite.take() : null;
  final next = held ?? (code == null ? null : Routes.sangatJoin(code));
  if (next != null) router.push(next);
}
