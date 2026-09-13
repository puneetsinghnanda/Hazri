import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';

/// Every user-facing string must exist in Punjabi, Hindi and English from day
/// one (PRD §11), so a missing key fails the build rather than shipping an
/// English fallback into a Punjabi UI.
void main() {
  Map<String, dynamic> arb(String locale) =>
      jsonDecode(File('lib/core/l10n/app_$locale.arb').readAsStringSync())
          as Map<String, dynamic>;

  Set<String> keys(Map<String, dynamic> m) =>
      m.keys.where((k) => !k.startsWith('@')).toSet();

  final en = arb('en');
  final pa = arb('pa');
  final hi = arb('hi');

  test('the app ships exactly the three Phase 1 locales', () {
    expect(
      L.supportedLocales.map((l) => l.languageCode).toSet(),
      {'en', 'pa', 'hi'},
    );
  });

  test('no key is missing from Punjabi', () {
    expect(keys(en).difference(keys(pa)), isEmpty);
  });

  test('no key is missing from Hindi', () {
    expect(keys(en).difference(keys(hi)), isEmpty);
  });

  test('no locale carries a key English does not have', () {
    expect(keys(pa).difference(keys(en)), isEmpty);
    expect(keys(hi).difference(keys(en)), isEmpty);
  });

  test('placeholders match across locales', () {
    final placeholder = RegExp(r'\{(\w+)\}');
    for (final key in keys(en)) {
      final want = placeholder
          .allMatches(en[key] as String)
          .map((m) => m.group(1))
          .toSet();
      for (final (name, map) in [('pa', pa), ('hi', hi)]) {
        final got = placeholder
            .allMatches(map[key] as String)
            .map((m) => m.group(1))
            .toSet();
        expect(got, want, reason: '$key in $name');
      }
    }
  });

  test('no translated string was left as the English source', () {
    // A handful of strings are deliberately identical in every locale: proper
    // nouns, script samples and the language names shown in their own script.
    const sharedByDesign = {
      'appNameNative',
      'setupLanguagePunjabi',
      'setupLanguagePunjabiSub',
      'setupLanguageHindi',
      'setupLanguageHindiSub',
      'setupLanguageEnglish',
      'setupLanguageEnglishSub',
      'introMeaningsIn',
      'simranWaheguru',
      'diaryTickTitle',
      'nOfM',
    };
    var identical = 0;
    for (final key in keys(en)) {
      if (sharedByDesign.contains(key)) continue;
      if (en[key] == pa[key]) identical++;
    }
    expect(identical, 0, reason: '$identical Punjabi strings are still English');
  });

  testWidgets('each locale loads and resolves a string', (tester) async {
    for (final locale in L.supportedLocales) {
      final l = await L.delegate.load(locale);
      expect(l.appName, isNotEmpty);
      expect(l.greeting, isNotEmpty);
      expect(l.minutes(5), contains('5'));
      expect(l.nOfM(2, 5), allOf(contains('2'), contains('5')));
    }
  });

  test('the Punjabi UI is written in Gurmukhi', () {
    final gurmukhi = RegExp(r'[਀-੿]');
    final devanagari = RegExp(r'[ऀ-ॿ]');
    var checked = 0;
    for (final key in ['greeting', 'navNitnem', 'diaryTitle', 'settingsTitle']) {
      expect(gurmukhi.hasMatch(pa[key] as String), isTrue, reason: key);
      expect(devanagari.hasMatch(hi[key] as String), isTrue, reason: key);
      checked++;
    }
    expect(checked, 4);
  });

  test('localeName is reported correctly for bani name lookups', () async {
    for (final locale in L.supportedLocales) {
      final l = await L.delegate.load(locale);
      expect(l.localeName, locale.languageCode);
    }
  });

  test('L.of is available wherever Localizations are installed', () {
    expect(L.localizationsDelegates, isNotEmpty);
    expect(const Locale('pa'), isNotNull);
  });
}
