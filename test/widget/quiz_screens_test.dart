import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';
import 'package:hazri/core/theme/hazri_theme.dart';
import 'package:hazri/features/quiz/data/quiz_repository.dart';
import 'package:hazri/features/quiz/ui/quiz_board_screen.dart';
import 'package:hazri/features/quiz/ui/quiz_home_screen.dart';
import 'package:hazri/features/quiz/ui/quiz_screen.dart';
import 'package:hazri/features/quiz/ui/quiz_today_card.dart';
import 'package:hazri/features/today/ui/today_screen.dart';

import '../app_harness.dart';

/// 14-quiz.md's screens: the Today card (QZ9-QZ12), a quiz without a profile
/// (QZ14, QZ15, QZ17, QZ23, QZ26, QZ31), the board without one (QZ29) and the
/// quiz page (QZ33).
void main() {
  late TestApp app;

  Future<L> pumpAt(WidgetTester tester, String location, {bool elder = false, DateTime? now}) async {
    app = await TestApp.create(
      prefs: {'onboarding_done': true, if (elder) 'elder_mode': true},
      now: now ?? DateTime(2026, 10, 27, 9),
      extra: [
        // No profile: the quiz never reaches for the server (QZ14).
        quizOnlineProvider.overrideWithValue(false),
        quizApiProvider.overrideWith((ref) => throw StateError('the quiz called the server without a profile')),
      ],
    );
    addTearDown(app.dispose);
    usePhoneFrame(tester);
    final router = GoRouter(
      initialLocation: location,
      routes: [
        GoRoute(path: '/today', builder: (_, _) => const TodayScreen()),
        GoRoute(
          path: '/quiz',
          builder: (_, s) => QuizHomeScreen(category: s.uri.queryParameters['category']),
        ),
        GoRoute(
          path: '/library/:id',
          builder: (_, s) => Scaffold(body: Text('vichar ${s.pathParameters['id']}')),
        ),
        GoRoute(
          path: '/quiz/play/:t',
          builder: (_, s) => QuizScreen(topicId: s.pathParameters['t']!),
        ),
        GoRoute(
          path: '/quiz/board',
          builder: (_, s) => QuizBoardScreen(scope: s.uri.queryParameters['scope']),
        ),
        GoRoute(
          path: '/profile-setup',
          builder: (_, _) => const Scaffold(body: Text('setup')),
        ),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: app.container,
        child: MaterialApp.router(
          locale: const Locale('en'),
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          theme: HazriTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await settle(tester);
    return L.delegate.load(const Locale('en'));
  }

  Future<void> scrollTo(WidgetTester tester, Finder finder) =>
      tester.scrollUntilVisible(finder, 300, scrollable: find.byType(Scrollable).first);

  testWidgets('the calendar leaf has no buttons; on a Gurpurab the card opens the day\'s Vichar page (QZ11)', (
    tester,
  ) async {
    final l = await pumpAt(tester, '/today');
    final card = find.byType(QuizTodayCard);
    await scrollTo(tester, find.descendant(of: card, matching: find.text('PRAKASH PURAB')));
    expect(find.descendant(of: card, matching: find.text('Guru Ram Das Ji')), findsOneWidget);
    expect(find.descendant(of: card, matching: find.byType(FilledButton)), findsNothing);
    expect(find.text(l.quizTakeQuiz), findsNothing);
    await tester.tap(find.descendant(of: card, matching: find.text('Guru Ram Das Ji')));
    await settle(tester);
    expect(find.textContaining('vichar '), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('on a day with no event the leaf says Did you know? and a tap does nothing', (tester) async {
    final l = await pumpAt(tester, '/today', now: DateTime(2026, 10, 28, 9));
    final card = find.byType(QuizTodayCard);
    await scrollTo(tester, find.descendant(of: card, matching: find.text(l.quizDidYouKnow.toUpperCase())));
    await tester.tap(find.descendant(of: card, matching: find.text(l.quizDidYouKnow.toUpperCase())));
    await settle(tester);
    expect(find.textContaining('vichar '), findsNothing);
    expect(find.byType(QuizScreen), findsNothing);
  });

  for (final width in [360.0, 390.0, 412.0]) {
    testWidgets('at ${width.toInt()} dp the quiz card (design D) lays out and Start opens today\'s quiz', (
      tester,
    ) async {
      final l = await pumpAt(tester, '/today');
      tester.view.physicalSize = Size(width * 3, 844 * 3);
      await settle(tester);
      final pick = find.byType(QuizPickCard);
      await scrollTo(tester, find.descendant(of: pick, matching: find.text(l.quizStart)));
      await settle(tester);
      expect(find.descendant(of: pick, matching: find.text('Guru Ram Das Ji')), findsOneWidget);
      expect(find.descendant(of: pick, matching: find.text(l.quizCardLineNoProfile)), findsOneWidget);
      // No profile: no points on the card (QZ14).
      expect(find.descendant(of: pick, matching: find.textContaining(RegExp(r'pts|today$'))), findsNothing);
      final start = tester.renderObject<RenderParagraph>(find.descendant(of: pick, matching: find.text(l.quizStart)));
      expect(start.size.width, greaterThanOrEqualTo(min(start.getMaxIntrinsicWidth(double.infinity), 60) - 0.5));
      expect(tester.takeException(), isNull);
      await tester.tap(find.descendant(of: pick, matching: find.text(l.quizStart)));
      await settle(tester);
      expect(find.byType(QuizScreen), findsOneWidget);
    });
  }

  testWidgets('the quiz card offers the other categories, and a tile opens the quiz page on it', (tester) async {
    final l = await pumpAt(tester, '/today');
    final pick = find.byType(QuizPickCard);
    // Today's topic is a Guru, so Gurus is not offered again.
    await scrollTo(tester, find.descendant(of: pick, matching: find.text(l.quizPickAnother.toUpperCase())));
    await settle(tester);
    expect(find.descendant(of: pick, matching: find.text(l.quizCatGurus)), findsNothing);
    await tester.tap(find.descendant(of: pick, matching: find.text(l.quizCatGurdwaras)));
    await settle(tester);
    expect(find.byType(QuizHomeScreen), findsOneWidget);
    expect(find.text('Five Takhts'), findsWidgets);
    expect(find.text('Guru Nanak Dev Ji'), findsNothing);
  });

  testWidgets('both quiz cards stay on Today in elder mode (QZ9)', (tester) async {
    await pumpAt(tester, '/today', elder: true);
    expect(find.byType(QuizTodayCard, skipOffstage: false), findsOneWidget);
    expect(find.byType(QuizPickCard, skipOffstage: false), findsOneWidget);
  });

  testWidgets('without a profile a quiz plays on the phone, marks each answer, and earns no points', (tester) async {
    final l = await pumpAt(tester, '/quiz/play/guru-ram-das-ji');
    expect(find.text(l.quizQuestionOf(1, 5)), findsOneWidget);
    for (var i = 0; i < 5; i++) {
      // Next waits for an answer.
      final next = find.text(i == 4 ? l.quizSeeResult : l.quizNext);
      await tester.tap(find.text('A'));
      await tester.pump();
      expect(find.text('A'), findsNothing); // marked: the letters give way to ticks and crosses
      expect(find.textContaining(RegExp('^(${l.quizRight}|${l.quizWrong})\$')), findsOneWidget);
      await tester.tap(next);
      await settle(tester);
    }
    expect(find.text(l.quizResultTitle), findsOneWidget);
    expect(find.textContaining('+'), findsNothing);
    expect(find.text(l.quizPointsNeedConnection), findsNothing);
    expect(find.text(l.quizMakeProfileToEarn), findsOneWidget);
    expect(find.text(l.quizShareButton), findsOneWidget);
    expect(find.text(l.quizSeeLeaderboard), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('leaving part-way asks first (QZ17)', (tester) async {
    final l = await pumpAt(tester, '/quiz/play/five-takhts');
    await tester.tap(find.text('B'));
    await tester.pump();
    await tester.tap(find.byTooltip(l.actionClose));
    await settle(tester);
    expect(find.text(l.quizLeaveTitle), findsOneWidget);
    await tester.tap(find.text(l.quizKeepGoing));
    await settle(tester);
    expect(find.text(l.quizNext), findsOneWidget);
  });

  testWidgets('the board without a profile asks for one and says it needs a connection (QZ29, QZ30)', (tester) async {
    final l = await pumpAt(tester, '/quiz/board?scope=guru-ram-das-ji');
    expect(find.text(l.quizProfileCardTitle), findsOneWidget);
    expect(find.text(l.quizBoardOffline), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the quiz page: coming up, the six categories, today\'s category open (6A)', (tester) async {
    final l = await pumpAt(tester, '/quiz');
    expect(find.text(l.quizComingUp.toUpperCase()), findsOneWidget);
    for (final label in [l.quizCatAll, l.quizCatGurus, l.quizCatGurdwaras, l.quizCatBanis]) {
      expect(find.text(label), findsWidgets, reason: label);
    }
    // The row of tiles scrolls sideways, as the design's does.
    await tester.drag(find.text(l.quizCatBanis).first, const Offset(-300, 0));
    await settle(tester);
    expect(find.text(l.quizCatCulture), findsWidgets);
    await tester.drag(find.text(l.quizCatCulture).first, const Offset(300, 0));
    await settle(tester);
    expect(find.text(l.quizCount(11)), findsOneWidget);
    await tester.tap(find.text(l.quizCatGurdwaras).first);
    await settle(tester);
    expect(find.text(l.quizCount(2)), findsOneWidget);
    expect(find.text('Five Takhts'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
