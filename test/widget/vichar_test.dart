import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/theme/hazri_theme.dart';
import 'package:hazri/core/widgets/app_icon.dart';
import 'package:hazri/core/theme/icon_data.dart';
import 'package:hazri/app/router.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hazri/core/db/content_repository.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';
import 'package:hazri/features/today/ui/today_screen.dart';
import 'package:hazri/features/vichar/ui/vichar_card.dart';
import 'package:hazri/features/vichar/ui/vichar_screen.dart';
import 'package:hazri/features/vichar/ui/vichar_share.dart';

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

  test('every share is a new file, and the old ones go', () async {
    // Android previews a name it has seen from its cache: the same name every
    // time showed the first, dark card while the cream one was sent.
    final dir = await Directory.systemTemp.createTemp('vichar');
    addTearDown(() => dir.delete(recursive: true));
    File('${dir.path}/vichar.png').writeAsBytesSync([1]);
    File('${dir.path}/other.png').writeAsBytesSync([1]);

    final a = await writeShareImage(dir, [2], DateTime(2026, 10, 10, 9));
    final b = await writeShareImage(dir, [3], DateTime(2026, 10, 10, 9, 1));

    expect(a.path, isNot(b.path));
    final names = dir.listSync().map((f) => f.uri.pathSegments.last).toSet();
    expect(names, {b.uri.pathSegments.last, 'other.png'});
    expect(b.readAsBytesSync(), [3]);
  });

  testWidgets('Explore opens the day\'s line in full, and the card has no chevron', (tester) async {
    usePhoneFrame(tester);
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, _) => const Scaffold(body: VicharCard())),
      GoRoute(path: Routes.vichar, builder: (_, _) => const Scaffold(body: Text('vichar screen'))),
    ]);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: app.container,
      child: MaterialApp.router(
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        theme: HazriTheme.light(),
        routerConfig: router,
      ),
    ));
    await settle(tester);
    final l = await L.delegate.load(const Locale('en'));
    expect(
      find.byWidgetPredicate((w) => w is AppIcon && w.data == HazriIconData.chevronRight),
      findsNothing,
    );
    await tester.tap(find.text(l.vicharExplore));
    await settle(tester);
    expect(find.text('vichar screen'), findsOneWidget);
  });
}
