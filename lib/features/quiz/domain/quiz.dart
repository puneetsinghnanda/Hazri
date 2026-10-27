import 'dart:math';

/// The Gurmat Quiz (`docs/features/14-quiz.md`). Every question, topic name
/// and event label comes from `content.db` (QZ4); nothing here is typed in.

enum QuizCategory {
  gurus,
  gurdwaras,
  banis,
  heroes,
  culture;

  static QuizCategory? parse(String s) => values.where((c) => c.name == s).firstOrNull;
}

class QuizTopic {
  const QuizTopic({
    required this.id,
    required this.category,
    required this.sort,
    required this.nameEn,
    required this.namePa,
    required this.nameHi,
    required this.glyph,
    this.slug,
  });

  final String id;
  final QuizCategory category;
  final int sort;
  final String nameEn;
  final String namePa;
  final String nameHi;

  /// A Gurmukhi numeral for a Guru, ੴ for Sri Guru Granth Sahib Ji, or the
  /// name of the category's drawing (`gurdwaras`, `banis`, ...).
  final String glyph;

  /// The Vichar page Know more opens on a day with no event (QZ11).
  final String? slug;

  String name(String language) => switch (language) {
    'pa' => namePa,
    'hi' => nameHi,
    _ => nameEn,
  };

  /// Whether [glyph] is a drawing rather than text.
  bool get drawn => QuizCategory.parse(glyph) != null;
}

enum Difficulty {
  easy,
  medium,
  hard;

  static Difficulty parse(String s) => values.firstWhere((d) => d.name == s, orElse: () => medium);
}

class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.topicId,
    required this.difficulty,
    required this.question,
    required this.options,
    required this.answer,
    required this.explanation,
    this.hasNote = false,
    this.retired = false,
    this.since = 10,
  });

  final String id;
  final String topicId;
  final Difficulty difficulty;
  final String question;

  /// Four options, in the bank's order (QZ15).
  final List<String> options;

  /// `A` to `D`.
  final String answer;
  final String explanation;
  final bool hasNote;
  final bool retired;
  final int since;

  int get answerIndex => 'ABCD'.indexOf(answer);

  static String letter(int index) => 'ABCD'[index];
}

/// A calendar event that has a quiz (`days.json`).
class QuizDay {
  const QuizDay({
    required this.eventName,
    required this.labelEn,
    required this.labelPa,
    required this.labelHi,
    required this.topicId,
    this.slug,
  });

  final String eventName;
  final String labelEn;
  final String labelPa;
  final String labelHi;
  final String topicId;
  final String? slug;

  String label(String language) => switch (language) {
    'pa' => labelPa,
    'hi' => labelHi,
    _ => labelEn,
  };
}

/// Today's quiz (QZ8-QZ11): the topic, the event that chose it (or none),
/// the insight and where Know more goes.
class TodayQuiz {
  const TodayQuiz({required this.date, required this.topic, this.day, this.insight, this.slug});

  final DateTime date;
  final QuizTopic topic;

  /// The event that chose the topic; null on a day with none.
  final QuizDay? day;

  /// One question whose explanation is shown word for word (QZ10).
  final QuizQuestion? insight;

  /// The Vichar page Know more opens, or null to hide it (QZ11).
  final String? slug;
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Days since 1970-01-01 of a local date, as ਅੱਜ ਦਾ ਵਿਚਾਰ counts them.
int daysSinceEpoch(DateTime date) =>
    DateTime.utc(date.year, date.month, date.day).difference(DateTime.utc(1970)).inDays;

/// QZ8: one topic a day, the same for everybody on that date.
///
/// 1. the date's calendar events that `days` maps to a topic, those mapped to
///    a Gurus topic first, then the calendar's order;
/// 2. otherwise the topics in their order, by days since 1970 modulo their
///    number.
///
/// QZ10: the insight is the explanation of one of the topic's easy questions
/// with no reviewer's note, chosen by the date. QZ11: Know more goes to the
/// event's page, else the topic's.
TodayQuiz? quizOfTheDay({
  required DateTime date,
  required List<QuizTopic> topics,
  required List<QuizQuestion> questions,
  required List<QuizDay> days,
  required List<String> eventsOnDate,
}) {
  if (topics.isEmpty) return null;
  final byId = {for (final t in topics) t.id: t};
  final dayByEvent = {for (final d in days) d.eventName: d};
  final mapped = [
    for (final e in eventsOnDate)
      if (dayByEvent[e] case final QuizDay d when byId.containsKey(d.topicId)) d,
  ];
  final gurus = mapped.where((d) => byId[d.topicId]!.category == QuizCategory.gurus);
  final day = gurus.isNotEmpty ? gurus.first : mapped.firstOrNull;
  final n = daysSinceEpoch(date);
  final ordered = [...topics]..sort((a, b) => a.sort.compareTo(b.sort));
  final topic = day != null ? byId[day.topicId]! : ordered[n % ordered.length];

  final candidates = [
    for (final q in questions)
      if (q.topicId == topic.id && q.difficulty == Difficulty.easy && !q.hasNote && !q.retired) q,
  ]..sort((a, b) => _idNumber(a.id).compareTo(_idNumber(b.id)));
  final insight = candidates.isEmpty ? null : candidates[n % candidates.length];
  return TodayQuiz(
    date: _dateOnly(date),
    topic: topic,
    day: day,
    insight: insight,
    slug: day != null ? day.slug : topic.slug,
  );
}

int _idNumber(String id) => int.tryParse(id.replaceAll(RegExp(r'\D'), '')) ?? 0;

const _slots = [Difficulty.easy, Difficulty.easy, Difficulty.medium, Difficulty.medium, Difficulty.hard];
const _fallback = {
  Difficulty.easy: [Difficulty.easy, Difficulty.medium, Difficulty.hard],
  Difficulty.medium: [Difficulty.medium, Difficulty.hard, Difficulty.easy],
  Difficulty.hard: [Difficulty.hard, Difficulty.medium, Difficulty.easy],
};

/// QZ13 on the phone, for a quiz without a profile or a connection (QZ14,
/// QZ16): two easy, two medium and one hard, a short difficulty filled from
/// the next harder then the next easier, a recent question of the right
/// difficulty taken before a fresh one of another. The server's draw is the
/// same rule (`functions/src/quiz/bank.ts`).
List<QuizQuestion> drawQuestions(List<QuizQuestion> topicQuestions, {Set<String> recent = const {}, Random? random}) {
  final rng = random ?? Random();
  final live = topicQuestions.where((q) => !q.retired).toList();
  final used = <String>{};
  final out = <QuizQuestion>[];
  for (final slot in _slots) {
    QuizQuestion? picked;
    search:
    for (final want in _fallback[slot]!) {
      for (final allowRecent in const [false, true]) {
        final pool = [
          for (final q in live)
            if (q.difficulty == want && !used.contains(q.id) && (allowRecent || !recent.contains(q.id))) q,
        ];
        if (pool.isNotEmpty) {
          picked = pool[rng.nextInt(pool.length)];
          break search;
        }
      }
    }
    if (picked == null) break;
    used.add(picked.id);
    out.add(picked);
  }
  return out.length == 5 ? out : const [];
}

/// "Harpreet Kaur" -> "HK", for the avatar on a board row (QZ28).
String initialsOf(String name) {
  final words = name.replaceAll('.', ' ').trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return '';
  String first(String w) => String.fromCharCode(w.runes.first);
  return (first(words.first) + (words.length > 1 ? first(words.last) : '')).toUpperCase();
}
