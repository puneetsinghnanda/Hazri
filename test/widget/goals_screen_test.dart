import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/db/user_db.dart';
import 'package:hazri/core/db/user_repository.dart';
import 'package:hazri/core/time/clock.dart';
import 'package:hazri/features/goals/ui/goals_screen.dart';

import '../app_harness.dart';

/// The reported fault: finish a goal and the count still reads zero.
void main() {
  late TestApp app;

  setUp(() async {
    app = await TestApp.create(
      prefs: {'onboarding_done': true},
      now: DateTime(2026, 9, 12, 6, 30),
    );
    await app.container.read(userRepositoryProvider).saveGoal(
          GoalsCompanion.insert(
            id: 'g1',
            baniId: 'JAPJ',
            timesPerDay: const Value(2),
            durationType: GoalDuration.everyDay,
            startDate: localDateKey(DateTime(2026, 9, 12)),
            createdAt: DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
          ),
        );
  });

  tearDown(() => app.dispose());

  testWidgets('finishing a bani moves the count while the screen is open',
      (tester) async {
    usePhoneFrame(tester);
    await tester.pumpWidget(app.wrapRouted(const GoalsScreen()));
    await settle(tester);
    expect(find.text('0 of 2 today'), findsOneWidget);

    // What the reader and the player both do when a bani finishes.
    await app.container.read(userRepositoryProvider).creditGoalsFor('JAPJ');
    await settle(tester);

    expect(find.text('0 of 2 today'), findsNothing,
        reason: 'the count did not move when the goal was credited');
    expect(find.text('1 of 2 today'), findsOneWidget);
  });
}
