import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show QueryRow, Variable;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/backend/api_client.dart';
import '../../../core/backend/api_exception.dart';
import '../../../core/db/content_db.dart';
import '../../../core/db/content_repository.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/time/clock.dart';
import '../../profile/data/profile_controller.dart';
import '../domain/quiz.dart';

/// The quiz as `content.db` holds it (ARCHITECTURE §3.2): topics, questions
/// and the calendar events that have a quiz. Read with raw queries, so drift
/// declares no table for them; a database from before the quiz answers with
/// nothing.
class QuizRepository {
  QuizRepository(this._db);

  final ContentDb _db;
  List<QuizTopic>? _topics;
  List<QuizQuestion>? _questions;
  List<QuizDay>? _days;

  Future<List<QuizTopic>> topics() async => _topics ??= await _read(
    'SELECT id, category, sort, name_en, name_pa, name_hi, glyph, slug FROM quiz_topic ORDER BY sort',
    (r) => QuizTopic(
      id: r.read<String>('id'),
      category: QuizCategory.parse(r.read<String>('category')) ?? QuizCategory.culture,
      sort: r.read<int>('sort'),
      nameEn: r.read<String>('name_en'),
      namePa: r.read<String>('name_pa'),
      nameHi: r.read<String>('name_hi'),
      glyph: r.read<String>('glyph'),
      slug: r.readNullable<String>('slug'),
    ),
  );

  Future<List<QuizQuestion>> questions() async => _questions ??= await _read(
    'SELECT * FROM quiz_question ORDER BY CAST(SUBSTR(id, 2) AS INTEGER)',
    (r) => QuizQuestion(
      id: r.read<String>('id'),
      topicId: r.read<String>('topic_id'),
      difficulty: Difficulty.parse(r.read<String>('difficulty')),
      question: r.read<String>('question'),
      options: [r.read<String>('option_a'), r.read<String>('option_b'), r.read<String>('option_c'), r.read<String>('option_d')],
      answer: r.read<String>('answer'),
      explanation: r.read<String>('explanation'),
      hasNote: r.read<int>('has_note') == 1,
      retired: r.read<int>('retired') == 1,
      since: r.read<int>('since'),
    ),
  );

  Future<List<QuizQuestion>> questionsOf(String topicId) async =>
      [for (final q in await questions()) if (q.topicId == topicId) q];

  Future<List<QuizDay>> days() async => _days ??= await _read(
    'SELECT event_name, label_en, label_pa, label_hi, topic_id, slug FROM quiz_day',
    (r) => QuizDay(
      eventName: r.read<String>('event_name'),
      labelEn: r.read<String>('label_en'),
      labelPa: r.read<String>('label_pa'),
      labelHi: r.read<String>('label_hi'),
      topicId: r.read<String>('topic_id'),
      slug: r.readNullable<String>('slug'),
    ),
  );

  /// The calendar's events on a date, in the calendar's order.
  Future<List<String>> eventsOn(DateTime date) async => _read(
    'SELECT name_en FROM calendar_event WHERE date = ? ORDER BY rowid',
    (r) => r.read<String>('name_en'),
    [_dayKey(date)],
  );

  /// QZ8-QZ11 for a date.
  Future<TodayQuiz?> quizFor(DateTime date) async => quizOfTheDay(
    date: date,
    topics: await topics(),
    questions: await questions(),
    days: await days(),
    eventsOnDate: await eventsOn(date),
  );

  /// The next dates after [from], up to [within] days on, whose events have a
  /// quiz, one per date (QZ33 "Coming up on the calendar").
  Future<List<TodayQuiz>> comingUp(DateTime from, {int within = 30, int count = 2}) async {
    final out = <TodayQuiz>[];
    for (var i = 1; i <= within && out.length < count; i++) {
      final date = DateTime(from.year, from.month, from.day + i);
      final q = await quizFor(date);
      if (q?.day != null) out.add(q!);
    }
    return out;
  }

  Future<List<T>> _read<T>(String sql, T Function(QueryRow r) map, [List<Object?> args = const []]) async {
    try {
      final rows = await _db.customSelect(sql, variables: [for (final a in args) Variable(a)]).get();
      return [for (final r in rows) map(r)];
    } on Object catch (e) {
      debugPrint('Hazri: no quiz in content.db ($e)');
      return const [];
    }
  }
}

String _dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

final quizRepositoryProvider = Provider<QuizRepository>(
  (ref) => QuizRepository(ref.watch(contentDbProvider)),
);

final quizTopicsProvider = FutureProvider<List<QuizTopic>>((ref) => ref.watch(quizRepositoryProvider).topics());

final todayQuizProvider = FutureProvider<TodayQuiz?>((ref) {
  final today = ref.watch(clockProvider).today();
  return ref.watch(quizRepositoryProvider).quizFor(today);
});

final comingUpQuizProvider = FutureProvider<List<TodayQuiz>>((ref) {
  final today = ref.watch(clockProvider).today();
  return ref.watch(quizRepositoryProvider).comingUp(today);
});

// --- The server (ARCHITECTURE §6.7) -----------------------------------------

class QuizSessionStart {
  const QuizSessionStart(this.sessionId, this.questionIds);
  final String sessionId;
  final List<String> questionIds;
}

class QuizSubmitResult {
  const QuizSubmitResult({required this.correct, required this.points, required this.totalPoints, this.placeToday});
  final List<bool> correct;
  final int points;
  final int totalPoints;
  final int? placeToday;
}

class QuizBoardRow {
  const QuizBoardRow({required this.place, required this.name, this.cityId, required this.score, this.you = false});
  final int place;
  final String name;
  final String? cityId;
  final int score;
  final bool you;

  factory QuizBoardRow.fromJson(Map<String, Object?> j) => QuizBoardRow(
    place: (j['place'] as num).toInt(),
    name: (j['name'] as String?) ?? '',
    cityId: j['cityId'] as String?,
    score: (j['score'] as num).toInt(),
    you: j['you'] == true,
  );
}

class QuizBoard {
  const QuizBoard({required this.played, required this.rows, this.myScore, this.myPlace});
  final int played;
  final List<QuizBoardRow> rows;
  final int? myScore;
  final int? myPlace;

  factory QuizBoard.fromJson(Map<String, Object?> j) {
    final me = j['me'];
    return QuizBoard(
      played: (j['played'] as num?)?.toInt() ?? 0,
      rows: [
        for (final r in (j['rows'] as List? ?? const []))
          if (r is Map<String, Object?>) QuizBoardRow.fromJson(r),
      ],
      myScore: me is Map<String, Object?> ? (me['score'] as num?)?.toInt() : null,
      myPlace: me is Map<String, Object?> ? (me['place'] as num?)?.toInt() : null,
    );
  }
}

/// What the board screen shows: the board, and whether it is the last copy
/// kept because a fresh one could not be fetched (QZ30).
class QuizBoardView {
  const QuizBoardView(this.board, {this.stale = false});
  final QuizBoard? board;
  final bool stale;
}

class QuizMe {
  const QuizMe({this.points = 0, this.attempts = 0, this.topics = const {}, this.days = const {}, this.places = const {}});
  final int points;
  final int attempts;
  final Map<String, int> topics;
  final Map<String, int> days;

  /// `day`, `week`, `month` on the Everyone boards.
  final Map<String, int?> places;

  factory QuizMe.fromJson(Map<String, Object?> j) {
    Map<String, int> ints(Object? m) => {
      if (m is Map) for (final e in m.entries) '${e.key}': (e.value as num).toInt(),
    };
    final places = j['places'];
    return QuizMe(
      points: (j['points'] as num?)?.toInt() ?? 0,
      attempts: (j['attempts'] as num?)?.toInt() ?? 0,
      topics: ints(j['topics']),
      days: ints(j['days']),
      places: {
        if (places is Map) for (final e in places.entries) '${e.key}': (e.value as num?)?.toInt(),
      },
    );
  }
}

enum QuizPeriod { day, week, month }

/// Calls to `/api/v1/quiz`, and the last answers kept on the phone so the
/// quiz page, Your numbers and a board open offline (ARCHITECTURE §3.9.4).
class QuizApi {
  QuizApi(this._api, this._prefs);

  final ApiClient _api;
  final SharedPreferences _prefs;

  static const meKey = 'quiz_me_v1';
  static const boardsKey = 'quiz_boards_v1';

  /// QZ14: five questions drawn by the server; the content version tells it
  /// which questions this phone has.
  Future<QuizSessionStart> start(String topicId) async {
    final body = await _api.post('/quiz/sessions', {'topicId': topicId, 'bankVersion': ContentDb.expectedVersion});
    return QuizSessionStart(
      body['sessionId']! as String,
      [for (final id in body['questionIds']! as List) id as String],
    );
  }

  Future<QuizSubmitResult> submit(String sessionId, List<String> choices) async {
    final body = await _api.post('/quiz/sessions/$sessionId/answers', {'choices': choices});
    return QuizSubmitResult(
      correct: [for (final c in body['correct']! as List) c == true],
      points: (body['points']! as num).toInt(),
      totalPoints: (body['totalPoints']! as num).toInt(),
      placeToday: (body['placeToday'] as num?)?.toInt(),
    );
  }

  QuizBoard? savedBoard(QuizPeriod period, String scope) {
    final all = _readMap(boardsKey);
    final b = all['${period.name}:$scope'];
    return b is Map<String, Object?> ? QuizBoard.fromJson(b) : null;
  }

  Future<QuizBoard> board(QuizPeriod period, String scope) async {
    final body = await _api.get('/quiz/board', query: {'period': period.name, 'scope': scope});
    final all = _readMap(boardsKey)..['${period.name}:$scope'] = body;
    await _prefs.setString(boardsKey, jsonEncode(all));
    return QuizBoard.fromJson(body);
  }

  QuizMe? savedMe() {
    final raw = _prefs.getString(meKey);
    if (raw == null) return null;
    try {
      return QuizMe.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } on Object {
      return null;
    }
  }

  Future<QuizMe> me() async {
    final body = await _api.get('/quiz/me');
    await _prefs.setString(meKey, jsonEncode(body));
    return QuizMe.fromJson(body);
  }

  /// A profile gone (or a different one restored) takes its numbers with it.
  Future<void> forget() async {
    await _prefs.remove(meKey);
    await _prefs.remove(boardsKey);
  }

  Map<String, Object?> _readMap(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return {};
    try {
      return Map<String, Object?>.from(jsonDecode(raw) as Map);
    } on Object {
      return {};
    }
  }
}

final quizApiProvider = Provider<QuizApi>(
  (ref) => QuizApi(ref.watch(apiClientProvider), ref.watch(sharedPreferencesProvider)),
);

/// Whether the quiz may talk to the server at all: only with a profile
/// (QZ14, QZ31). Without one nothing is sent.
final quizOnlineProvider = Provider<bool>((ref) => ref.watch(profileControllerProvider) is ProfileLoaded);

/// The player's own numbers (QZ34, QZ35): the last copy at once, a fresh one
/// behind it. Null without a profile.
class QuizMeController extends Notifier<QuizMe?> {
  @override
  QuizMe? build() {
    if (!ref.watch(quizOnlineProvider)) return null;
    scheduleMicrotask(refresh);
    return ref.read(quizApiProvider).savedMe() ?? const QuizMe();
  }

  Future<void> refresh() async {
    if (!ref.read(quizOnlineProvider)) return;
    try {
      state = await ref.read(quizApiProvider).me();
    } on ApiException catch (e) {
      debugPrint('Hazri: quiz numbers ($e)');
    } on NetworkException catch (e) {
      debugPrint('Hazri: quiz numbers offline ($e)');
    }
  }
}

final quizMeProvider = NotifierProvider<QuizMeController, QuizMe?>(QuizMeController.new);

/// One board (QZ28-QZ30). A board can be read without a profile; a failed
/// fetch shows the last copy, marked stale.
final quizBoardProvider = FutureProvider.autoDispose.family<QuizBoardView, (QuizPeriod, String)>((ref, key) async {
  final api = ref.watch(quizApiProvider);
  final saved = api.savedBoard(key.$1, key.$2);
  try {
    return QuizBoardView(await api.board(key.$1, key.$2));
  } on Object catch (e) {
    debugPrint('Hazri: quiz board ($e)');
    return QuizBoardView(saved, stale: saved != null);
  }
});

/// The question ids of the last two quizzes per topic on this phone, so a
/// quiz drawn on the phone avoids them (QZ14). Kept for the app's run only.
final quizRecentProvider = Provider<Map<String, List<String>>>((ref) => {});
