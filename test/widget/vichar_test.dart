import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/db/content_repository.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';
import 'package:hazri/features/today/ui/today_screen.dart';
import 'package:hazri/features/vichar/ui/vichar_card.dart';
import 'package:hazri/features/vichar/ui/vichar_screen.dart';

import '../app_harness.dart';

/// ਅੱਜ ਦਾ ਵਿਚਾਰ on Today and in full (PRD 1.11).
void main() {
  late TestApp app;

  setUp(() async {
    app = await TestApp.create(
      prefs: {'onboarding_done': true},
      now: DateTime(2026, 9, 13, 6, 30),
    );
  });

  tearDown(() => app.dispose());

  testWidgets('this build ships the whole cycle', (tester) async {
    final vichar = await app.container.read(todayVicharProvider.future);
    expect(vichar, isNotNull);
    expect(vichar!.gurmukhi, isNotEmpty);
    expect(vichar.meaningPa, isNotEmpty);
    expect(vichar.hasEnglish, isTrue);
  });

  testWidgets('Today shows the line and its meaning', (tester) async {
    usePhoneFrame(tester);
    await tester.pumpWidget(app.wrapRouted(const VicharCard()));
    await settle(tester);

    final vichar = await app.container.read(todayVicharProvider.future);
    final l = await L.delegate.load(const Locale('en'));
    expect(find.text(l.vicharTitle), findsOneWidget);
    expect(find.text(vichar!.gurmukhi), findsOneWidget);
    expect(find.text(vichar.meaningEn), findsOneWidget);
    // No Ang anywhere: this dataset has none and the app does not invent one.
    expect(find.textContaining('Ang'), findsNothing);
  });

  testWidgets('the full screen carries both meanings', (tester) async {
    usePhoneFrame(tester);
    await tester.pumpWidget(app.wrapRouted(const VicharScreen()));
    await settle(tester);

    final vichar = await app.container.read(todayVicharProvider.future);
    final l = await L.delegate.load(const Locale('en'));
    expect(find.text(vichar!.meaningPa), findsOneWidget);
    expect(find.text(vichar.meaningEn), findsOneWidget);
    expect(find.text(l.vicharSource), findsOneWidget);
  });

  testWidgets('a Hindi reader gets the Punjabi meaning, not English',
      (tester) async {
    usePhoneFrame(tester);
    await tester.pumpWidget(
      app.wrapRouted(const VicharCard(), locale: const Locale('hi')),
    );
    await settle(tester);

    final vichar = await app.container.read(todayVicharProvider.future);
    expect(find.text(vichar!.meaningPa), findsOneWidget);
    expect(find.text(vichar.meaningEn), findsNothing);
  });

  testWidgets('Today no longer mentions the Hukamnama', (tester) async {
    usePhoneFrame(tester);
    await tester.pumpWidget(app.wrapRouted(const TodayScreen()));
    await settle(tester);
    expect(find.textContaining('Hukamnama'), findsNothing);
    expect(find.byType(VicharCard), findsOneWidget);
  });
}
