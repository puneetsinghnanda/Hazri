import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/db/user_db.dart';
import 'package:hazri/core/db/user_repository.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';
import 'package:hazri/features/hazri/ui/goal_complete_sheet.dart';

import '../app_harness.dart';

/// Design 61: a full screen listing each item met today, the hazri line, and
/// See my diary / Done.
void main() {
  testWidgets('lists what was met and closes on Done', (tester) async {
    final app = await TestApp.create(prefs: {'onboarding_done': true}, now: DateTime(2026, 10, 9, 6, 30));
    addTearDown(app.dispose);
    final repo = app.container.read(userRepositoryProvider);
    await tester.runAsync(() async {
      await repo.addItem(const GoalItemSpec.bani('JAPJ'));
      await repo.logCompletion(baniId: 'JAPJ', slot: BaniSlotValue.morning, source: CompletionSource.reader);
    });
    usePhoneFrame(tester);
    await tester.pumpWidget(app.wrapRouted(Builder(
      builder: (context) => Scaffold(
        body: TextButton(onPressed: () => showGoalCompleteSheet(context), child: const Text('open')),
      ),
    )));
    await settle(tester);
    await tester.tap(find.text('open'));
    await settle(tester);
    final l = await L.delegate.load(const Locale('en'));
    expect(find.text(l.hazriGoalsAllDone), findsOneWidget);
    expect(find.text('Japji Sahib'), findsOneWidget);
    expect(find.text(l.hazriSeeDiary), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text(l.actionDone));
    await settle(tester);
    expect(find.text(l.hazriGoalsAllDone), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 5));
  });
}
