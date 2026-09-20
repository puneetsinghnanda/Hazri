import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/db/content_repository.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';
import 'package:hazri/core/theme/hazri_text.dart';
import 'package:hazri/core/widgets/surfaces.dart';
import 'package:hazri/features/simran/ui/simran_globe.dart';
import 'package:hazri/features/simran/ui/simran_screen.dart';

import '../app_harness.dart';

/// The Simran tab as the reader drew it on 2026-09-20.
///
/// The mock-up supersedes design 29 for this screen: the globe and the
/// legend are design 29's, the serif headline, the ੴ rule and the verse are
/// the mock-up's.
void main() {
  const kesri = Color(0xFFF2A24E);

  Future<(TestApp, L)> pump(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
  }) async {
    final app = await TestApp.create(
      prefs: {'onboarding_done': true},
      now: DateTime(2026, 9, 20, 6, 30),
    );
    addTearDown(app.dispose);
    usePhoneFrame(tester);
    await tester.pumpWidget(app.wrapRouted(const SimranScreen(), locale: locale));
    await settle(tester);
    return (app, await L.delegate.load(locale));
  }

  /// The rich-text runs on screen, flattened, so a span split across colours
  /// can still be searched as one string.
  List<String> spans(WidgetTester tester) => tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.textSpan?.toPlainText() ?? t.data ?? '')
      .toList();

  testWidgets('it carries the mock-up\'s words', (tester) async {
    final (_, l) = await pump(tester);
    final text = spans(tester).join('\n');

    expect(text, contains(l.simranBrandDaily.trim()));
    expect(text, contains(l.simranBrandName));
    expect(text, contains(l.simranKicker));
    expect(text, contains(l.simranVerseOne));
    expect(text, contains(l.simranVerseTwoWord));
  });

  testWidgets('and not the headline, which the reader took out',
      (tester) async {
    final (_, l) = await pump(tester);
    final text = spans(tester).join('\n');
    // "One Name. / A Brighter World." is gone and ੴ moved up into its place.
    // The strings stay in the ARB files -- they are reviewed copy in three
    // languages and cost nothing to keep -- so this is what stops them
    // drifting back onto the screen unnoticed.
    expect(text, isNot(contains(l.simranHeadlineOne)));
    expect(text, isNot(contains(l.simranHeadlineTwoWord)));
  });

  testWidgets('the brand is set in the serif', (tester) async {
    final (_, l) = await pump(tester);
    final brand = tester.widget<Text>(
      find.byWidgetPredicate((w) =>
          w is Text &&
          (w.textSpan?.toPlainText() ?? '').contains(l.simranBrandName)),
    );
    final first = (brand.textSpan! as TextSpan).children!.first as TextSpan;
    expect(first.style!.fontFamily, HazriFonts.serif);
    // Gurmukhi and Devanagari are not in the Latin subset, so they have to
    // fall through to the Noto serifs rather than to the UI face.
    expect(first.style!.fontFamilyFallback, HazriFonts.serifFallback);
  });

  testWidgets('ੴ comes from content.db, never from Dart', (tester) async {
    final (app, _) = await pump(tester);
    final glyph = await app.container.read(ikOnkarProvider.future);
    expect(glyph, isNotEmpty);
    expect(spans(tester).join('\n'), contains(glyph));
  });

  testWidgets('Begin Simran is kesri, not the light theme\'s indigo',
      (tester) async {
    final (_, l) = await pump(tester);
    final button = tester.widget<PrimaryButton>(
      find.widgetWithText(PrimaryButton, l.simranBeginMinutes(5)),
    );
    expect(button.background, kesri);
  });

  testWidgets('Pause is kesri too, and End stands back', (tester) async {
    final (_, l) = await pump(tester);
    await tester.tap(find.text(l.simranBeginMinutes(5)));
    await tester.pump();

    final pause = tester.widget<PrimaryButton>(
      find.widgetWithText(PrimaryButton, l.actionPause),
    );
    expect(pause.background, kesri);
    final end = tester.widget<PrimaryButton>(
      find.widgetWithText(PrimaryButton, l.simranEnd),
    );
    expect(end.background, isNot(kesri));

    await tester.tap(find.text(l.simranEnd));
    await settle(tester);
  });

  testWidgets('the globe turns under the hand in both directions',
      (tester) async {
    await pump(tester);
    final globe = find.byType(SimranGlobe);
    // Sideways was always allowed; up and down used to do nothing, because
    // the gesture was a horizontal drag rather than a pan.
    await tester.drag(globe, const Offset(-70, 0));
    await tester.pump();
    await tester.drag(globe, const Offset(0, -140));
    await tester.pump();
    await tester.drag(globe, const Offset(0, 400));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  for (final locale in [Locale('en'), Locale('pa'), Locale('hi')]) {
    testWidgets('lays out on a 390 x 844 phone in ${locale.languageCode}',
        (tester) async {
      await pump(tester, locale: locale);
      expect(tester.takeException(), isNull);
    });
  }
}
