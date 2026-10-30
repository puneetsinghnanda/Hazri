import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/backend/backend.dart';
import 'package:hazri/features/about/ui/privacy_screen.dart';
import 'package:hazri/features/audio/data/notification_access.dart';

import '../app_harness.dart';
import '../features/notification_access_test.dart' show FakeSystemSettings;

/// The way to ask for an account's deletion from inside the app, which Google
/// Play asks of an app with accounts (`01-accounts.md` §12, 2026-10-30).
void main() {
  test('the deletion page is not on a host the app claims as an App Link', () {
    // The manifest's autoVerify filter has no path restriction, so a link to
    // any path on one of its hosts opens Hazri, not a browser: the row would
    // send somebody straight back to the screen they tapped it on.
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    final claimed = RegExp(r'android:host="([^"]+)"')
        .allMatches(manifest)
        .map((m) => m.group(1)!)
        .toSet();
    expect(claimed, contains(Uri.parse(kSiteBase).host),
        reason: 'the regex should find the App Link hosts');
    expect(claimed, isNot(contains(Uri.parse(kDeleteAccountUrl).host)));
    expect(kDeleteAccountUrl, startsWith('https://'));
  });

  group('Privacy & my data', () {
    late TestApp app;
    late _Settings settings;

    setUp(() async {
      settings = _Settings();
      app = await TestApp.create(extra: [
        systemSettingsProvider.overrideWithValue(settings),
      ]);
    });

    tearDown(() => app.dispose());

    Future<void> tapDelete(WidgetTester tester) async {
      usePhoneFrame(tester);
      await tester.pumpWidget(app.wrap(const PrivacyScreen()));
      await settle(tester);
      final row = find.text('Delete my account and data');
      await tester.scrollUntilVisible(row, 200, scrollable: find.byType(Scrollable).first);
      await tester.tap(row);
      await settle(tester);
    }

    testWidgets('the delete row opens the website deletion page', (tester) async {
      await tapDelete(tester);
      expect(settings.urls, [kDeleteAccountUrl]);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('with no browser it says where the page is', (tester) async {
      settings.opens = false;
      await tapDelete(tester);
      expect(settings.urls, [kDeleteAccountUrl]);
      expect(find.textContaining('hazri.me/delete-account'), findsWidgets);
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}

class _Settings extends FakeSystemSettings {
  bool opens = true;

  @override
  Future<bool> openUrl(String url) async {
    await super.openUrl(url);
    return opens;
  }
}
