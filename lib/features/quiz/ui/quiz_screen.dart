import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/backend/api_exception.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/surfaces.dart';
import '../data/quiz_repository.dart';
import '../domain/quiz.dart';
import 'quiz_share.dart';

/// Why a quiz earns no points this time (QZ14, QZ16, QZ22).
enum QuizOffline { none, noProfile, noConnection, dailyLimit }

/// A quiz from its first question to the result (14-quiz.md §5, §7):
/// straight into the questions (QZ12), each marked at once with its
/// explanation (QZ15), then design 4B.
class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key, required this.topicId, this.startTimeout = const Duration(seconds: 5)});

  final String topicId;

  /// QZ16: a session not started within this plays on the phone.
  final Duration startTimeout;

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  QuizTopic? _topic;
  TodayQuiz? _today;
  List<QuizQuestion> _questions = const [];
  String? _sessionId;
  QuizOffline _offline = QuizOffline.none;
  bool _loading = true;
  int _index = 0;
  final _chosen = <int?>[null, null, null, null, null];
  bool _submitting = false;
  bool _done = false;
  QuizSubmitResult? _result;

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  Future<void> _start() async {
    final repo = ref.read(quizRepositoryProvider);
    final topics = await repo.topics();
    final topic = topics.where((t) => t.id == widget.topicId).firstOrNull;
    final all = await repo.questionsOf(widget.topicId);
    final today = await ref.read(todayQuizProvider.future);
    final recent = ref.read(quizRecentProvider);
    var questions = <QuizQuestion>[];
    var offline = QuizOffline.noProfile;

    if (topic != null && ref.read(quizOnlineProvider)) {
      try {
        final s = await ref.read(quizApiProvider).start(widget.topicId).timeout(widget.startTimeout);
        final byId = {for (final q in all) q.id: q};
        final drawn = [for (final id in s.questionIds) ?byId[id]];
        if (drawn.length == 5) {
          questions = drawn;
          _sessionId = s.sessionId;
          offline = QuizOffline.none;
        } else {
          offline = QuizOffline.noConnection;
        }
      } on ApiException catch (e) {
        offline = switch (e.code) {
          'QUIZ_DAILY_LIMIT' => QuizOffline.dailyLimit,
          'NO_PROFILE' => QuizOffline.noProfile,
          _ => QuizOffline.noConnection,
        };
      } on Object {
        // NetworkException, a timeout: QZ16.
        offline = QuizOffline.noConnection;
      }
    }
    if (questions.isEmpty) {
      questions = drawQuestions(all, recent: {...?recent[widget.topicId]});
    }
    recent[widget.topicId] = [
      ...questions.map((q) => q.id),
      ...?recent[widget.topicId],
    ].take(10).toList();
    if (!mounted) return;
    setState(() {
      _topic = topic;
      _today = today;
      _questions = questions;
      _offline = offline;
      _loading = false;
    });
  }

  bool get _revealed => _chosen[_index] != null;

  void _choose(int option) {
    if (_revealed) return;
    setState(() => _chosen[_index] = option);
  }

  Future<void> _next() async {
    if (_index < _questions.length - 1) {
      setState(() => _index++);
      return;
    }
    final sessionId = _sessionId;
    if (sessionId != null) {
      setState(() => _submitting = true);
      try {
        _result = await ref.read(quizApiProvider).submit(sessionId, [for (final c in _chosen) QuizQuestion.letter(c!)]);
        unawaited(ref.read(quizMeProvider.notifier).refresh());
      } on Object {
        _offline = QuizOffline.noConnection;
      }
    }
    if (mounted) {
      setState(() {
        _submitting = false;
        _done = true;
      });
    }
  }

  Future<void> _confirmLeave() async {
    if (_done || _loading || _chosen.every((c) => c == null)) {
      context.pop();
      return;
    }
    final l = L.of(context);
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.quizLeaveTitle),
        content: Text(l.quizLeaveBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l.quizKeepGoing)),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(l.quizLeave)),
        ],
      ),
    );
    if (leave == true && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return PopScope(
      canPop: _done || _loading || _chosen.every((x) => x == null),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_confirmLeave());
      },
      child: Scaffold(
        backgroundColor: c.bg,
        body: SafeArea(
          child: _loading
              ? _Starting()
              : _questions.isEmpty
              ? _Empty(onClose: () => context.pop())
              : _done
              ? _Result(
                  topic: _topic!,
                  today: _today,
                  questions: _questions,
                  chosen: [for (final x in _chosen) x!],
                  result: _result,
                  offline: _offline,
                )
              : _Asking(
                  topic: _topic!,
                  question: _questions[_index],
                  index: _index,
                  chosen: _chosen[_index],
                  submitting: _submitting,
                  onChoose: _choose,
                  onNext: _next,
                  onClose: _confirmLeave,
                ),
        ),
      ),
    );
  }
}

class _Starting extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: c.kesri),
          const SizedBox(height: 14),
          Text(L.of(context).quizStarting, style: HazriText.bodySmall.copyWith(color: c.muted)),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(l.quizEmpty, textAlign: TextAlign.center, style: HazriText.body.copyWith(color: c.muted)),
          const SizedBox(height: 16),
          PrimaryButton(label: l.actionClose, expanded: false, onPressed: onClose),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, this.subtitle, required this.onClose});

  final String title;
  final String? subtitle;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 4),
      child: Row(
        children: [
          IconButton(
            tooltip: L.of(context).actionClose,
            onPressed: onClose,
            icon: AppIcon(HazriIconData.close, size: 22, color: c.ink2),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: HazriText.bodyStrong.copyWith(color: c.ink)),
                if (subtitle != null) Text(subtitle!, style: HazriText.caption.copyWith(color: c.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One question (QZ15): the options in the bank's order; a tap marks it at
/// once, the explanation follows, then Next.
class _Asking extends StatelessWidget {
  const _Asking({
    required this.topic,
    required this.question,
    required this.index,
    required this.chosen,
    required this.submitting,
    required this.onChoose,
    required this.onNext,
    required this.onClose,
  });

  final QuizTopic topic;
  final QuizQuestion question;
  final int index;
  final int? chosen;
  final bool submitting;
  final ValueChanged<int> onChoose;
  final VoidCallback onNext;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final revealed = chosen != null;
    final right = chosen == question.answerIndex;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TopBar(title: topic.name(language), subtitle: l.quizQuestionOf(index + 1, 5), onClose: onClose),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: HazriSize.gutter),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (index + (revealed ? 1 : 0)) / 5,
              minHeight: 6,
              color: c.kesri,
              backgroundColor: c.card2,
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(HazriSize.gutter, 18, HazriSize.gutter, 16),
            children: [
              if (language != 'en' && index == 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(l.quizEnglishOnly, style: HazriText.caption.copyWith(color: c.muted)),
                ),
              Text(question.question, style: HazriText.display22.copyWith(color: c.ink, fontSize: 21, height: 1.3)),
              const SizedBox(height: 18),
              for (var i = 0; i < 4; i++) ...[
                _Option(
                  letter: QuizQuestion.letter(i),
                  text: question.options[i],
                  state: !revealed
                      ? _OptionState.open
                      : i == question.answerIndex
                      ? _OptionState.right
                      : i == chosen
                      ? _OptionState.wrong
                      : _OptionState.faded,
                  onTap: () => onChoose(i),
                ),
                const SizedBox(height: 10),
              ],
              if (revealed) ...[
                const SizedBox(height: 4),
                HazriCard(
                  colour: right ? c.sageSoft : c.card2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        right ? l.quizRight : l.quizWrong,
                        style: HazriText.bodyStrong.copyWith(color: right ? c.sage : c.ink),
                      ),
                      const SizedBox(height: 4),
                      // QZ7: the explanation alone; no source.
                      Text(question.explanation, style: HazriText.bodySmall.copyWith(color: c.ink2, height: 1.45)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(HazriSize.gutter, 4, HazriSize.gutter, 16),
          child: PrimaryButton(
            label: index == 4 ? l.quizSeeResult : l.quizNext,
            onPressed: revealed && !submitting ? onNext : null,
          ),
        ),
      ],
    );
  }
}

enum _OptionState { open, right, wrong, faded }

class _Option extends StatelessWidget {
  const _Option({required this.letter, required this.text, required this.state, required this.onTap});

  final String letter;
  final String text;
  final _OptionState state;
  final VoidCallback onTap;

  static const wrongInk = Color(0xFFB3261E);
  static const wrongSoft = Color(0x1FB3261E);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (bg, border, ink) = switch (state) {
      _OptionState.open => (c.card, c.rule, c.ink),
      _OptionState.right => (c.sageSoft, c.sage, c.ink),
      _OptionState.wrong => (wrongSoft, wrongInk, c.ink),
      _OptionState.faded => (c.card, c.rule, c.muted),
    };
    return Semantics(
      button: state == _OptionState.open,
      selected: state == _OptionState.right || state == _OptionState.wrong,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border, width: state == _OptionState.open || state == _OptionState.faded ? 1 : 2),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: state == _OptionState.open ? onTap : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: switch (state) {
                        _OptionState.right => c.sage,
                        _OptionState.wrong => wrongInk,
                        _ => c.card2,
                      },
                    ),
                    child: switch (state) {
                      _OptionState.right => const Icon(Icons.check_rounded, size: 18, color: Colors.white),
                      _OptionState.wrong => const Icon(Icons.close_rounded, size: 18, color: Colors.white),
                      _ => Text(letter, style: HazriText.captionStrong.copyWith(color: c.ink2)),
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(text, style: HazriText.body.copyWith(color: ink, height: 1.35))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Design 4B (QZ23-QZ26): the score, the five answers, the share card, then
/// the leaderboard as the main button.
class _Result extends ConsumerWidget {
  const _Result({
    required this.topic,
    required this.today,
    required this.questions,
    required this.chosen,
    required this.result,
    required this.offline,
  });

  final QuizTopic topic;
  final TodayQuiz? today;
  final List<QuizQuestion> questions;
  final List<int> chosen;
  final QuizSubmitResult? result;
  final QuizOffline offline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final right = [for (var i = 0; i < questions.length; i++) chosen[i] == questions[i].answerIndex];
    final score = right.where((r) => r).length;
    final eventToday = today?.day != null && today!.topic.id == topic.id && topic.category == QuizCategory.gurus;
    final pointsLine = switch (offline) {
      QuizOffline.none when result != null => l.quizPointsEarned(result!.points),
      QuizOffline.noConnection => l.quizPointsNeedConnection,
      QuizOffline.dailyLimit => l.quizDailyLimit,
      _ => null,
    };
    final place = result?.placeToday;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TopBar(title: l.quizResultTitle, onClose: () => context.pop()),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(HazriSize.gutter, 8, HazriSize.gutter, 20),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$score', style: HazriText.display44.copyWith(color: c.ink, height: 1)),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6, left: 2),
                    child: Text('/5', style: HazriText.display22.copyWith(color: c.muted)),
                  ),
                  const SizedBox(width: 14),
                  if (pointsLine != null)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          pointsLine,
                          style: (offline == QuizOffline.none ? HazriText.bodyStrong : HazriText.bodySmall)
                              .copyWith(color: offline == QuizOffline.none ? c.kesriInk : c.muted),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(topic.name(language), style: HazriText.bodyStrong.copyWith(color: c.ink2)),
              const SizedBox(height: 14),
              HazriCard(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    for (var i = 0; i < questions.length; i++)
                      InkWell(
                        onTap: () => _showAnswer(context, questions[i], chosen[i]),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          child: Row(
                            children: [
                              Icon(
                                right[i] ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                size: 22,
                                color: right[i] ? c.sage : _Option.wrongInk,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  questions[i].question,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: HazriText.bodySmall.copyWith(color: c.ink),
                                ),
                              ),
                              AppIcon(HazriIconData.chevronRight, size: 16, color: c.muted),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (offline == QuizOffline.noProfile) ...[
                const SizedBox(height: 12),
                HazriCard(
                  onTap: () => context.push(Routes.profileSetup),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(l.quizMakeProfileToEarn, style: HazriText.bodySmall.copyWith(color: c.ink)),
                      ),
                      AppIcon(HazriIconData.chevronRight, size: 16, color: c.kesriInk),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              HazriCard(
                colour: c.kesriSoft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.quizShareChallenge(score), style: HazriText.display22.copyWith(color: c.ink, fontSize: 19)),
                    const SizedBox(height: 4),
                    Text(
                      eventToday
                          ? l.quizShareEventLine(topic.name(language), today!.day!.label(language))
                          : l.quizShareLine,
                      style: HazriText.bodySmall.copyWith(color: c.ink2),
                    ),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      label: l.quizShareButton,
                      icon: HazriIconData.share,
                      background: c.kesri,
                      foreground: Colors.white,
                      onPressed: () => showQuizShareSheet(context, topic: topic, score: score, language: language),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(HazriSize.gutter, 4, HazriSize.gutter, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (offline != QuizOffline.noConnection)
                PrimaryButton(
                  label: place != null ? l.quizSeeLeaderboardPlace(place) : l.quizSeeLeaderboard,
                  background: c.primary,
                  foreground: c.onPrimary,
                  onPressed: () => context.pushReplacement(Routes.quizBoard(scope: topic.id)),
                ),
              TextButton(onPressed: () => context.pop(), child: Text(l.actionDone)),
            ],
          ),
        ),
      ],
    );
  }

  void _showAnswer(BuildContext context, QuizQuestion q, int chosen) {
    final c = context.colors;
    final l = L.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: c.card,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(HazriSize.gutter, 0, HazriSize.gutter, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(q.question, style: HazriText.bodyStrong.copyWith(color: c.ink)),
              const SizedBox(height: 12),
              for (var i = 0; i < 4; i++)
                if (i == q.answerIndex || i == chosen)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          i == q.answerIndex ? Icons.check_circle_rounded : Icons.cancel_rounded,
                          size: 20,
                          color: i == q.answerIndex ? c.sage : _Option.wrongInk,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(q.options[i], style: HazriText.body.copyWith(color: c.ink))),
                      ],
                    ),
                  ),
              const SizedBox(height: 6),
              Text(
                chosen == q.answerIndex ? l.quizRight : l.quizWrong,
                style: HazriText.captionStrong.copyWith(color: c.muted),
              ),
              const SizedBox(height: 4),
              Text(q.explanation, style: HazriText.bodySmall.copyWith(color: c.ink2, height: 1.45)),
            ],
          ),
        ),
      ),
    );
  }
}
