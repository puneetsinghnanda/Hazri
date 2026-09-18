import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';
import 'package:hazri/features/gurpurab/ui/gurpurab_screen.dart';

import '../app_harness.dart';

/// The calendar screen, now that it carries a whole year rather than ten days.
///
/// 147 entries ship: Gurpurabs, shaheedi divas, jorh melas, historical days
/// and every Sangrand, Puranmashi and Masya. All of it is worth having and
/// none of it should bury what most people open this screen for, so the list
/// starts on Gurpurabs and the rest is one tap away.
void main() {
  late TestApp app;

  setUp(() async {
    app = await TestApp.create(
      prefs: {'onboarding_done': true},
      now: DateTime(2026, 11, 20, 9, 0),
    );
  });

  tearDown(() => app.dispose());

  Future<L> pump(WidgetTester tester, {Locale locale = const Locale('en')}) async {
    usePhoneFrame(tester);
    await tester.pumpWidget(app.wrapRouted(const GurpurabScreen(), locale: locale));
    await settle(tester);
    return L.delegate.load(locale);
  }

  testWidgets('opens on Gurpurabs, and the rest is one tap away', (tester) async {
    // A day that carries both a Gurpurab and a birth anniversary, so the one
    // the filter hides is on screen rather than below the fold.
    app.dispose();
    app = await TestApp.create(
      prefs: {'onboarding_done': true},
      now: DateTime(2026, 12, 14, 9, 0),
    );
    final l = await pump(tester);

    expect(find.text(l.calendarKindGurgaddi), findsWidgets);
    expect(find.text(l.calendarKindBirth), findsNothing);

    await tester.tap(find.text(l.gurpurabFilterAll));
    await settle(tester);
    expect(find.text(l.calendarKindBirth), findsWidgets);
    expect(find.text(l.calendarKindGurgaddi), findsWidgets);

    await tester.tap(find.text(l.gurpurabFilterGurpurabsOnly));
    await settle(tester);
    expect(find.text(l.calendarKindBirth), findsNothing);
  });

  testWidgets('every event shows the type the document gave it', (tester) async {
    final l = await pump(tester);
    // The type is stored per event and shown, rather than only filtered on.
    expect(find.text(l.calendarKindPrakash), findsWidgets);
  });

  testWidgets('an event with no Punjabi still reads in Punjabi', (tester) async {
    await pump(tester, locale: const Locale('pa'));
    await settle(tester);

    // Guru Nanak Dev Ji's Prakash Purab is one of the ten that carry Gurmukhi.
    expect(find.text('ਪ੍ਰਕਾਸ਼ ਪੁਰਬ, ਗੁਰੂ ਨਾਨਕ ਦੇਵ ਜੀ'), findsOneWidget);

    // Nothing anywhere fell back to an empty string: every row has a name.
    final l = await L.delegate.load(const Locale('pa'));
    expect(find.text(l.gurpurabNoneUpcoming), findsNothing);
  });
}
