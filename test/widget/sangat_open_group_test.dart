import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hazri/app/router.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';
import 'package:hazri/core/theme/hazri_theme.dart';
import 'package:hazri/features/sangat/ui/group_screen.dart';
import 'package:hazri/features/sangat/ui/join_screen.dart';
import 'package:hazri/features/sangat/ui/sangat_widgets.dart';

import '../app_harness.dart';
import '../features/profile/profile_fakes.dart';

/// The Sangat tab's ways out (design 102), through the app's own router.
void main() {
  late L l;

  setUpAll(() async => l = await L.delegate.load(const Locale('en')));

  final builtIn = {
    'groupId': 'simran',
    'kind': 'BUILT_IN',
    'names': {'en': 'Simran Sangat', 'pa': 'ਸਿਮਰਨ ਸੰਗਤ', 'hi': 'सिमरन संगत'},
    'status': 'ACTIVE',
    'memberCount': 3,
    'isMember': true,
    'role': 'MEMBER',
    'goal': {
      'goalId': 'g0001', 'type': 'SIMRAN', 'baniId': null, 'simranMinutes': null, 'target': 1000,
      'startDay': '2026-10-01', 'endDay': '2026-10-31', 'status': 'ACTIVE', 'total': 250, 'pct': 25,
      'todayTotal': 9, 'daysLeft': 23,
    },
  };
  final custom = {
    'groupId': 'gill',
    'kind': 'CUSTOM',
    'name': 'Gill Parivar',
    'status': 'ACTIVE',
    'memberCount': 4,
    'isMember': true,
    'role': 'MEMBER',
    'goal': {
      'goalId': 'g0002', 'type': 'BANI', 'baniId': 'JAPJ', 'target': 100, 'startDay': '2026-10-01',
      'endDay': '2026-12-31', 'status': 'ACTIVE', 'total': 40, 'pct': 40, 'todayTotal': 2, 'daysLeft': 83,
    },
  };

  Future<(TestApp, GoRouter)> boot(WidgetTester tester) async {
    final server = FakeServer();
    server.on('GET', '/profile', 404, errorJson('NO_PROFILE'));
    server.on('GET', '/sangat/groups/mine', 200, {'groups': [custom, builtIn]});
    server.on('GET', '/sangat/groups/built-in', 200, {'groups': [builtIn]});
    server.on('GET', '/sangat/groups/simran', 200, {'group': {...builtIn, 'members': [], 'moreMembers': 0}});
    server.on('GET', '/sangat/groups/gill', 200, {'group': {...custom, 'members': [], 'moreMembers': 0}});
    server.on('POST', '/sangat/contributions', 200, {'processed': []});
    final app = await TestApp.create(prefs: {'onboarding_done': true}, extra: server.overrides());
    addTearDown(app.dispose);
    usePhoneFrame(tester);
    final router = app.container.read(routerProvider);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: app.container,
      child: MaterialApp.router(
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        theme: HazriTheme.light(),
        routerConfig: router,
      ),
    ));
    router.go(Routes.sangat);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await settle(tester);
    return (app, router);
  }

  Future<void> drain(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 5));
  }

  testWidgets('a joined built-in group opens from its row', (tester) async {
    await boot(tester);
    await tester.tap(find.descendant(of: find.byType(BuiltInGroupRow), matching: find.text('Simran Sangat')));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await settle(tester);
    expect(find.byType(GroupScreen), findsOneWidget);
    await drain(tester);
  });

  testWidgets('a group tile opens the group screen', (tester) async {
    await boot(tester);
    await tester.tap(find.widgetWithText(GroupGridTile, 'Gill Parivar'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await settle(tester);
    expect(find.byWidgetPredicate((w) => w is GroupScreen && w.groupId == 'gill'), findsOneWidget);
    await drain(tester);
  });

  testWidgets('the Join group tile opens the join screen', (tester) async {
    await boot(tester);
    await tester.tap(find.text(l.sangatJoinGroupTile));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await settle(tester);
    expect(find.byType(JoinScreen), findsOneWidget);
    await drain(tester);
  });
}
