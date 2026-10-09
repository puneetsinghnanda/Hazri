import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/app/router.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';
import 'package:hazri/core/theme/hazri_theme.dart';
import 'package:hazri/features/sangat/ui/group_screen.dart';

import '../app_harness.dart';
import '../features/profile/profile_fakes.dart';

void main() {
  testWidgets('a joined built-in group opens from the Sangat tab', (tester) async {
    final server = FakeServer();
    final group = {
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
    server.on('GET', '/profile', 404, errorJson('NO_PROFILE'));
    server.on('GET', '/sangat/groups/mine', 200, {'groups': [group]});
    server.on('GET', '/sangat/groups/built-in', 200, {'groups': [group]});
    server.on('GET', '/sangat/groups/simran', 200, {'group': {...group, 'members': [], 'moreMembers': 0}});
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
    await tester.tap(find.text('Simran Sangat').first);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await settle(tester);
    expect(find.byType(GroupScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 5));
  });
}
