import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/db/user_db.dart';
import 'package:hazri/core/db/user_repository.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';
import 'package:hazri/core/theme/hazri_colors.dart';
import 'package:hazri/core/time/clock.dart';
import 'package:hazri/features/badges/data/badge_controller.dart';
import 'package:hazri/features/badges/domain/badges.dart';
import 'package:hazri/features/profile/data/profile_controller.dart';
import 'package:hazri/features/profile/ui/city_field.dart';
import 'package:hazri/features/profile/ui/profile_edit_screen.dart';
import 'package:hazri/features/profile/ui/profile_screen.dart';

import '../app_harness.dart';
import '../features/profile/profile_fakes.dart';

/// Designs 100 (Profile) and 101 (Edit profile), owner 2026-10-10:
/// `01-accounts.md` §8.7 and §13.8, `12-badges.md` UI5.
void main() {
  late FakeServer server;
  late TestApp app;
  late L l;

  setUpAll(() async => l = await L.delegate.load(const Locale('en')));

  setUp(() => server = FakeServer());

  Future<void> net(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
    await settle(tester);
  }

  Future<void> create() async {
    app = await TestApp.create(
      prefs: {'onboarding_done': true},
      now: DateTime(2026, 10, 8, 9),
      extra: server.overrides(),
    );
    addTearDown(app.dispose);
  }

  /// Loads the profile first, as the Profile screen does before it pushes
  /// Edit profile, then shows [screen].
  Future<void> showLoaded(WidgetTester tester, Widget screen) async {
    usePhoneFrame(tester);
    await tester.pumpWidget(app.wrapRouted(const SizedBox()));
    app.container.read(profileControllerProvider);
    await net(tester);
    expect(app.container.read(profileControllerProvider), isA<ProfileLoaded>());
    await tester.pumpWidget(app.wrapRouted(screen));
    await net(tester);
  }

  group('Profile (design 100)', () {
    testWidgets('the three numbers: days of Hazri, days in a row, badges earned', (tester) async {
      server.on('GET', '/profile', 200, {'profile': profileJson(verified: true)});
      await create();
      final repo = app.container.read(userRepositoryProvider);
      final clock = app.container.read(clockProvider) as FixedClock;
      // Two days in early September, then 6, 7 and 8 October: five days of
      // hazri in all, three of them in a row up to today.
      for (final day in [DateTime(2026, 9, 1), DateTime(2026, 9, 2), DateTime(2026, 10, 6),
        DateTime(2026, 10, 7), DateTime(2026, 10, 8)]) {
        clock.instant = day.add(const Duration(hours: 6));
        await repo.logCompletion(baniId: 'JAPJ', slot: BaniSlotValue.morning, source: CompletionSource.reader);
      }
      clock.instant = DateTime(2026, 10, 8, 9);
      await app.container.read(badgeStoreProvider).insertNew(
        {BadgeId.jigyasu, BadgeId.shardhalu},
        today: '2026-10-08',
        silent: true,
      );
      final streak = await repo.hazriStreak();
      expect(streak.days.length, 5);
      expect(streak.current, 3);

      await showLoaded(tester, const ProfileScreen());
      final stats = find.byKey(const Key('profile-stats'));
      Finder inStats(String text) => find.descendant(of: stats, matching: find.text(text));
      expect(inStats('5'), findsOneWidget);
      expect(inStats(l.profileStatHazriDays(5)), findsOneWidget);
      expect(inStats('3'), findsOneWidget);
      expect(inStats(l.profileStatInARow), findsOneWidget);
      expect(inStats('2'), findsOneWidget);
      expect(inStats(l.profileStatBadges(2)), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('UI5: all ten badges with names, five to a shelf; See all 10', (tester) async {
      server.on('GET', '/profile', 200, {'profile': profileJson(verified: true)});
      await create();
      await showLoaded(tester, const ProfileScreen());
      expect(find.text(l.badgesSeeAll), findsOneWidget);
      for (final b in BadgeId.values) {
        expect(find.text(b.latin), findsOneWidget, reason: b.latin);
      }
      final first = BadgeId.values.take(5).map((b) => tester.getCenter(find.text(b.latin)).dy).toSet();
      final second = BadgeId.values.skip(5).map((b) => tester.getCenter(find.text(b.latin)).dy).toSet();
      expect(first, hasLength(1));
      expect(second, hasLength(1));
      expect(second.single, greaterThan(first.single));
    });

    testWidgets('Edit profile and Back up now sit side by side; Restore and the phone below', (tester) async {
      server.on('GET', '/profile', 200, {'profile': profileJson(verified: true)});
      await create();
      await showLoaded(tester, const ProfileScreen());
      final edit = tester.getCenter(find.text(l.profileEditButton));
      final backup = tester.getCenter(find.text(l.backupNowButton));
      expect(edit.dy, closeTo(backup.dy, 1));
      expect(edit.dx, lessThan(backup.dx));
      expect(find.textContaining(l.profilePhoneNotProvided), findsOneWidget);
      expect(find.text(l.restoreDataButton), findsOneWidget);
      expect(find.text(l.profilePrivacyLine), findsOneWidget);
    });
  });

  group('Edit profile (design 101)', () {
    testWidgets('Today in the city; "Changed from" only once the city is changed', (tester) async {
      server.on('GET', '/profile', 200, {'profile': profileJson(verified: true)});
      await create();
      await showLoaded(tester, const ProfileEditScreen());
      expect(find.text(l.profileEditTodayIn('New Delhi')), findsOneWidget);
      expect(find.text(l.profileEditSunrise), findsOneWidget);
      expect(find.text(l.profileEditSunset), findsOneWidget);
      expect(find.text(l.profileEditCityHelp), findsOneWidget);
      expect(find.textContaining('Changed from'), findsNothing);

      await tester.tap(find.byType(CityField));
      await settle(tester);
      await tester.enterText(find.widgetWithText(TextField, l.cityPickerSearch), 'Ludh');
      await settle(tester);
      await tester.tap(find.text('Ludhiana').last);
      await settle(tester);

      expect(find.text(l.profileEditTodayIn('Ludhiana')), findsOneWidget);
      expect(find.text(l.profileEditChangedFrom('New Delhi')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Change email is inside the email row', (tester) async {
      server.on('GET', '/profile', 200, {'profile': profileJson(verified: true)});
      await create();
      await showLoaded(tester, const ProfileEditScreen());
      final row = find.ancestor(of: find.text('harpreet@example.com'), matching: find.byType(InputDecorator));
      expect(row, findsOneWidget);
      expect(find.descendant(of: row, matching: find.text(l.profileChangeEmail)), findsOneWidget);
      expect(find.descendant(of: row, matching: find.byTooltip(l.profileVerified)), findsOneWidget);
      expect(find.text(l.profileEditEmailHelp), findsOneWidget);
    });

    testWidgets('a verified email carries no warning; a pending one is said quietly', (tester) async {
      server.on('GET', '/profile', 200,
          {'profile': profileJson(verified: true, pendingEmail: 'new@example.com')});
      await create();
      await showLoaded(tester, const ProfileEditScreen());
      expect(find.text(l.profileNotVerified), findsNothing);
      final pending = find.text(l.profileEmailPending('new@example.com'));
      expect(pending, findsOneWidget);
      final colours = HazriColors.light;
      final style = tester.widget<Text>(pending).style!;
      expect(style.color, colours.ink2);
      expect(style.color, isNot(colours.kesriInk));
    });

    testWidgets('a verified email with nothing pending: no warning at all', (tester) async {
      server.on('GET', '/profile', 200, {'profile': profileJson(verified: true)});
      await create();
      await showLoaded(tester, const ProfileEditScreen());
      expect(find.text(l.profileNotVerified), findsNothing);
      expect(find.textContaining('Waiting for you'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
