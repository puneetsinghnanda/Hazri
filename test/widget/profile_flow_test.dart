import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';
import 'package:hazri/features/profile/data/profile_controller.dart';
import 'package:hazri/features/profile/ui/link_result_screen.dart';
import 'package:hazri/features/profile/ui/profile_screen.dart';
import 'package:hazri/features/profile/ui/profile_setup_screen.dart';

import '../app_harness.dart';
import '../features/profile/profile_fakes.dart';

/// `01-accounts.md` §9 scenarios at the screen seam, against a fake server.
void main() {
  late FakeServer server;
  late TestApp app;
  late L l;

  setUpAll(() async => l = await L.delegate.load(const Locale('en')));

  Future<void> boot(WidgetTester tester, Widget screen) async {
    app = await TestApp.create(prefs: {'onboarding_done': true}, extra: server.overrides());
    addTearDown(app.dispose);
    usePhoneFrame(tester);
    await tester.pumpWidget(app.wrapRouted(screen));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await settle(tester);
  }

  Future<void> net(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await settle(tester);
  }

  setUp(() {
    server = FakeServer();
    server.on('GET', '/profile', 404, errorJson('NO_PROFILE'));
  });

  group('Profile Setup (§8.5)', () {
    testWidgets('empty submit shows every required message and sends nothing', (tester) async {
      await boot(tester, const ProfileSetupScreen());
      await tester.tap(find.text(l.profileSave));
      await settle(tester);
      expect(find.text(l.profileErrNameEmpty), findsOneWidget);
      expect(find.text(l.profileErrEmailEmpty), findsOneWidget);
      expect(find.text(l.profileErrCityEmpty), findsOneWidget);
      expect(server.requests.where((r) => r.startsWith('POST')), isEmpty);
    });

    testWidgets('an invalid email is refused inline', (tester) async {
      await boot(tester, const ProfileSetupScreen());
      await tester.enterText(find.widgetWithText(TextFormField, l.profileFieldEmail), 'not-an-email');
      await tester.tap(find.text(l.profileSave));
      await settle(tester);
      expect(find.text(l.profileErrEmailInvalid), findsOneWidget);
    });
  });

  group('Link Result (§8.9)', () {
    testWidgets('200 EMAIL_VERIFIED says so only after the server answered', (tester) async {
      server.on('POST', '/tokens/verify', 200,
          {'result': 'EMAIL_VERIFIED', 'purpose': 'VERIFY_EMAIL', 'isOwner': true, 'profile': profileJson(verified: true)});
      await boot(tester, const LinkResultScreen(token: 'abc'));
      await net(tester);
      expect(find.text(l.linkEmailVerifiedTitle), findsOneWidget);
      expect(find.text(l.linkEmailVerified), findsOneWidget);
      expect(server.requests, contains('POST /tokens/verify'));
    });

    testWidgets('410 expired on an unverified profile offers a new link', (tester) async {
      server.on('GET', '/profile', 200, {'profile': profileJson()});
      server.on('POST', '/tokens/verify', 410, errorJson('TOKEN_EXPIRED', {'purpose': 'VERIFY_EMAIL'}));
      // The profile is loaded first: the button rule reads it.
      await boot(tester, const SizedBox());
      app.container.read(profileControllerProvider);
      await net(tester);
      expect(app.container.read(profileControllerProvider), isA<ProfileLoaded>());
      await tester.pumpWidget(app.wrapRouted(const LinkResultScreen(token: 'abc')));
      await net(tester);
      expect(find.text(l.linkExpiredTitle), findsOneWidget);
      expect(find.text(l.linkSendNew), findsOneWidget);
      expect(find.text(l.linkGoHome), findsOneWidget);
    });

    testWidgets('403 RESTORE_WRONG_DEVICE says which phone', (tester) async {
      server.on('POST', '/tokens/verify', 403, errorJson('RESTORE_WRONG_DEVICE', {'purpose': 'RESTORE_PROFILE'}));
      await boot(tester, const LinkResultScreen(token: 'abc'));
      await net(tester);
      expect(find.text(l.linkWrongPhone), findsOneWidget);
      expect(find.text(l.linkGoHome), findsOneWidget);
    });

    testWidgets('no network offers Retry and Go to Home', (tester) async {
      server.offline = true;
      await boot(tester, const LinkResultScreen(token: 'abc'));
      await net(tester);
      expect(find.text(l.linkCouldNotCheckTitle), findsOneWidget);
      expect(find.text(l.profileRetry), findsOneWidget);
    });
  });

  group('Profile screen (§8.7)', () {
    testWidgets('no profile: says so and offers Set up profile', (tester) async {
      await boot(tester, const ProfileScreen());
      await net(tester);
      expect(find.text(l.profileNone), findsOneWidget);
      expect(find.text(l.profileSetupTitle), findsWidgets);
    });

    testWidgets('unverified: the rows, Not verified, Change email and Confirm my email', (tester) async {
      server.on('GET', '/profile', 200, {'profile': profileJson()});
      await boot(tester, const ProfileScreen());
      await net(tester);
      expect(find.text('Harpreet Kaur'), findsOneWidget);
      expect(find.text(l.profileNotVerified), findsOneWidget);
      expect(find.text(l.profileChangeEmail), findsOneWidget);
      expect(find.text(l.profileConfirmEmail), findsOneWidget);
      expect(find.text(l.profileNotProvided), findsOneWidget);
    });

    testWidgets('verified: no Change email under the row, no Confirm button', (tester) async {
      server.on('GET', '/profile', 200, {'profile': profileJson(verified: true)});
      await boot(tester, const ProfileScreen());
      await net(tester);
      expect(find.text(l.profileVerified), findsOneWidget);
      expect(find.text(l.profileChangeEmail), findsNothing);
      expect(find.text(l.profileConfirmEmail), findsNothing);
    });

    testWidgets('Change email to the same address says so and sends nothing', (tester) async {
      server.on('GET', '/profile', 200, {'profile': profileJson()});
      await boot(tester, const ProfileScreen());
      await net(tester);
      await tester.tap(find.text(l.profileChangeEmail));
      await settle(tester);
      await tester.enterText(find.widgetWithText(TextFormField, l.changeEmailField), ' HARPREET@example.com ');
      await tester.tap(find.text(l.changeEmailSave));
      await settle(tester);
      expect(find.text(l.changeEmailSame), findsOneWidget);
      expect(server.requests.where((r) => r == 'PATCH /profile/email'), isEmpty);
    });
  });
}
