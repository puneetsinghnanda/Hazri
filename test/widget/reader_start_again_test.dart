import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/app/router.dart';
import 'package:hazri/core/db/content_repository.dart';
import 'package:hazri/core/db/user_repository.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';
import 'package:hazri/core/theme/hazri_theme.dart';
import 'package:hazri/features/audio/data/audio_controller.dart';
import 'package:hazri/features/audio/domain/paath_player.dart';

import '../app_harness.dart';

/// Design 48's Start again: the first line, and the recitation back at 0:00.
/// The scrubber used to stay at the end, so starting again meant dragging it
/// back by hand (2026-10-10).
void main() {
  testWidgets('Start again puts the recitation at 0:00, paused, and keeps no end position',
      (tester) async {
    final player = FakePaathPlayer();
    final app = await TestApp.create(
      prefs: {'onboarding_done': true},
      extra: [paathPlayerProvider.overrideWithValue(player)],
    );
    addTearDown(app.dispose);
    final banis = await tester.runAsync(() => app.container.read(banisProvider.future));
    final japji = banis!.firstWhere((b) => b.id == 'JAPJ');
    final lines = await tester.runAsync(() => app.container.read(baniLinesProvider(japji.versionId!).future));

    // Heard to the end.
    await player.setQueue([
      PaathTrack(
        baniId: japji.id,
        slug: japji.slug,
        title: 'Japji Sahib',
        nativeTitle: japji.nativeName,
        assetPath: 'x',
        duration: const Duration(minutes: 19),
        route: Routes.reader(japji.slug),
      ),
    ], at: const Duration(minutes: 18, seconds: 59));
    await player.play();

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
    await tester.pump();
    router.push(Routes.reader(japji.slug, line: lines!.length - 1));
    await settle(tester);

    final l = await L.delegate.load(const Locale('en'));
    final button = find.text(l.readerStartAgain);
    await tester.scrollUntilVisible(button, 200, scrollable: find.byType(Scrollable).last);
    await tester.tap(button);
    await settle(tester);

    expect(player.position, Duration.zero);
    expect(player.isPlaying, isFalse);
    final saved = await tester.runAsync(
        () => app.container.read(userRepositoryProvider).progressFor(japji.versionId!));
    expect(saved?.lineIdx ?? 0, 0, reason: 'the old screen must not write the end back as it closes');
    expect(saved?.audioPosMs ?? 0, 0);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));
  });
}
