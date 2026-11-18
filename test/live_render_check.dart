import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/db/content_repository.dart';
import 'package:hazri/features/audio/data/audio_controller.dart';
import 'package:hazri/features/live/domain/live_group.dart';
import 'package:hazri/features/live/ui/live_screen.dart';
import 'package:hazri/features/sangat/ui/sangat_screen.dart';
import 'package:hazri/features/simran/domain/world_outline.dart';
import 'features/profile/profile_fakes.dart';

import 'app_harness.dart';

/// Renders the live sangat screens (15-live-sangat) to PNGs so they can be
/// looked at, as `render_check.dart` does for Simran.
///
/// Deliberately **not** named `*_test.dart`, so `flutter test` and CI ignore
/// it. Run it by name when a screen needs checking by eye:
///
///     flutter test test/render_check.dart
///     # then open /tmp/hazri-*.png
///
/// It exists because looking at the Simran screen found three things no
/// assertion had: a kicker wrapping to two lines, ੴ clipped in half by its
/// own line box, and ਵਾਹਿਗੁਰੂ not being drawn at all.
///
/// One `testWidgets` per picture. A second `pumpWidget` over a tree whose
/// tickers are still running never comes back, so each shot gets its own.
void main() {
  setUpAll(() async {
    Future<void> font(String family, List<String> files) async {
      final loader = FontLoader(family);
      for (final f in files) {
        loader.addFont(
            Future.value(File(f).readAsBytesSync().buffer.asByteData()));
      }
      await loader.load();
    }

    await font('PlayfairDisplay', [
      'assets/fonts/PlayfairDisplay-Regular.ttf',
      'assets/fonts/PlayfairDisplay-Medium.ttf',
      'assets/fonts/PlayfairDisplay-SemiBold.ttf',
      'assets/fonts/PlayfairDisplay-Bold.ttf',
    ]);
    await font('Mukta', [
      'assets/fonts/Mukta-Regular.ttf',
      'assets/fonts/Mukta-Medium.ttf',
      'assets/fonts/Mukta-SemiBold.ttf',
      'assets/fonts/Mukta-Bold.ttf',
    ]);
    await font('NotoSerifGurmukhi', [
      'assets/fonts/NotoSerifGurmukhi-Regular.ttf',
      'assets/fonts/NotoSerifGurmukhi-Medium.ttf',
      'assets/fonts/NotoSerifGurmukhi-SemiBold.ttf',
    ]);
    await font('NotoSerifDevanagari', [
      'assets/fonts/NotoSerifDevanagari-Regular.ttf',
      'assets/fonts/NotoSerifDevanagari-Medium.ttf',
    ]);
    await font('BalooPaaji2', ['assets/fonts/BalooPaaji2-Medium.ttf']);
  });

  Future<void> shoot(WidgetTester tester, String name) async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byType(RepaintBoundary).first,
    );
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('/tmp/hazri-$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    // ignore: avoid_print
    print('WROTE /tmp/hazri-$name.png');
  }

  void phone(WidgetTester tester, {double width = 390, double height = 844}) {
    tester.view.physicalSize = Size(width * 3, height * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Map<String, Object?> liveBody({bool joined = true}) => {
        'groups': [
          for (final d in liveGroups)
            {
              'id': d.id, 'listening': 214, 'cities': 38,
              'cityIds': ['ludhiana', 'amritsar', 'toronto', 'london', 'melbourne', 'vancouver', 'new_delhi'],
              'members': 3, 'minutesToday': 4210, 'minutesMonth': 91240,
              'joins': [
                {'name': 'Harpreet K.', 'cityId': 'ludhiana'},
                {'name': 'Gurdeep S.', 'cityId': 'amritsar'},
              ],
              'memberRows': [
                {'name': 'Gurdeep S.', 'cityId': 'amritsar', 'minutesMonth': 320},
              ],
              'joined': joined && d.id == 'naam-simran',
            },
        ],
      };

  for (final id in ['naam-simran', 'mool-mantar', 'chaupai-sahib']) {
    testWidgets('live $id', (tester) async {
      final server = FakeServer()
        ..on('GET', '/profile', 404, errorJson('NO_PROFILE'))
        ..on('GET', '/live', 200, liveBody());
      late TestApp app;
      await tester.runAsync(() async {
        app = await TestApp.create(prefs: {'onboarding_done': true},
            extra: [...server.overrides(), paathPlayerProvider.overrideWithValue(FakePaathPlayer())]);
        await app.container.read(worldOutlineProvider.future);
        await app.container.read(ikOnkarProvider.future);
        await app.container.read(citiesProvider.future);
      });
      phone(tester);
      await tester.pumpWidget(RepaintBoundary(child: app.wrapRouted(LiveScreen(groupId: id))));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
      for (var i = 0; i < 10; i++) { await tester.pump(const Duration(milliseconds: 100)); }
      await tester.runAsync(() => shoot(tester, 'live-$id'));
      await tester.pumpWidget(const SizedBox());
      app.dispose();
    });
  }

  testWidgets('discover', (tester) async {
    final server = FakeServer()
      ..on('GET', '/profile', 404, errorJson('NO_PROFILE'))
      ..on('GET', '/sangat/groups/mine', 200, {'groups': []})
      ..on('GET', '/sangat/groups/built-in', 200, {'groups': []})
      ..on('POST', '/sangat/contributions', 200, {'processed': []})
      ..on('GET', '/live', 200, liveBody(joined: false));
    late TestApp app;
    await tester.runAsync(() async {
      app = await TestApp.create(prefs: {'onboarding_done': true}, extra: server.overrides());
      await app.container.read(worldOutlineProvider.future);
      await app.container.read(ikOnkarProvider.future);
    });
    phone(tester);
    await tester.pumpWidget(RepaintBoundary(child: app.wrapRouted(const SangatScreen())));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    for (var i = 0; i < 10; i++) { await tester.pump(const Duration(milliseconds: 100)); }
    await tester.runAsync(() => shoot(tester, 'discover'));
    await tester.pumpWidget(const SizedBox());
    app.dispose();
  });
}
