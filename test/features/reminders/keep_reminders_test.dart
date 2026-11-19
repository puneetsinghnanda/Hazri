import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';
import 'package:hazri/core/platform/system_settings.dart';
import 'package:hazri/core/settings/settings_controller.dart';
import 'package:hazri/features/audio/data/notification_access.dart';
import 'package:hazri/features/reminders/ui/keep_reminders_card.dart';

import '../../app_harness.dart';

class _Settings implements SystemSettings {
  _Settings({this.unused, this.battery});
  bool? unused;
  bool? battery;
  final opened = <String>[];

  @override
  Future<bool?> unusedAppExempt() async => unused;
  @override
  Future<bool?> ignoringBatteryOptimizations() async => battery;
  @override
  Future<bool> openUnusedAppSettings() async {
    opened.add('unused');
    return true;
  }
  @override
  Future<bool> openAppSettings() async {
    opened.add('app');
    return true;
  }
  @override
  Future<bool> openNotificationSettings() async => true;
  @override
  Future<String?> installReferrer() async => null;
  @override
  Future<bool> openUrl(String url) async => true;
}

/// 02-notifications KA1, KA2 (owner, 2026-11-19).
void main() {
  late L l;
  setUpAll(() async => l = await L.delegate.load(const Locale('en')));

  Future<TestApp> boot(WidgetTester tester, _Settings s, Widget child, {Map<String, Object> prefs = const {}}) async {
    final app = await TestApp.create(
      prefs: {'onboarding_done': true, ...prefs},
      extra: [systemSettingsProvider.overrideWithValue(s)],
    );
    addTearDown(app.dispose);
    usePhoneFrame(tester);
    await tester.pumpWidget(app.wrapRouted(child));
    await settle(tester);
    return app;
  }

  testWidgets('KA1: a setting still to switch offers Open, which opens its page; one done shows a tick',
      (tester) async {
    final s = _Settings(unused: false, battery: true);
    await boot(tester, s, const Scaffold(body: KeepRemindersCard()));
    expect(find.text(l.keepAwakeTitle), findsOneWidget);
    expect(find.text(l.keepAwakeOpen), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is Semantics && w.properties.label == l.keepAwakeDone), findsOneWidget);
    await tester.tap(find.text(l.keepAwakeOpen));
    await settle(tester);
    expect(s.opened, ['unused']);
  });

  testWidgets('KA1: before Android 11 there is no unused-app setting, only the battery row', (tester) async {
    final s = _Settings(unused: null, battery: false);
    await boot(tester, s, const Scaffold(body: KeepRemindersCard()));
    expect(find.text(l.keepAwakeUnusedTitle), findsNothing);
    expect(find.text(l.keepAwakeBatteryTitle), findsOneWidget);
    await tester.tap(find.text(l.keepAwakeOpen));
    expect(s.opened, ['app']);
  });

  testWidgets('KA2: the sheet shows once, and never when nothing is left to switch', (tester) async {
    final s = _Settings(unused: false, battery: false);
    late WidgetRef captured;
    final app = await boot(
      tester,
      s,
      Scaffold(body: Consumer(builder: (context, ref, _) {
        captured = ref;
        return TextButton(onPressed: () => maybeShowKeepAwakeSheet(context, ref), child: const Text('go'));
      })),
    );
    await tester.tap(find.text('go'));
    await settle(tester);
    expect(find.text(l.keepAwakeLater), findsOneWidget);
    await tester.tap(find.text(l.keepAwakeLater));
    await settle(tester);
    expect(app.container.read(sharedPreferencesProvider).getBool(kKeepAwakeAsked), isTrue);
    await tester.tap(find.text('go'));
    await settle(tester);
    expect(find.text(l.keepAwakeLater), findsNothing, reason: 'asked once, never again');
    expect(captured, isNotNull);
  });

  testWidgets('KA2: with both settings already right, no sheet', (tester) async {
    final s = _Settings(unused: true, battery: true);
    await boot(
      tester,
      s,
      Scaffold(body: Consumer(builder: (context, ref, _) {
        return TextButton(onPressed: () => maybeShowKeepAwakeSheet(context, ref), child: const Text('go'));
      })),
    );
    await tester.tap(find.text('go'));
    await settle(tester);
    expect(find.text(l.keepAwakeLater), findsNothing);
  });
}
