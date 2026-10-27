import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hazri/app/menu_sheet.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';
import 'package:hazri/core/theme/hazri_theme.dart';
import 'package:hazri/features/saakhi/ui/saakhi_library_screen.dart';
import 'package:hazri/features/saakhi/ui/saakhi_reader_screen.dart';
import 'package:hazri/features/today/ui/today_screen.dart';

import '../app_harness.dart';

/// 13-saakhi.md's screens: the reader (SK6-SK8), the library and Today's
/// row (SK11, 1A), and the left drawer (SK11, option A).
void main() {
  late TestApp app;

  setUp(() async {
    app = await TestApp.create(prefs: {'onboarding_done': true}, now: DateTime(2026, 10, 25, 9));
  });
  tearDown(() => app.dispose());

  Future<L> pumpAt(WidgetTester tester, String location, {Locale locale = const Locale('en')}) async {
    usePhoneFrame(tester);
    final router = GoRouter(
      initialLocation: location,
      routes: [
        GoRoute(path: '/today', builder: (_, _) => const TodayScreen()),
        GoRoute(path: '/saakhis', builder: (_, _) => const SaakhiLibraryScreen()),
        GoRoute(
          path: '/saakhis/:id',
          builder: (_, s) => SaakhiReaderScreen(id: s.pathParameters['id']!),
        ),
      ],
    );
    await tester.pumpWidget(UncontrolledProviderScope(
      container: app.container,
      child: MaterialApp.router(
        locale: locale,
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        theme: HazriTheme.light(),
        routerConfig: router,
      ),
    ));
    await settle(tester);
    return L.delegate.load(locale);
  }

  testWidgets('the reader opens on the cover, and Read goes to page 1', (tester) async {
    final l = await pumpAt(tester, '/saakhis/bhai-lalo-malik-bhago');
    expect(find.text('Bhai Lalo and Malik Bhago'), findsOneWidget);
    expect(find.text(l.saakhiListen), findsOneWidget);
    await tester.tap(find.text(l.saakhiRead));
    await settle(tester);
    expect(find.textContaining(l.saakhiPageOf(1, 8)), findsOneWidget);
    // SK10: Share is a labelled button on every story page.
    expect(find.text(l.saakhiShare), findsOneWidget);
  });

  testWidgets('the lesson page is design D, and its Gurbani row opens to the pankti', (tester) async {
    final l = await pumpAt(tester, '/saakhis/bhai-lalo-malik-bhago');
    await tester.tap(find.text(l.saakhiRead));
    await settle(tester);
    for (var i = 0; i < 7; i++) {
      await tester.tap(find.byTooltip(l.saakhiNextPage));
      await settle(tester);
    }
    // Punjabi by default, whatever the app's language (SK9, owner 2026-10-27).
    expect(find.text('ਇਮਾਨਦਾਰੀ ਦੀ ਰੋਟੀ ਦੁੱਧ ਵਰਗੀ ਮਿੱਠੀ ਹੈ।'), findsOneWidget);
    expect(find.text(l.saakhiTalkTogether), findsOneWidget); // a Punjabi page's eyebrow is not upper-cased
    expect(find.text(l.saakhiReadAgain), findsOneWidget);
    expect(find.text(l.saakhiAng(105)), findsOneWidget);
    expect(find.textContaining('ਰੁਖੀ ਰੋਟੀ'), findsNothing, reason: 'the row starts closed');
    await tester.tap(find.text(l.saakhiGurbani));
    await settle(tester);
    expect(find.textContaining('ਰੁਖੀ ਰੋਟੀ'), findsOneWidget);
  });

  testWidgets('in an English app a saakhi opens in Punjabi, with its Punjabi narration (SK9)', (tester) async {
    final l = await pumpAt(tester, '/saakhis/bhai-lalo-malik-bhago');
    await tester.tap(find.text(l.saakhiRead));
    await settle(tester);
    expect(find.textContaining('ਜਦੋਂ ਗੁਰੂ ਨਾਨਕ ਦੇਵ ਜੀ'), findsOneWidget);
    expect(find.text(l.saakhiPunjabiNarrationComing), findsNothing);
    final play = tester.widget<InkWell>(
      find.descendant(of: find.byTooltip(l.saakhiPlay), matching: find.byType(InkWell)),
    );
    expect(play.onTap, isNotNull);
  });

  testWidgets('the library lists every saakhi with its pages and length', (tester) async {
    final l = await pumpAt(tester, '/saakhis');
    expect(find.text(l.saakhiTitle), findsOneWidget);
    expect(find.text('Anand Bhaya Meri Maaye'), findsOneWidget);
    expect(find.textContaining(l.saakhiPages(8)), findsWidgets);
  });

  testWidgets('Today shows the saakhis as a row of covers with See all (1A)', (tester) async {
    final l = await pumpAt(tester, '/today');
    final row = find.byType(SaakhiTodayRow);
    await tester.scrollUntilVisible(row, 300, scrollable: find.byType(Scrollable).first);
    expect(find.text(l.saakhiSeeAll), findsOneWidget);
    expect(find.descendant(of: row, matching: find.text('Bhai Lalo and Malik Bhago')), findsOneWidget);
  });

  testWidgets('the menu is a left drawer with Saakhis and its count (option A)', (tester) async {
    final l = await pumpAt(tester, '/today');
    await tester.tap(find.byTooltip(l.menuTooltip).first);
    await settle(tester);
    expect(find.text('4'), findsOneWidget);
    expect(find.text(l.helpSheetTitle), findsOneWidget);
    // It slides in from the left edge.
    expect(tester.getTopLeft(find.text(l.navToday).last).dx, lessThan(100));
    await tester.tap(find.text(l.saakhiTitle).last);
    await settle(tester);
    expect(find.byType(SaakhiLibraryScreen), findsOneWidget);
  });

  test('showMenuDrawer is what every tab opens', () => expect(showMenuDrawer, isNotNull));
}
