import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/db/content_repository.dart';
import '../../../core/db/user_db.dart' show Reminder;
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/widgets/surfaces.dart';
import '../../audio/data/audio_controller.dart';
import '../../audio/data/notification_access.dart';
import '../../goals/data/goals_controller.dart';
import '../../reminders/data/reminder_service.dart';
import '../../reminders/data/reminders_controller.dart';
import '../../reminders/domain/reminder_plan.dart';
import '../../reminders/ui/city_picker_sheet.dart';
import '../../reminders/ui/reminder_row.dart';
import 'screen_scaffold.dart';

final _exactAlarmProvider = FutureProvider<bool>(
  (ref) => ref.watch(reminderServiceProvider).canScheduleExact(),
);

/// Settings (Design 27). Every change persists immediately.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);
    final lang = Localizations.localeOf(context).languageCode;
    final reminders = ref.watch(remindersProvider).value ?? const <Reminder>[];
    final goals = ref.watch(goalsSummaryProvider);
    final exact = ref.watch(_exactAlarmProvider).value;
    final hasAudio = ref.watch(hasAudioProvider);
    final city = ref
        .watch(citiesProvider)
        .value
        ?.where((x) => x.id == s.cityId)
        .firstOrNull;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: PhoneWidth(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(HazriSize.gutter, 14, HazriSize.gutter, 24),
            children: [
              // Pushed from the menu rather than a tab, so this is a way back
              // and not another menu button.
              Row(
                children: [
                  CardIconButton(
                    icon: HazriIconData.chevronLeft,
                    tooltip: l.actionBack,
                    onPressed: () =>
                        context.canPop() ? context.pop() : context.go(Routes.today),
                    size: 40,
                    iconSize: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(l.settingsTitle,
                        style: HazriText.display26.copyWith(color: c.ink)),
                  ),
                ],
              ),

              SettingsSection(
                title: l.settingsSectionLanguage,
                children: [
                  _SegmentedRow(
                    title: l.settingsAppLanguage,
                    options: const [
                      ('pa', 'ਪੰਜਾਬੀ'),
                      ('hi', 'हिन्दी'),
                      ('en', 'English'),
                    ],
                    value: s.locale.languageCode,
                    onChanged: (v) => n.setLocale(Locale(v)),
                  ),
                ],
              ),

              SettingsSection(
                title: l.settingsSectionReading,
                children: [
                  _SegmentedRow(
                    title: l.settingsGurbaniScript,
                    subtitle: l.settingsGurbaniScriptSub,
                    options: [
                      (GurbaniScript.gurmukhi.name, l.scriptGurmukhi),
                      (GurbaniScript.devanagari.name, l.scriptDevanagari),
                      (GurbaniScript.roman.name, l.scriptRoman),
                    ],
                    value: s.script.name,
                    onChanged: (v) =>
                        n.setScript(GurbaniScript.values.firstWhere((x) => x.name == v)),
                  ),
                  SettingsRow(
                    title: l.readerShowMeanings,
                    subtitle: l.settingsShowMeaningsSub,
                    trailing: Switch(value: s.meaningsOn, onChanged: n.setMeaningsOn),
                  ),
                  if (s.meaningsOn)
                    _SegmentedRow(
                      title: l.readerMeaningLanguage,
                      options: [
                        (MeaningLanguage.pa.name, l.langPunjabi),
                        (MeaningLanguage.hi.name, l.langHindi),
                        (MeaningLanguage.en.name, l.langEnglish),
                      ],
                      value: s.meaningsLang.name,
                      onChanged: (v) => n.setMeaningsLang(
                        MeaningLanguage.values.firstWhere((x) => x.name == v),
                      ),
                    ),
                  SettingsRow(
                    title: l.readerPauseMarks,
                    subtitle: l.readerPauseMarksSub,
                    trailing: Switch(value: s.visraamOn, onChanged: n.setVisraam),
                  ),
                  SettingsRow(
                    title: l.readerLarivaar,
                    subtitle: l.readerLarivaarSub,
                    trailing: Switch(value: s.larivaarOn, onChanged: n.setLarivaar),
                  ),
                  _SliderRow(
                    title: l.textSize,
                    value: s.readerFontSize,
                    onChanged: n.setReaderFontSize,
                  ),
                  SettingsRow(
                    title: l.readerKeepScreenOn,
                    trailing: Switch(value: s.keepScreenOn, onChanged: n.setKeepScreenOn),
                  ),
                  SettingsRow(
                    title: l.readerFollowAudio,
                    subtitle: l.readerFollowAudioSub,
                    trailing: Switch(value: s.followAudio, onChanged: n.setFollowAudio),
                  ),
                ],
              ),

              SettingsSection(
                title: l.settingsSectionAudio,
                children: [
                  SettingsRow(
                    title: l.settingsNitnemAudio,
                    subtitle: hasAudio ? l.audioIncludedSub : l.audioNotInBuildSub,
                    value: hasAudio ? l.settingsAudioOnPhone : l.comingSoonShort,
                  ),
                  if (hasAudio)
                    SettingsRow(
                      title: l.settingsLockScreenControls,
                      subtitle: switch (ref.watch(notificationsAllowedProvider).value) {
                        null => null,
                        true => l.settingsLockScreenAllowed,
                        false => l.settingsLockScreenBlocked,
                      },
                      value: ref.watch(notificationsAllowedProvider).value == false
                          ? l.actionAllow
                          : null,
                      onTap: ref.watch(notificationsAllowedProvider).value == false
                          ? () =>
                              ref.read(notificationsAllowedProvider.notifier).allow()
                          : null,
                    ),
                  _SegmentedRow(
                    title: l.playerSpeed,
                    options: const [('0.75', '0.75×'), ('1.0', '1.0×'), ('1.5', '1.5×')],
                    value: s.speed.toStringAsFixed(s.speed == 0.75 ? 2 : 1),
                    onChanged: (v) =>
                        ref.read(playbackControllerProvider).setSpeed(double.parse(v)),
                  ),
                ],
              ),

              SettingsSection(
                title: l.settingsSectionVersions,
                children: [
                  SettingsRow(
                    title: l.versionsNote,
                    value: 'SGPC',
                  ),
                ],
              ),

              SettingsSection(
                title: l.settingsSectionReminders,
                children: [
                  for (final id in ReminderIds.defaults)
                    ReminderRow(
                      reminderId: id,
                      reminder: reminders.where((r) => r.id == id).firstOrNull,
                      showDivider: false,
                    ),
                  SettingsRow(
                    title: l.settingsPaathGoals,
                    subtitle: l.settingsPaathGoalsSub,
                    value: l.settingsGoalsCount(goals.total),
                    onTap: () => context.push(Routes.goals),
                  ),
                  SettingsRow(
                    title: l.settingsOnTimeReminders,
                    subtitle: exact == null
                        ? null
                        : exact
                            ? l.settingsOnTimeAllowed
                            : l.settingsOnTimeNotAllowed,
                    value: exact == false ? l.actionAllow : null,
                    onTap: exact == false
                        ? () async {
                            await ref
                                .read(reminderServiceProvider)
                                .requestExactAlarmPermission();
                            ref.invalidate(_exactAlarmProvider);
                          }
                        : null,
                  ),
                  SettingsRow(
                    title: l.settingsSunFor,
                    value: city == null
                        ? '—'
                        : switch (lang) {
                            'pa' => city.namePa,
                            'hi' => city.nameHi,
                            _ => city.nameEn,
                          },
                    onTap: () => showCityPickerSheet(context),
                  ),
                  SettingsRow(
                    title: l.notifTitle,
                    subtitle: l.notifOwnPractice,
                    onTap: () => context.push(Routes.notifications),
                  ),
                  SettingsRow(
                    title: l.settingsRemindersNotArriving,
                    onTap: () => context.push(Routes.batteryHelp),
                  ),
                ],
              ),

              SettingsSection(
                title: l.settingsSectionDisplay,
                children: [
                  _SegmentedRow(
                    title: l.settingsTheme,
                    options: [
                      (ThemeMode.system.name, l.settingsThemeAuto),
                      (ThemeMode.light.name, l.settingsThemeLight),
                      (ThemeMode.dark.name, l.settingsThemeDark),
                    ],
                    value: s.themeMode.name,
                    onChanged: (v) =>
                        n.setThemeMode(ThemeMode.values.firstWhere((x) => x.name == v)),
                  ),
                  SettingsRow(
                    title: l.elderMode,
                    subtitle: l.elderModeSub,
                    trailing: Switch(value: s.elderMode, onChanged: n.setElderMode),
                  ),
                ],
              ),

              SettingsSection(
                title: l.settingsSectionDiary,
                children: [
                  SettingsRow(
                    title: l.settingsBackup,
                    subtitle: l.settingsBackupSub,
                    value: l.on,
                  ),
                ],
              ),

              SettingsSection(
                title: l.settingsSectionAbout,
                children: [
                  SettingsRow(
                    title: l.settingsAboutCredits,
                    subtitle: l.settingsAboutCreditsSub,
                    onTap: () => context.push(Routes.about),
                  ),
                  SettingsRow(
                    title: l.settingsPrivacy,
                    subtitle: l.settingsPrivacySub,
                    onTap: () => context.push(Routes.privacy),
                  ),
                  SettingsRow(
                    title: l.settingsAnalytics,
                    subtitle: l.settingsAnalyticsSub,
                    trailing: Switch(value: false, onChanged: null),
                  ),
                  SettingsRow(
                    title: l.settingsLicences,
                    onTap: () => context.push(Routes.licences),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              Text(
                l.settingsVersion(appVersion),
                textAlign: TextAlign.center,
                style: HazriText.caption.copyWith(color: c.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kept in one place so About and Settings agree.
const String appVersion = '0.1.0';

class _SegmentedRow extends StatelessWidget {
  const _SegmentedRow({
    required this.title,
    required this.options,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<(String, String)> options;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: HazriText.bodyStrong.copyWith(color: c.ink)),
          if (subtitle != null)
            Text(subtitle!, style: HazriText.bodySmall.copyWith(color: c.muted)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: c.card2,
              borderRadius: BorderRadius.circular(HazriRadius.button),
            ),
            child: Row(
              children: [
                for (final (key, label) in options)
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(13),
                      onTap: () => onChanged(key),
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: value == key ? c.card : Colors.transparent,
                          borderRadius: BorderRadius.circular(13),
                          boxShadow: value == key ? c.shadows : null,
                        ),
                        child: Center(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: HazriText.chip.copyWith(
                              color: value == key ? c.ink : c.muted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({required this.title, required this.value, required this.onChanged});

  final String title;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: HazriText.bodyStrong.copyWith(color: c.ink)),
          ),
          Expanded(
            flex: 2,
            child: Slider(
              value: value,
              min: ReaderType.min,
              max: ReaderType.max,
              divisions: (ReaderType.max - ReaderType.min).round(),
              label: '${value.round()}',
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
