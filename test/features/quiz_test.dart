import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/features/profile/data/incoming_link.dart';
import 'package:hazri/features/quiz/data/quiz_repository.dart';
import 'package:hazri/features/quiz/domain/quiz.dart';

import '../app_harness.dart';

/// 14-quiz.md QZ8-QZ11 and QZ13 against the content.db the app ships, and
/// QZ25's link.
void main() {
  late TestApp app;
  late QuizRepository repo;

  setUp(() async {
    app = await TestApp.create();
    repo = app.container.read(quizRepositoryProvider);
  });
  tearDown(() => app.dispose());

  test('the bank ships seventeen topics of twenty questions in five categories', () async {
    final topics = await repo.topics();
    expect(topics, hasLength(17));
    expect(topics.map((t) => t.category).toSet(), QuizCategory.values.toSet());
    for (final t in topics) {
      expect(await repo.questionsOf(t.id), hasLength(20), reason: t.id);
    }
  });

  test('a Gurpurab picks its Guru: 27 October 2026 is Guru Ram Das Ji (QZ8, QZ11)', () async {
    final q = (await repo.quizFor(DateTime(2026, 10, 27)))!;
    expect(q.topic.id, 'guru-ram-das-ji');
    expect(q.day!.labelEn, 'Prakash Purab');
    expect(q.slug, 'prakash-purab-guru-ram-das-ji');
  });

  test('the insight is an easy question of the topic with no note, word for word (QZ10)', () async {
    final q = (await repo.quizFor(DateTime(2026, 10, 27)))!;
    final all = await repo.questionsOf('guru-ram-das-ji');
    final insight = q.insight!;
    expect(insight.topicId, 'guru-ram-das-ji');
    expect(insight.difficulty, Difficulty.easy);
    expect(insight.hasNote, isFalse);
    expect(all.map((x) => x.explanation), contains(insight.explanation));
  });

  test('two events: a Guru\'s comes first (14 December 2026)', () async {
    final q = (await repo.quizFor(DateTime(2026, 12, 14)))!;
    expect(q.topic.id, 'guru-tegh-bahadur-ji');
    expect(q.day!.labelEn, 'Shaheedi Purab');
  });

  test('a day with no event takes the rotation, the same for every phone, and Know more goes to the topic page',
      () async {
    final date = DateTime(2026, 10, 29); // no mapped event
    expect((await repo.eventsOn(date)).where((e) => e.contains('Purab')), isEmpty);
    final a = (await repo.quizFor(date))!;
    final b = (await repo.quizFor(date))!;
    expect(a.day, isNull);
    expect(a.topic.id, b.topic.id);
    final topics = await repo.topics();
    expect(a.topic.id, topics[daysSinceEpoch(date) % topics.length].id);
    expect(a.slug, a.topic.slug);
  });

  test('coming up lists the next mapped dates after today (QZ33)', () async {
    final next = await repo.comingUp(DateTime(2026, 10, 27));
    expect(next, hasLength(2));
    expect(next.first.date, DateTime(2026, 11, 3)); // 1 November's event has no quiz
    expect(next.every((q) => q.day != null), isTrue);
  });

  test('the phone\'s draw: two easy, two medium, one hard, avoiding the last quiz (QZ13, QZ14)', () async {
    final all = await repo.questionsOf('guru-nanak-dev-ji');
    final first = drawQuestions(all, random: Random(1));
    expect(first.map((q) => q.difficulty), [Difficulty.easy, Difficulty.easy, Difficulty.medium, Difficulty.medium, Difficulty.hard]);
    final second = drawQuestions(all, recent: first.map((q) => q.id).toSet(), random: Random(2));
    expect(second.where(first.contains), isEmpty);
  });

  test('initials for a board row', () {
    expect(initialsOf('Manpreet S.'), 'MS');
    expect(initialsOf('Harpreet'), 'H');
    expect(initialsOf('ਹਰਪ੍ਰੀਤ ਕ.'), 'ਹਕ');
  });

  test('a shared quiz link opens that quiz (QZ25)', () {
    expect(incomingLinkRoute(Uri.parse('https://hazri-dfcc1.web.app/q/guru-ram-das-ji')), '/quiz/play/guru-ram-das-ji');
    expect(incomingLinkRoute(Uri.parse('/q/five-takhts')), '/quiz/play/five-takhts');
    expect(incomingLinkRoute(Uri.parse('https://hazri-dfcc1.web.app/q/../../etc')), '/today');
  });
}
