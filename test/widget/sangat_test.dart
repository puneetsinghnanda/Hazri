import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';
import 'package:hazri/features/sangat/data/sangat_controller.dart';
import 'package:hazri/features/sangat/ui/join_screen.dart';
import 'package:hazri/features/sangat/ui/sangat_screen.dart';

import '../app_harness.dart';
import '../features/profile/profile_fakes.dart';

/// 08-sangat §10 at the screen seam.
void main() {
  late FakeServer server;
  late TestApp app;
  late L l;

  setUpAll(() async => l = await L.delegate.load(const Locale('en')));

  Map<String, Object?> builtIn({bool member = false}) => {
        'groupId': 'simran',
        'kind': 'BUILT_IN',
        'names': {'en': 'Simran Sangat', 'pa': 'ਸਿਮਰਨ ਸੰਗਤ', 'hi': 'सिमरन संगत'},
        'status': 'ACTIVE',
        'memberCount': 120,
        'isMember': member,
        'role': member ? 'MEMBER' : null,
        'goal': {
          'goalId': 'g0001', 'type': 'SIMRAN', 'simranMinutes': 11, 'target': 1000, 'startDay': '2026-10-01',
          'endDay': '2026-10-31', 'status': 'ACTIVE', 'total': 250, 'pct': 25, 'todayTotal': 9, 'daysLeft': 23,
        },
      };

  Future<void> boot(WidgetTester tester, Widget screen) async {
    app = await TestApp.create(prefs: {'onboarding_done': true}, extra: server.overrides());
    addTearDown(app.dispose);
    usePhoneFrame(tester);
    await tester.pumpWidget(app.wrapRouted(screen));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
    await settle(tester);
  }

  setUp(() {
    server = FakeServer();
    server.on('GET', '/profile', 404, errorJson('NO_PROFILE'));
    server.on('GET', '/sangat/groups/mine', 200, {'groups': []});
    server.on('GET', '/sangat/groups/built-in', 200, {'groups': [builtIn()]});
    server.on('POST', '/sangat/contributions', 200, {'processed': []});
  });

  testWidgets('S-1: no profile → built-in groups with Join', (tester) async {
    await boot(tester, const SangatScreen());
    expect(find.text('Simran Sangat'), findsOneWidget);
    expect(find.text(l.sangatJoin), findsOneWidget);
    expect(find.text(l.sangatNoGroups), findsOneWidget);
    expect(find.text(l.sangatCreate), findsOneWidget);
  });

  testWidgets('S-2: Join a built-in group → member, and the outbox turns on', (tester) async {
    server.on('POST', '/sangat/groups/simran/join', 200, {'result': 'JOINED', 'groupId': 'simran'});
    await boot(tester, const SangatScreen());
    server.on('GET', '/sangat/groups/built-in', 200, {'groups': [builtIn(member: true)]});
    await tester.tap(find.text(l.sangatJoin));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
    await settle(tester);
    expect(server.requests, contains('POST /sangat/groups/simran/join'));
    expect(find.text(l.sangatLeave), findsOneWidget);
    expect(app.container.read(sangatMemberProvider), isTrue);
  });

  testWidgets('S-28: offline with no copy says so', (tester) async {
    server.offline = true;
    await boot(tester, const SangatScreen());
    expect(find.textContaining(l.sangatOffline), findsWidgets);
  });

  testWidgets('IV8: an invalid code is refused inline without asking the server', (tester) async {
    await boot(tester, const JoinScreen());
    await tester.enterText(find.byType(TextField), 'nope');
    await tester.tap(find.text(l.sangatJoin));
    await settle(tester);
    expect(find.text(l.sangatCodeInvalid), findsOneWidget);
    expect(server.requests.where((r) => r == 'POST /sangat/join'), isEmpty);
  });

  testWidgets('S-25: a full group says so', (tester) async {
    server.on('POST', '/sangat/join', 409, errorJson('GROUP_FULL'));
    await boot(tester, const JoinScreen(code: 'ABCD-2345'));
    await tester.tap(find.text(l.sangatJoin));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
    await settle(tester);
    expect(find.text(l.sangatGroupFull), findsOneWidget);
  });

  for (final locale in const [Locale('pa'), Locale('hi')]) {
    testWidgets('the tab lays out in ${locale.languageCode}', (tester) async {
      app = await TestApp.create(prefs: {'onboarding_done': true}, extra: server.overrides());
      addTearDown(app.dispose);
      usePhoneFrame(tester);
      await tester.pumpWidget(app.wrapRouted(const SangatScreen(), locale: locale));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
      await settle(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('ਸਿਮਰਨ ਸੰਗਤ').evaluate().isNotEmpty || find.text('सिमरन संगत').evaluate().isNotEmpty, isTrue);
    });
  }
}
