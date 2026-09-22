import 'package:flutter/material.dart';

/// Which script Gurbani is shown in.
enum GurbaniScript { gurmukhi, devanagari, roman }

/// Which language meanings are shown in.
enum MeaningLanguage { pa, hi, en }

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
    this.simranMinutes = 5,
    this.onboardingDone = false,
    this.exactAlarmAsked = false,
    this.analyticsEnabled = false,
    this.diarySync = false,
    this.sangatDeclined = false,
    this.syncWifiOnly = true,
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
  final int simranMinutes;
  final bool onboardingDone;
  final bool exactAlarmAsked;
  final bool analyticsEnabled;

  /// Whether the diary is copied to the account. **Off by default**, and off
  /// is a complete answer: the diary works, the streak works and the whole of
  /// Phase 1 works without it. What it buys is the diary coming back on a new
  /// phone, and nothing else.
  final bool diarySync;

  /// "Not now" was tapped on the join sheet at least once.
  ///
  /// Once it has, Today stops carrying the invitation and carries the hazri
  /// card instead: the sangat is opt-in (rule 4), and somebody who declined
  /// it must still see the thing the app is named after. The account card in
  /// the menu and the Sangat tab remain the ways in.
  final bool sangatDeclined;

  /// **On by default**, because somebody's mobile data is theirs. A diary is
  /// small, but "small" is not a promise anybody made them.
  final bool syncWifiOnly;

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
    int? simranMinutes,
    bool? onboardingDone,
    bool? exactAlarmAsked,
    bool? analyticsEnabled,
    bool? diarySync,
    bool? sangatDeclined,
    bool? syncWifiOnly,
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
      simranMinutes: simranMinutes ?? this.simranMinutes,
      onboardingDone: onboardingDone ?? this.onboardingDone,
      exactAlarmAsked: exactAlarmAsked ?? this.exactAlarmAsked,
      analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
      diarySync: diarySync ?? this.diarySync,
      sangatDeclined: sangatDeclined ?? this.sangatDeclined,
      syncWifiOnly: syncWifiOnly ?? this.syncWifiOnly,
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
