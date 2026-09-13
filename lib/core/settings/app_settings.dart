import 'package:flutter/material.dart';

/// Which script Gurbani is shown in.
enum GurbaniScript { gurmukhi, devanagari, roman }

/// Which language meanings are shown in.
enum MeaningLanguage { pa, hi, en }

/// What plays during a Simran session.
enum SimranSound { silence, drone, bell }

/// Every user preference that lives in `shared_preferences` (PRD §7.2).
@immutable
class AppSettings {
  const AppSettings({
    this.locale = const Locale('en'),
    this.script = GurbaniScript.gurmukhi,
    this.showRomanUnderGurmukhi = false,
    this.meaningsOn = true,
    this.meaningsLang = MeaningLanguage.en,
    this.visraamOn = true,
    this.larivaarOn = false,
    this.readerFontSize = 22,
    this.keepScreenOn = true,
    this.followAudio = true,
    this.themeMode = ThemeMode.system,
    this.elderMode = false,
    this.cityId = 'new_delhi',
    this.speed = 1.0,
    this.simranSound = SimranSound.silence,
    this.simranMinutes = 5,
    this.onboardingDone = false,
    this.exactAlarmAsked = false,
    this.analyticsEnabled = false,
  });

  final Locale locale;
  final GurbaniScript script;
  final bool showRomanUnderGurmukhi;
  final bool meaningsOn;
  final MeaningLanguage meaningsLang;
  final bool visraamOn;
  final bool larivaarOn;
  final double readerFontSize;
  final bool keepScreenOn;
  final bool followAudio;
  final ThemeMode themeMode;
  final bool elderMode;
  final String cityId;
  final double speed;
  final SimranSound simranSound;
  final int simranMinutes;
  final bool onboardingDone;
  final bool exactAlarmAsked;
  final bool analyticsEnabled;

  /// In elder mode the reader never goes below 30 sp (PRD 1.12).
  double get effectiveReaderFontSize =>
      elderMode ? (readerFontSize < 30 ? 30 : readerFontSize) : readerFontSize;

  AppSettings copyWith({
    Locale? locale,
    GurbaniScript? script,
    bool? showRomanUnderGurmukhi,
    bool? meaningsOn,
    MeaningLanguage? meaningsLang,
    bool? visraamOn,
    bool? larivaarOn,
    double? readerFontSize,
    bool? keepScreenOn,
    bool? followAudio,
    ThemeMode? themeMode,
    bool? elderMode,
    String? cityId,
    double? speed,
    SimranSound? simranSound,
    int? simranMinutes,
    bool? onboardingDone,
    bool? exactAlarmAsked,
    bool? analyticsEnabled,
  }) {
    return AppSettings(
      locale: locale ?? this.locale,
      script: script ?? this.script,
      showRomanUnderGurmukhi: showRomanUnderGurmukhi ?? this.showRomanUnderGurmukhi,
      meaningsOn: meaningsOn ?? this.meaningsOn,
      meaningsLang: meaningsLang ?? this.meaningsLang,
      visraamOn: visraamOn ?? this.visraamOn,
      larivaarOn: larivaarOn ?? this.larivaarOn,
      readerFontSize: readerFontSize ?? this.readerFontSize,
      keepScreenOn: keepScreenOn ?? this.keepScreenOn,
      followAudio: followAudio ?? this.followAudio,
      themeMode: themeMode ?? this.themeMode,
      elderMode: elderMode ?? this.elderMode,
      cityId: cityId ?? this.cityId,
      speed: speed ?? this.speed,
      simranSound: simranSound ?? this.simranSound,
      simranMinutes: simranMinutes ?? this.simranMinutes,
      onboardingDone: onboardingDone ?? this.onboardingDone,
      exactAlarmAsked: exactAlarmAsked ?? this.exactAlarmAsked,
      analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
    );
  }

  /// The defaults each app language implies (PRD 1.2, step 1).
  ///
  /// Punjabi reads in Gurmukhi, Hindi in Devanagari, and English in Gurmukhi
  /// with the Roman line underneath.
  static AppSettings defaultsForLocale(Locale locale, AppSettings base) {
    switch (locale.languageCode) {
      case 'pa':
        return base.copyWith(
          locale: locale,
          script: GurbaniScript.gurmukhi,
          showRomanUnderGurmukhi: false,
          meaningsLang: MeaningLanguage.pa,
        );
      case 'hi':
        return base.copyWith(
          locale: locale,
          script: GurbaniScript.devanagari,
          showRomanUnderGurmukhi: false,
          meaningsLang: MeaningLanguage.hi,
        );
      default:
        return base.copyWith(
          locale: locale,
          script: GurbaniScript.gurmukhi,
          showRomanUnderGurmukhi: true,
          meaningsLang: MeaningLanguage.en,
        );
    }
  }
}
