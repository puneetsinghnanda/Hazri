import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/db/user_db.dart';
import 'package:hazri/core/db/user_repository.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';
import 'package:hazri/features/goals/ui/goals_screen.dart';

import '../app_harness.dart';

/// The reported fault: finish a bani and the count still reads zero.
void main() {
  late TestApp app;

  setUp(() async {
    app = await TestApp.create(
      prefs: {'onboarding_done': true},
      now: DateTime(2026, 9, 12, 6, 30),
    );
    await app.container
        .read(userRepositoryProvider)
        .addItem(const GoalItemSpec.bani('JAPJ', timesPerDay: 2));
  });

  tearDown(() => app.dispose());

  testWidgets('a completion moves the count while the screen is open',
      (tester) async {
    usePhoneFrame(tester);
    await tester.pumpWidget(app.wrapRouted(const GoalsScreen()));
    await settle(tester);
    final l = await L.delegate.load(const Locale('en'));
    expect(find.text(l.goalTimesOfTarget(0, 2)), findsOneWidget);

    // What the reader and the player both do when a bani finishes.
    await tester.runAsync(() => app.container.read(userRepositoryProvider).logCompletion(
          baniId: 'JAPJ',
          slot: BaniSlotValue.morning,
          source: CompletionSource.reader,
        ));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await settle(tester);

    expect(find.text(l.goalTimesOfTarget(1, 2)), findsOneWidget);
  });
}
