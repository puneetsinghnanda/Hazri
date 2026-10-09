import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/db/content_repository.dart';
import 'package:hazri/core/settings/app_settings.dart';
import 'package:hazri/features/reader/ui/gurbani_line_view.dart';

import '../app_harness.dart';

/// The line being recited is highlighted edge to edge. It used a negative
/// margin to get there, which Container asserts against: the reader threw on
/// the current line in every debug build, and nothing rendered one.
void main() {
  testWidgets('the current line renders without an assertion', (tester) async {
    final app = await TestApp.create(prefs: {'onboarding_done': true});
    addTearDown(app.dispose);
    final banis = await tester.runAsync(() => app.container.read(banisProvider.future));
    final japji = banis!.firstWhere((b) => b.id == 'JAPJ');
    final lines = await tester.runAsync(() => app.container.read(baniLinesProvider(japji.versionId!).future));
    usePhoneFrame(tester);
    await tester.pumpWidget(app.wrap(Scaffold(
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        children: [
          GurbaniLineView(line: lines![2], settings: const AppSettings(), highlight: LineHighlight.current),
          GurbaniLineView(line: lines[3], settings: const AppSettings()),
        ],
      ),
    )));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
