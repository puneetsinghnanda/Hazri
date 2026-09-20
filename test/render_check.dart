import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/db/content_repository.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';
import 'package:hazri/features/simran/ui/simran_naam.dart';
import 'package:hazri/features/simran/ui/simran_screen.dart';

import 'app_harness.dart';

/// Renders screens to PNGs so they can be looked at.
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

  for (final locale in const [Locale('en'), Locale('pa'), Locale('hi')]) {
    testWidgets('simran ${locale.languageCode}', (tester) async {
      final app = await TestApp.create(prefs: {'onboarding_done': true});
      addTearDown(app.dispose);
      phone(tester);
      await tester.pumpWidget(RepaintBoundary(
        child: app.wrapRouted(const SimranScreen(), locale: locale),
      ));
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await shoot(tester, 'simran-${locale.languageCode}');
    });
  }

  testWidgets('naam', (tester) async {
    final app = await TestApp.create(prefs: {'onboarding_done': true});
    addTearDown(app.dispose);
    final track = await app.container.read(simranTrackProvider.future);
    final l = await L.delegate.load(const Locale('en'));

    phone(tester, width: 390, height: 390);
    // Through MaterialApp: the globe asks MediaQuery whether the system
    // wants less motion, and without one it throws into the red error box.
    await tester.pumpWidget(RepaintBoundary(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: ColoredBox(
          color: const Color(0xFF040819),
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // A plain disc rather than the real globe: this picture is
                // about the words and how strongly they read, and the globe
                // wants more of an app around it than a bare tree gives.
                Container(
                  width: 340,
                  height: 340,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Color(0xFF071232), Color(0xFF0A1F52)],
                      stops: [0.72, 1],
                    ),
                  ),
                ),
                SimranNaam(
                  size: 340,
                  word: l.simranWaheguru,
                  track: track,
                  elapsed: const Duration(seconds: 40),
                  running: true,
                ),
              ],
            ),
          ),
        ),
      ),
    ));
    for (var i = 0; i < 14; i++) {
      await tester.pump(const Duration(milliseconds: 90));
    }
    await shoot(tester, 'naam');
  });
}
