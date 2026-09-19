import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/features/hazri/domain/hazri.dart';

/// Hazri is being present. It is not the goal, and the difference is the
/// whole reason this type exists.
void main() {
  final morning = DateTime(2026, 11, 20, 5, 52);
  final evening = DateTime(2026, 11, 20, 18, 44);

  test('a day with nothing on it is not marked, and is not a failure', () {
    final hazri = Hazri.from(completions: const [], completedSimran: const []);
    expect(hazri.isMarked, isFalse);
    expect(hazri, Hazri.none);
  });

  test('one paath marks the day', () {
    final hazri = Hazri.from(
      completions: [(at: morning, baniId: 'japji')],
      completedSimran: const [],
    );
    expect(hazri.isMarked, isTrue);
    expect(hazri.baniId, 'japji');
    expect(hazri.bySimran, isFalse);
  });

  test('one sitting of simran marks it just as well', () {
    final hazri = Hazri.from(completions: const [], completedSimran: [morning]);
    expect(hazri.isMarked, isTrue);
    expect(hazri.bySimran, isTrue);
    expect(hazri.baniId, isNull);
  });

  test('it is the first thing of the day, not the last', () {
    // Five banis read; the banner still says 5:52, because that is when
    // somebody turned up.
    final hazri = Hazri.from(
      completions: [
        (at: evening, baniId: 'rehras'),
        (at: morning, baniId: 'japji'),
      ],
      completedSimran: const [],
    );
    expect(hazri.markedAt, morning);
    expect(hazri.baniId, 'japji');
  });

  test('simran before the first paath is what marked it', () {
    final hazri = Hazri.from(
      completions: [(at: evening, baniId: 'rehras')],
      completedSimran: [morning],
    );
    expect(hazri.markedAt, morning);
    expect(hazri.bySimran, isTrue);
  });

  test('a paath before the simran is what marked it', () {
    final hazri = Hazri.from(
      completions: [(at: morning, baniId: 'japji')],
      completedSimran: [evening],
    );
    expect(hazri.markedAt, morning);
    expect(hazri.bySimran, isFalse);
    expect(hazri.baniId, 'japji');
  });
}
