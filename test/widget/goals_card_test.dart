import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/db/user_db.dart';
import 'package:hazri/core/db/user_repository.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';
import 'package:hazri/features/today/ui/today_screen.dart';

import '../app_harness.dart';

/// Today's goal widget (04-goals §7.1): the Set Goal card until an item is in
/// scope, then a header with `itemsMet` of `itemsInScope` and one row per
/// item.
void main() {
  late TestApp app;

  setUp(() async {
    app = await TestApp.create(
      prefs: {'onboarding_done': true},
      now: DateTime(2026, 9, 14, 9, 30),
    );
  });

  tearDown(() => app.dispose());

  UserRepository repo() => app.container.read(userRepositoryProvider);

  Future<L> pump(WidgetTester tester) async {
    usePhoneFrame(tester);
    await tester.pumpWidget(app.wrapRouted(const TodayScreen()));
    await settle(tester);
    return L.delegate.load(const Locale('en'));
  }

  testWidgets('no goal ever: the Set Goal card, first-time subtitle', (tester) async {
    final l = await pump(tester);
    expect(find.text(l.goalSetCardTitle), findsOneWidget);
    expect(find.text(l.goalSetCardSubtitleFirst), findsOneWidget);
    expect(find.text(l.goalWidgetTitle.toUpperCase()), findsNothing);
  });

  testWidgets('an item in scope: the widget with the item and "0 of 1"', (tester) async {
    await repo().addItem(const GoalItemSpec.bani('JAPJ'));
    final l = await pump(tester);
    expect(find.text(l.goalWidgetTitle.toUpperCase()), findsOneWidget);
    expect(find.text(l.goalWidgetProgress(0, 1)), findsOneWidget);
    expect(find.text('Japji Sahib'), findsOneWidget);
    expect(find.textContaining('${l.goalTimesOfTarget(0, 1)} ·'), findsOneWidget);
  });

  testWidgets('a completion moves the header (one rule: verdictOn)', (tester) async {
    await repo().addItem(const GoalItemSpec.bani('JAPJ'));
    await repo().addItem(const GoalItemSpec.bani('SOHL', timesPerDay: 2));
    await repo().logCompletion(baniId: 'JAPJ', slot: BaniSlotValue.morning, source: CompletionSource.reader);
    final l = await pump(tester);
    expect(find.text(l.goalWidgetProgress(1, 2)), findsOneWidget);
    expect(find.textContaining('${l.goalTimesOfTarget(0, 2)} ·'), findsOneWidget);
  });

  testWidgets('Naam Simran is named, in minutes', (tester) async {
    await repo().addItem(const GoalItemSpec.simran(11));
    final l = await pump(tester);
    expect(find.text(l.goalNaamSimran), findsOneWidget);
    // RM1: every item has a reminder, so its time follows the amount.
    expect(find.textContaining(l.goalSimranMinutes(0)), findsOneWidget);
  });

  testWidgets('after the last item is removed: the card says set a new one (GL1)', (tester) async {
    final item = await repo().addItem(const GoalItemSpec.bani('JAPJ'));
    await repo().removeItem(item.id);
    final l = await pump(tester);
    expect(find.text(l.goalSetCardSubtitleAgain), findsOneWidget);
  });
}
