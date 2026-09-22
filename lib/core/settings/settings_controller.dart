import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_settings.dart';

/// Set during bootstrap in `main.dart`.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('SharedPreferences must be overridden at startup'),
);

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

/// Reads and writes every preference, persisting each change immediately.
class SettingsController extends Notifier<AppSettings> {
  static const _kLocale = 'app_locale';
  static const _kScript = 'script';
  static const _kRomanUnder = 'show_roman_under_gurmukhi';
  static const _kMeaningsOn = 'meanings_on';
  static const _kMeaningsLang = 'meanings_lang';
  static const _kVisraam = 'visraam_on';
  static const _kLarivaar = 'larivaar_on';
  static const _kFontSize = 'reader_font_size';
  static const _kKeepScreenOn = 'keep_screen_on';
  static const _kFollowAudio = 'follow_audio';
  static const _kTheme = 'theme';
  static const _kElder = 'elder_mode';
  static const _kCity = 'city_id';
  static const _kSpeed = 'speed';
  static const _kSimranMinutes = 'simran_minutes';
  static const _kOnboardingDone = 'onboarding_done';
  static const _kExactAlarmAsked = 'exact_alarm_asked';
  static const _kAnalytics = 'analytics_enabled';
  static const _kDiarySync = 'diary_sync';
  static const _kSangatDeclined = 'sangat_declined';
  static const _kSyncWifiOnly = 'sync_wifi_only';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  AppSettings build() {
    final p = _prefs;
    const fallback = AppSettings();
    final stored = p.getString(_kLocale);
    // With nothing stored yet, follow the device language when it is one we
    // ship, and fall back to English otherwise (PRD 1.1).
    final locale = stored != null
        ? Locale(stored)
        : _deviceLocaleOrEnglish();
    final base = stored == null
        ? AppSettings.defaultsForLocale(locale, fallback)
        : fallback;

    return base.copyWith(
      locale: locale,
      script: _enum(GurbaniScript.values, p.getString(_kScript), base.script),
      showRomanUnderGurmukhi: p.getBool(_kRomanUnder) ?? base.showRomanUnderGurmukhi,
      meaningsOn: p.getBool(_kMeaningsOn) ?? base.meaningsOn,
      meaningsLang: _enum(MeaningLanguage.values, p.getString(_kMeaningsLang), base.meaningsLang),
      visraamOn: p.getBool(_kVisraam) ?? base.visraamOn,
      larivaarOn: p.getBool(_kLarivaar) ?? base.larivaarOn,
      readerFontSize: p.getDouble(_kFontSize) ?? base.readerFontSize,
      keepScreenOn: p.getBool(_kKeepScreenOn) ?? base.keepScreenOn,
      followAudio: p.getBool(_kFollowAudio) ?? base.followAudio,
      themeMode: _enum(ThemeMode.values, p.getString(_kTheme), base.themeMode),
      elderMode: p.getBool(_kElder) ?? base.elderMode,
      cityId: p.getString(_kCity) ?? base.cityId,
      speed: p.getDouble(_kSpeed) ?? base.speed,
      simranMinutes: p.getInt(_kSimranMinutes) ?? base.simranMinutes,
      onboardingDone: p.getBool(_kOnboardingDone) ?? base.onboardingDone,
      exactAlarmAsked: p.getBool(_kExactAlarmAsked) ?? base.exactAlarmAsked,
      analyticsEnabled: p.getBool(_kAnalytics) ?? base.analyticsEnabled,
      diarySync: p.getBool(_kDiarySync) ?? base.diarySync,
      sangatDeclined: p.getBool(_kSangatDeclined) ?? base.sangatDeclined,
      syncWifiOnly: p.getBool(_kSyncWifiOnly) ?? base.syncWifiOnly,
    );
  }

  static Locale _deviceLocaleOrEnglish() {
    final device = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return Locale(const {'pa', 'hi'}.contains(device) ? device : 'en');
  }

  static T _enum<T extends Enum>(List<T> values, String? name, T fallback) {
    if (name == null) return fallback;
    for (final v in values) {
      if (v.name == name) return v;
    }
    return fallback;
  }

  /// Changes the app language and moves the reading defaults with it, unless
  /// the user has already chosen otherwise.
  Future<void> setLocale(Locale locale, {bool applyReadingDefaults = true}) async {
    await _prefs.setString(_kLocale, locale.languageCode);
    final next = applyReadingDefaults
        ? AppSettings.defaultsForLocale(locale, state)
        : state.copyWith(locale: locale);
    await _prefs.setString(_kScript, next.script.name);
    await _prefs.setString(_kMeaningsLang, next.meaningsLang.name);
    await _prefs.setBool(_kRomanUnder, next.showRomanUnderGurmukhi);
    state = next;
  }

  Future<void> setScript(GurbaniScript v) async {
    await _prefs.setString(_kScript, v.name);
    state = state.copyWith(script: v);
  }

  Future<void> setShowRomanUnder(bool v) async {
    await _prefs.setBool(_kRomanUnder, v);
    state = state.copyWith(showRomanUnderGurmukhi: v);
  }

  Future<void> setMeaningsOn(bool v) async {
    await _prefs.setBool(_kMeaningsOn, v);
    state = state.copyWith(meaningsOn: v);
  }

  Future<void> setMeaningsLang(MeaningLanguage v) async {
    await _prefs.setString(_kMeaningsLang, v.name);
    state = state.copyWith(meaningsLang: v);
  }

  Future<void> setVisraam(bool v) async {
    await _prefs.setBool(_kVisraam, v);
    state = state.copyWith(visraamOn: v);
  }

  Future<void> setLarivaar(bool v) async {
    await _prefs.setBool(_kLarivaar, v);
    state = state.copyWith(larivaarOn: v);
  }

  Future<void> setReaderFontSize(double v) async {
    await _prefs.setDouble(_kFontSize, v);
    state = state.copyWith(readerFontSize: v);
  }

  Future<void> setKeepScreenOn(bool v) async {
    await _prefs.setBool(_kKeepScreenOn, v);
    state = state.copyWith(keepScreenOn: v);
  }

  Future<void> setFollowAudio(bool v) async {
    await _prefs.setBool(_kFollowAudio, v);
    state = state.copyWith(followAudio: v);
  }

  Future<void> setThemeMode(ThemeMode v) async {
    await _prefs.setString(_kTheme, v.name);
    state = state.copyWith(themeMode: v);
  }

  Future<void> setElderMode(bool v) async {
    await _prefs.setBool(_kElder, v);
    state = state.copyWith(elderMode: v);
  }

  Future<void> setCityId(String v) async {
    await _prefs.setString(_kCity, v);
    state = state.copyWith(cityId: v);
  }

  Future<void> setSpeed(double v) async {
    await _prefs.setDouble(_kSpeed, v);
    state = state.copyWith(speed: v);
  }

  Future<void> setOnboardingDone(bool v) async {
    await _prefs.setBool(_kOnboardingDone, v);
    state = state.copyWith(onboardingDone: v);
  }

  Future<void> setExactAlarmAsked(bool v) async {
    await _prefs.setBool(_kExactAlarmAsked, v);
    state = state.copyWith(exactAlarmAsked: v);
  }

  Future<void> setAnalyticsEnabled(bool v) async {
    await _prefs.setBool(_kAnalytics, v);
    state = state.copyWith(analyticsEnabled: v);
  }

  Future<void> setDiarySync(bool v) async {
    await _prefs.setBool(_kDiarySync, v);
    state = state.copyWith(diarySync: v);
  }

  Future<void> setSangatDeclined(bool v) async {
    await _prefs.setBool(_kSangatDeclined, v);
    state = state.copyWith(sangatDeclined: v);
  }

  Future<void> setSyncWifiOnly(bool v) async {
    await _prefs.setBool(_kSyncWifiOnly, v);
    state = state.copyWith(syncWifiOnly: v);
  }
}
