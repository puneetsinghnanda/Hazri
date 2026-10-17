import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';
import 'package:hazri/features/simran/domain/simran_presence.dart';
import 'package:hazri/features/simran/domain/world_outline.dart';
import 'package:hazri/features/simran/ui/simran_globe.dart';

/// 07-simran ZM1–ZM3 and TT1–TT3: the globe in the hand. Built from dots
/// alone, so the tests do not depend on a snapshot or the network.
void main() {
  const size = 320.0;

  // The middle of the disc when the globe has not turned: 0°N 0°E.
  const centreDots = [
    GlobeDot(cityId: 'accra', lat: 0, lon: 0, kind: DotKind.you, count: 1, radius: dotYouRadius),
    GlobeDot(cityId: 'accra', lat: 0, lon: 0, kind: DotKind.live, count: 2, radius: 6),
    GlobeDot(cityId: 'lagos', lat: 6.5, lon: 3.4, kind: DotKind.live, count: 3, radius: 7),
  ];

  Future<void> pump(WidgetTester tester, {bool youLive = true}) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [worldOutlineProvider.overrideWith((ref) async => WorldOutline.empty)],
      child: MaterialApp(
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: Scaffold(
          body: Center(
            child: SimranGlobe(
              dots: centreDots,
              cityNames: const {'accra': 'Accra', 'lagos': 'Lagos'},
              youLive: youLive,
              size: size,
              spinning: false,
            ),
          ),
        ),
      ),
    ));
    await tester.pump();
  }

  GlobePainter painterOf(WidgetTester tester) => tester
      .widget<CustomPaint>(find.descendant(of: find.byType(SimranGlobe), matching: find.byType(CustomPaint)))
      .painter! as GlobePainter;

  testWidgets('ZM1: a pinch brings the earth nearer, and no further than the limit', (tester) async {
    await pump(tester);
    expect(painterOf(tester).zoom, 1);
    final c = tester.getCenter(find.byType(SimranGlobe));
    final a = await tester.startGesture(c - const Offset(20, 0));
    final b = await tester.startGesture(c + const Offset(20, 0), pointer: 2);
    await a.moveTo(c - const Offset(60, 0));
    await b.moveTo(c + const Offset(60, 0));
    await tester.pump();
    expect(painterOf(tester).zoom, greaterThan(1.3));
    await a.moveTo(c - const Offset(600, 0));
    await b.moveTo(c + const Offset(600, 0));
    await tester.pump();
    expect(painterOf(tester).zoom, SimranGlobe.maxZoom);
    await a.up();
    await b.up();
  });

  testWidgets('ZM2: two quick taps zoom in, and from all the way in, back out', (tester) async {
    await pump(tester);
    final c = tester.getCenter(find.byType(SimranGlobe)) + const Offset(0, 120);
    await tester.tapAt(c);
    await tester.pump(const Duration(milliseconds: 80));
    await tester.tapAt(c);
    await tester.pump();
    expect(painterOf(tester).zoom, greaterThan(2));
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tapAt(c);
      await tester.pump(const Duration(milliseconds: 80));
      await tester.tapAt(c);
      await tester.pump();
    }
    expect(painterOf(tester).zoom, 1);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('TT1–TT2: a tap on your city names it and counts you as live', (tester) async {
    await pump(tester);
    await tester.tapAt(tester.getCenter(find.byType(SimranGlobe)));
    await tester.pump();
    expect(find.text('Accra'), findsOneWidget);
    expect(find.text('You are here'), findsOneWidget);
    // Two others plus you, once your attendance is marked.
    expect(find.text('3 live today'), findsOneWidget);
    // TT3: it goes by itself.
    await tester.pump(const Duration(seconds: 6));
    expect(find.text('Accra'), findsNothing);
  });

  testWidgets('TT2: not marked yet, you are counted here today instead', (tester) async {
    await pump(tester, youLive: false);
    await tester.tapAt(tester.getCenter(find.byType(SimranGlobe)));
    await tester.pump();
    expect(find.text('2 live today'), findsOneWidget);
    expect(find.text('1 here today'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('a tap on the sea shows nothing', (tester) async {
    await pump(tester);
    await tester.tapAt(tester.getCenter(find.byType(SimranGlobe)) + const Offset(0, 120));
    await tester.pump();
    expect(find.text('Accra'), findsNothing);
    expect(find.text('Lagos'), findsNothing);
    await tester.pump(const Duration(seconds: 1));
  });

  test('DR8: an arc on the surface lands where the map puts the same place', () {
    const d = math.pi / 180;
    for (final (lat, lon) in [(31.6, 74.9), (-33.9, 151.2), (51.5, -0.4)]) {
      for (final rot in [0.0, 1.0, 2.5]) {
        final p = GlobePainter.project(
          cosPhi: math.cos(lat * d), sinPhi: math.sin(lat * d),
          cosLambda: math.cos(lon * d), sinLambda: math.sin(lon * d),
          r: 100, cosR: math.cos(rot), sinR: math.sin(rot), cosT: math.cos(0.3), sinT: math.sin(0.3),
        );
        final v = GlobePainter.projectVec(
          math.cos(lat * d) * math.cos(lon * d), math.cos(lat * d) * math.sin(lon * d), math.sin(lat * d),
          r: 100, cosR: math.cos(rot), sinR: math.sin(rot), cosT: math.cos(0.3), sinT: math.sin(0.3),
        );
        if (p == null) {
          expect(v, isNull);
        } else {
          expect(v!.dx, closeTo(p.dx, 1e-9));
          expect(v.dy, closeTo(p.dy, 1e-9));
        }
      }
    }
  });
}
