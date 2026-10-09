import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';
import 'package:hazri/features/diary/ui/diary_screen.dart';
import 'package:hazri/features/nitnem/ui/nitnem_screen.dart';
import 'package:hazri/features/simran/ui/simran_screen.dart';
import 'package:hazri/features/today/ui/today_screen.dart';

import '../app_harness.dart';

/// The menu button sits in the same place on every tab: where Today's does
/// (05-today T11). It was 20 dp further in on Nitnem, Diary and Sangat,
/// because the tab header added its own gutter inside an already-guttered list.
void main() {
  late TestApp app;
  setUp(() async {
    app = await TestApp.create(prefs: {'onboarding_done': true}, now: DateTime(2026, 10, 9, 6, 30));
  });
  tearDown(() => app.dispose());

  Future<Rect> menuOn(WidgetTester tester, Widget screen) async {
    usePhoneFrame(tester);
    await tester.pumpWidget(app.wrapRouted(screen));
    await settle(tester);
    final l = await L.delegate.load(const Locale('en'));
    final rect = tester.getRect(find.byTooltip(l.menuTooltip).first);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 5));
    return rect;
  }

  const expected = Rect.fromLTWH(20, 10, 44, 44); // Today's, measured below
  testWidgets('Today\'s menu is at 20, 10 and 44 dp square', (tester) async {
    expect(await menuOn(tester, const TodayScreen()), expected);
  });
  for (final (name, screen) in const <(String, Widget)>[
    ('Nitnem', NitnemScreen()),
    ('Simran', SimranScreen()),
    ('Diary', DiaryScreen()),
  ]) {
    testWidgets('$name puts the menu where Today does', (tester) async {
      expect(await menuOn(tester, screen), expected);
    });
  }
}
