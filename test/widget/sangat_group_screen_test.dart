import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hazri/app/router.dart' show Routes;
import 'package:hazri/core/db/content_repository.dart';
import 'package:hazri/core/db/user_db.dart';
import 'package:hazri/core/db/user_repository.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';
import 'package:hazri/core/theme/hazri_theme.dart';
import 'package:hazri/core/time/date_format.dart';
import 'package:hazri/features/sangat/ui/group_screen.dart';

import '../app_harness.dart';
import '../features/profile/profile_fakes.dart';

/// The group screen, design 103 (08-sangat VS3–VS5, SC1).
void main() {
  late L l;

  setUpAll(() async => l = await L.delegate.load(const Locale('en')));

  final members = [
    {
      'memberKey': 'm1',
      'name': 'Amandeep Singh',
      'role': 'MEMBER',
      'status': 'ACTIVE',
      'contribution': 240,
      'isYou': false,
    },
    {
      'memberKey': 'm2',
      'name': 'Baljit Kaur',
      'role': 'MEMBER',
      'status': 'ACTIVE',
      'contribution': 95,
      'isYou': false,
    },
    {
      'memberKey': 'm3',
      'name': 'Charanjit Singh',
      'role': 'MEMBER',
      'status': 'ACTIVE',
      'contribution': 186,
      'isYou': true,
    },
  ];
  final simran = {
    'groupId': 'simran',
    'kind': 'BUILT_IN',
    'names': {'en': 'Simran Sangat', 'pa': 'ਸਿਮਰਨ ਸੰਗਤ', 'hi': 'सिमरन संगत'},
    'status': 'ACTIVE',
    'memberCount': 2418,
    'isMember': true,
    'role': 'MEMBER',
    'goal': {
      'goalId': 'g0001',
      'type': 'SIMRAN',
      'baniId': null,
      'target': 500000,
      'startDay': '2026-10-01',
      'endDay': '2026-10-31',
      'status': 'ACTIVE',
      'total': 212480,
      'pct': 42,
      'todayTotal': 6930,
      'daysLeft': 23,
    },
    'members': members,
    'moreMembers': 2415,
  };
  final gill = {
    'groupId': 'gill',
    'kind': 'CUSTOM',
    'name': 'Gill Parivar',
    'status': 'ACTIVE',
    'memberCount': 3,
    'isMember': true,
    'role': 'MEMBER',
    'goal': {
      'goalId': 'g0002',
      'type': 'BANI',
      'baniId': 'JAPJ',
      'target': 5000,
      'startDay': '2026-10-01',
      'endDay': '2026-12-31',
      'status': 'ACTIVE',
      'total': 3412,
      'pct': 68,
      'todayTotal': 46,
      'daysLeft': 84,
    },
    'members': members,
    'moreMembers': 0,
  };

  Future<(TestApp, GoRouter)> boot(
    WidgetTester tester,
    String groupId, {
    Future<void> Function(UserRepository repo)? seed,
  }) async {
    final server = FakeServer();
    server.on('GET', '/profile', 404, errorJson('NO_PROFILE'));
    server.on('GET', '/sangat/groups/mine', 200, {'groups': []});
    server.on('GET', '/sangat/groups/built-in', 200, {'groups': []});
    server.on('GET', '/sangat/groups/simran', 200, {'group': simran});
    server.on('GET', '/sangat/groups/gill', 200, {'group': gill});
    server.on('POST', '/sangat/contributions', 200, {'processed': []});
    final app = await TestApp.create(
      prefs: {'onboarding_done': true},
      now: DateTime(2026, 10, 9, 9),
      extra: server.overrides(),
    );
    addTearDown(app.dispose);
    if (seed != null) await tester.runAsync(() => seed(app.container.read(userRepositoryProvider)));
    usePhoneFrame(tester);
    // The group screen on the app's own route, and stand-ins for where it
    // leads, so a test sees the navigation without starting a sitting or the
    // reader.
    final router = GoRouter(
      initialLocation: Routes.sangatGroup(groupId),
      routes: [
        GoRoute(path: Routes.sangat, builder: (_, _) => const Text('SANGAT TAB')),
        GoRoute(path: Routes.simran, builder: (_, _) => const Text('SIMRAN TAB')),
        GoRoute(path: '/reader/:slug', builder: (_, s) => Text('READER ${s.pathParameters['slug']}')),
        GoRoute(
          path: '/sangat-group/:id',
          builder: (_, s) => GroupScreen(groupId: s.pathParameters['id']!),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: app.container,
        child: MaterialApp.router(
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          theme: HazriTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await settle(tester);
    return (app, router);
  }

  Future<void> drain(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 5));
  }

  testWidgets('the band holds the ring, total of target and the goal', (tester) async {
    await boot(tester, 'simran');
    expect(find.text('Simran Sangat'), findsOneWidget);
    expect(find.text('${l.sangatBuiltInKind} · ${l.sangatMembers(2418)}'), findsOneWidget);
    expect(find.text('212,480'), findsOneWidget);
    expect(find.text(l.sangatOfTargetMinutes('500,000')), findsOneWidget);
    expect(find.text('42%'), findsOneWidget);
    expect(find.textContaining('500000 minutes of Naam Simran by'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await drain(tester);
  });

  testWidgets('the timeline: started, today with days left, the end and the next goal', (tester) async {
    await boot(tester, 'simran');
    final dates = HazriDates.of(tester.element(find.byType(GroupScreen)));
    expect(find.text(l.sangatThisGoal.toUpperCase()), findsOneWidget);
    expect(find.text(l.sangatDayOf(9, 31)), findsOneWidget);
    expect(find.text(dates.shortDate(DateTime(2026, 10, 1))), findsOneWidget);
    expect(find.text(l.sangatStarted), findsOneWidget);
    expect(find.text(l.today), findsOneWidget);
    expect(find.text(l.sangatDaysLeft(23)), findsOneWidget);
    expect(find.text(dates.shortDate(DateTime(2026, 10, 31))), findsOneWidget);
    // BI4: a built-in group starts its next goal the day after.
    expect(find.text(l.sangatEndsNewGoal(dates.shortDate(DateTime(2026, 11, 1)))), findsOneWidget);
    await drain(tester);
  });

  testWidgets('the three figures: the sangat today, yours today from user.db, yours toward the goal', (tester) async {
    // CT1: whole minutes per sitting, so 7 min 30 s is 7 and 59 s is nothing.
    await boot(
      tester,
      'simran',
      seed: (repo) async {
        await repo.logSitting(
          duration: const Duration(minutes: 7, seconds: 30),
          completed: true,
          source: SittingSource.timer,
        );
        await repo.logSitting(duration: const Duration(seconds: 59), completed: false, source: SittingSource.timer);
      },
    );
    expect(find.text(l.sangatFigureSangatToday), findsOneWidget);
    expect(find.text('6,930 min', findRichText: true), findsOneWidget);
    expect(find.text(l.sangatFigureYoursToday), findsOneWidget);
    expect(find.text('7 min', findRichText: true), findsOneWidget);
    expect(find.text(l.sangatFigureYoursGoal), findsOneWidget);
    final toward = find.ancestor(of: find.text(l.sangatFigureYoursGoal), matching: find.byType(Column)).first;
    expect(find.descendant(of: toward, matching: find.text('186 min', findRichText: true)), findsOneWidget);
    await drain(tester);
  });

  testWidgets('SC1: Sit for Naam Simran opens the Simran tab', (tester) async {
    await boot(tester, 'simran');
    final sit = find.text(l.sangatSitFor(l.sangatGoalSimran));
    expect(sit, findsOneWidget);
    await tester.ensureVisible(sit);
    await tester.tap(sit);
    await settle(tester);
    expect(find.text('SIMRAN TAB'), findsOneWidget);
    await drain(tester);
  });

  testWidgets('SC1: Sit for {bani} names the bani from content.db and opens the reader', (tester) async {
    final (app, _) = await boot(tester, 'gill');
    final banis = await tester.runAsync(() => app.container.read(banisProvider.future));
    final japji = banis!.firstWhere((b) => b.id == 'JAPJ');
    final sit = find.text(l.sangatSitFor(japji.name('en')));
    expect(sit, findsOneWidget);
    await tester.ensureVisible(sit);
    await tester.tap(sit);
    await settle(tester);
    expect(find.text('READER ${japji.slug}'), findsOneWidget);
    await drain(tester);
  });

  testWidgets('a bani goal: yours today counts today\'s paath of that bani only', (tester) async {
    await boot(
      tester,
      'gill',
      seed: (repo) async {
        await repo.logCompletion(baniId: 'JAPJ', slot: BaniSlotValue.morning, source: CompletionSource.reader);
        await repo.logCompletion(baniId: 'JAPJ', slot: BaniSlotValue.morning, source: CompletionSource.reader);
        await repo.logCompletion(baniId: 'JAAP', slot: BaniSlotValue.morning, source: CompletionSource.reader);
      },
    );
    final yours = find.ancestor(of: find.text(l.sangatFigureYoursToday), matching: find.byType(Column)).first;
    expect(find.descendant(of: yours, matching: find.text('2', findRichText: true)), findsOneWidget);
    // A custom group's next goal is not promised; the end is just the end.
    expect(find.text(l.sangatEnds), findsOneWidget);
    await drain(tester);
  });

  testWidgets('VS4, VS5: members A to Z with their own figures, then "and N more"', (tester) async {
    await boot(tester, 'simran');
    expect(find.text(l.sangatMembersHeading.toUpperCase()), findsOneWidget);
    expect(find.text(l.sangatMembersAtoZ('2,418')), findsOneWidget);
    final a = find.text('Amandeep Singh');
    final b = find.text('Baljit Kaur');
    final you = find.text('Charanjit Singh (${l.sangatYou})');
    await tester.ensureVisible(you);
    expect(tester.getTopLeft(a).dy, lessThan(tester.getTopLeft(b).dy));
    expect(tester.getTopLeft(b).dy, lessThan(tester.getTopLeft(you).dy));
    expect(find.text('240 min'), findsOneWidget);
    expect(find.text('95 min'), findsOneWidget);
    expect(find.text(l.sangatAndMore('2,415')), findsOneWidget);
    // No bars and no rank.
    expect(find.byType(LinearProgressIndicator), findsNothing);
    await drain(tester);
  });

  testWidgets('a custom group keeps Share invite below the members and in the menu', (tester) async {
    await boot(tester, 'gill');
    final share = find.text(l.sangatShareInvite);
    expect(share, findsOneWidget);
    await tester.tap(find.byTooltip(l.sangatGroupMenu));
    await settle(tester);
    expect(find.text(l.sangatShareInvite), findsNWidgets(2));
    expect(find.text(l.sangatLeave), findsOneWidget);
    expect(find.text(l.sangatReport), findsOneWidget);
    await drain(tester);
  });

  testWidgets('a built-in group has Leave and Report and no invite', (tester) async {
    await boot(tester, 'simran');
    expect(find.text(l.sangatShareInvite), findsNothing);
    await tester.tap(find.byTooltip(l.sangatGroupMenu));
    await settle(tester);
    expect(find.text(l.sangatLeave), findsOneWidget);
    expect(find.text(l.sangatReport), findsOneWidget);
    expect(find.text(l.sangatShareInvite), findsNothing);
    await drain(tester);
  });

  for (final locale in const [Locale('pa'), Locale('hi')]) {
    testWidgets('the group screen lays out in ${locale.languageCode}', (tester) async {
      final (app, router) = await boot(tester, 'simran');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: app.container,
          child: MaterialApp.router(
            locale: locale,
            localizationsDelegates: L.localizationsDelegates,
            supportedLocales: L.supportedLocales,
            theme: HazriTheme.light(),
            routerConfig: router,
          ),
        ),
      );
      await settle(tester);
      expect(tester.takeException(), isNull);
      await drain(tester);
    });
  }
}
