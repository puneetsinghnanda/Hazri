import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/db/content_db.dart';
import '../../../core/db/content_repository.dart';
import '../../../core/db/user_db.dart';
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
import '../../reminders/data/reminder_service.dart';
import '../../reminders/data/reminders_controller.dart';
import '../../reminders/domain/reminder_plan.dart';
import '../../reminders/ui/city_picker_sheet.dart';
import '../../reminders/ui/reminder_row.dart';

/// Setup steps 1-3 (PRD 1.2). Nothing is required except the language.
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
                  3 => const _StepReminders(),
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
            width: 44,
            child: canGoBack
                ? CardIconButton(
                    icon: HazriIconData.chevronLeft,
                    tooltip: L.of(context).actionBack,
                    onPressed: () => context.go(Routes.setup(step - 1)),
                  )
                : null,
          ),
          const Spacer(),
          for (var i = 1; i <= 3; i++)
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
          const SizedBox(width: 44),
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
          note: '${l.chipWorksOffline} · ${l.chipNoLogin} · ${l.chipNoAdsOnGurbani}',
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

  static const _sample = (
    gurmukhi: 'ਆਦਿ ਸਚੁ ਜੁਗਾਦਿ ਸਚੁ ॥',
    devanagari: 'आदि सचु जुगादि सचु ॥',
    roman: 'aad sach jugaad sach',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final s = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

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
                sample: _sample.gurmukhi,
                style: HazriText.gurmukhi(s.readerFontSize),
                selected: s.script == GurbaniScript.gurmukhi,
                onTap: () => notifier.setScript(GurbaniScript.gurmukhi),
              ),
              const SizedBox(height: 10),
              _ScriptCard(
                eyebrow: 'हिन्दी · DEVANAGARI',
                sample: _sample.devanagari,
                style: HazriText.devanagari(s.readerFontSize - 1),
                selected: s.script == GurbaniScript.devanagari,
                onTap: () => notifier.setScript(GurbaniScript.devanagari),
              ),
              const SizedBox(height: 10),
              _ScriptCard(
                eyebrow: 'ROMAN',
                sample: _sample.roman,
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
                            l.elderModeSub,
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
          onPressed: () => context.go(Routes.setup(3)),
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

// ------------------------------------------------------------------- step 3

class _StepReminders extends ConsumerStatefulWidget {
  const _StepReminders();

  @override
  ConsumerState<_StepReminders> createState() => _StepRemindersState();
}

class _StepRemindersState extends ConsumerState<_StepReminders> {
  bool? _exactAllowed;
  bool _askedNotifications = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _requestPermissions());
  }

  /// The notification permission is asked for on reaching this step; denying it
  /// never blocks setup (PRD 1.2 AC).
  Future<void> _requestPermissions() async {
    if (_askedNotifications) return;
    _askedNotifications = true;
    final service = ref.read(reminderServiceProvider);
    await service.requestNotificationPermission();
    final exact = await service.canScheduleExact();
    if (mounted) setState(() => _exactAllowed = exact);
  }

  Future<void> _requestExactAlarm() async {
    final service = ref.read(reminderServiceProvider);
    await service.requestExactAlarmPermission();
    await ref.read(settingsProvider.notifier).setExactAlarmAsked(true);
    final exact = await service.canScheduleExact();
    if (mounted) setState(() => _exactAllowed = exact);
  }

  Future<void> _finish() async {
    await ref.read(settingsProvider.notifier).setOnboardingDone(true);
    await ref.read(reminderSchedulerProvider).reschedule();
    if (mounted) context.go(Routes.today);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    final reminders = ref.watch(remindersProvider).value ?? const <Reminder>[];
    final cityId = ref.watch(settingsProvider).cityId;
    final city = ref.watch(citiesProvider).value?.where((x) => x.id == cityId).firstOrNull;
    final localeCode = Localizations.localeOf(context).languageCode;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(HazriSize.gutter, 16, HazriSize.gutter, 8),
            children: [
              Text(l.setupRemindersTitle, style: HazriText.display22.copyWith(color: c.ink)),
              const SizedBox(height: 8),
              Text(l.setupRemindersBody, style: HazriText.bodySmall.copyWith(color: c.ink2)),
              const SizedBox(height: 16),
              HazriCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (final id in ReminderIds.defaults)
                      ReminderRow(
                        reminderId: id,
                        reminder: reminders.where((r) => r.id == id).firstOrNull,
                        showDivider: id != ReminderIds.defaults.last,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (_exactAllowed == false)
                HazriCard(
                  colour: c.kesriSoft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AppIcon(HazriIconData.clock, size: 20, color: c.kesriInk),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l.allowOnTimeTitle,
                              style: HazriText.bodyStrong.copyWith(color: c.kesriInk),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l.allowOnTimeBody,
                        style: HazriText.bodySmall.copyWith(color: c.kesriInk),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: PrimaryButton(
                          label: l.actionAllow,
                          expanded: false,
                          minHeight: 44,
                          onPressed: _requestExactAlarm,
                        ),
                      ),
                    ],
                  ),
                )
              else if (_exactAllowed == true)
                HazriCard(
                  colour: c.sageSoft,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      AppIcon(HazriIconData.check, size: 18, color: c.sage),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l.allowOnTimeGranted,
                          style: HazriText.bodySmall.copyWith(color: c.sage),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 10),
              HazriCard(
                onTap: () => showCityPickerSheet(context),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    AppIcon(HazriIconData.pin, size: 18, color: c.ink2),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l.usingCityForSun(_cityName(city, localeCode)),
                        style: HazriText.bodySmall.copyWith(color: c.ink2),
                      ),
                    ),
                    Text(
                      l.actionChange,
                      style: HazriText.chip.copyWith(color: c.kesriInk),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Audio is not part of this build, so the setup step says so
              // rather than showing a download that never starts (PRD 1.2).
              HazriCard(
                colour: c.card2,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppIcon(HazriIconData.headphones, size: 20, color: c.muted),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.audioNotInBuild,
                            style: HazriText.bodyStrong.copyWith(color: c.ink2),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l.audioNotInBuildSub,
                            style: HazriText.bodySmall.copyWith(color: c.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _StepFooter(label: l.beginMyNitnem, onPressed: _finish),
      ],
    );
  }

  static String _cityName(CityRow? city, String languageCode) {
    if (city == null) return '—';
    return switch (languageCode) {
      'pa' => city.namePa,
      'hi' => city.nameHi,
      _ => city.nameEn,
    };
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
