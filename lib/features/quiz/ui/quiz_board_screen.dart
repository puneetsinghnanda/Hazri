import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/widgets/surfaces.dart';
import '../../settings/ui/screen_scaffold.dart';
import '../data/quiz_repository.dart';
import '../domain/quiz.dart';
import 'quiz_widgets.dart';

/// Designs 5A and 5B (14-quiz.md QZ27-QZ30): the top twenty for a quiz or
/// for everyone, today, this week or this month; the player's own row marked
/// and, when outside the twenty, shown below it. Without a profile the board
/// is the same with the Make a profile card above it.
class QuizBoardScreen extends ConsumerStatefulWidget {
  const QuizBoardScreen({super.key, this.scope});

  /// A topic id, or null for Everyone.
  final String? scope;

  @override
  ConsumerState<QuizBoardScreen> createState() => _QuizBoardScreenState();
}

class _QuizBoardScreenState extends ConsumerState<QuizBoardScreen> {
  QuizPeriod _period = QuizPeriod.day;
  late String _scope = widget.scope ?? 'all';

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final online = ref.watch(quizOnlineProvider);
    final topics = ref.watch(quizTopicsProvider).value ?? const <QuizTopic>[];
    final today = ref.watch(todayQuizProvider).value?.topic.id;
    // Everyone, then today's topic, then the chosen one, then the rest (QZ28).
    final order = <String>{'all', ?today, _scope, for (final t in topics) t.id}.toList();
    final view = ref.watch(quizBoardProvider((_period, _scope)));

    Widget chip(String label, bool on, VoidCallback onTap) => Padding(
      padding: const EdgeInsets.only(right: 8),
      child: HazriChip(
        label: label,
        background: on ? c.primary : c.card,
        foreground: on ? c.onPrimary : c.ink2,
        minHeight: 40,
        onTap: onTap,
      ),
    );

    return HazriScreen(
      title: l.quizLeaderboardTitle,
      children: [
        const SizedBox(height: 4),
        Row(
          children: [
            for (final (p, label) in [
              (QuizPeriod.day, l.quizPeriodToday),
              (QuizPeriod.week, l.quizPeriodWeek),
              (QuizPeriod.month, l.quizPeriodMonth),
            ])
              chip(label, _period == p, () => setState(() => _period = p)),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final id in order)
                chip(
                  id == 'all' ? l.quizEveryone : (topics.where((t) => t.id == id).firstOrNull?.name(language) ?? id),
                  _scope == id,
                  () => setState(() => _scope = id),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (!online) ...[const QuizProfileCard(), const SizedBox(height: 12)],
        ...switch (view) {
          AsyncData(value: final v) => _rows(context, v),
          AsyncError() => [_note(context, l.quizBoardOffline)],
          _ => [
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        },
      ],
    );
  }

  Widget _note(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 28),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: HazriText.body.copyWith(color: context.colors.muted),
    ),
  );

  List<Widget> _rows(BuildContext context, QuizBoardView view) {
    final c = context.colors;
    final l = L.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final board = view.board;
    if (board == null) return [_note(context, l.quizBoardOffline)];
    if (board.rows.isEmpty) {
      // Today's board starts empty at midnight IST, so an earlier quiz is
      // only on the week's and the month's (QZ28a, owner 2026-10-28).
      final next = switch (_period) {
        QuizPeriod.day => (l.quizBoardEmptyToday, l.quizSeeWeek, QuizPeriod.week),
        QuizPeriod.week => (l.quizBoardEmptyWeek, l.quizSeeMonth, QuizPeriod.month),
        QuizPeriod.month => null,
      };
      if (next == null) return [_note(context, l.quizBoardEmpty)];
      return [
        _note(context, next.$1),
        PrimaryButton(label: next.$2, secondary: true, onPressed: () => setState(() => _period = next.$3)),
      ];
    }
    final mine = board.rows.any((r) => r.you);
    Widget row(QuizBoardRow r) => _BoardRow(
      place: r.place,
      name: r.you ? l.quizYou : r.name,
      initials: initialsOf(r.name),
      city: cityName(ref, r.cityId, language),
      score: r.score,
      you: r.you,
    );
    return [
      if (view.stale)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(l.quizBoardStale, style: HazriText.caption.copyWith(color: c.muted)),
        ),
      HazriCard(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            for (final r in board.rows) row(r),
            if (!mine && board.myPlace != null) ...[
              Divider(height: 1, color: c.rule),
              _BoardRow(
                place: board.myPlace!,
                name: l.quizYou,
                initials: initialsOf(l.quizYou),
                city: '',
                score: board.myScore ?? 0,
                you: true,
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 10),
      Text(
        switch (_period) {
          QuizPeriod.day => l.quizPlayedToday(board.played),
          QuizPeriod.week => l.quizPlayedWeek(board.played),
          QuizPeriod.month => l.quizPlayedMonth(board.played),
        },
        textAlign: TextAlign.center,
        style: HazriText.caption.copyWith(color: c.muted),
      ),
    ];
  }
}

class _BoardRow extends StatelessWidget {
  const _BoardRow({
    required this.place,
    required this.name,
    required this.initials,
    required this.city,
    required this.score,
    this.you = false,
  });

  final int place;
  final String name;
  final String initials;
  final String city;
  final int score;
  final bool you;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      color: you ? c.kesriSoft : null,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text('$place', style: HazriText.bodyStrong.copyWith(color: place <= 3 ? c.kesriInk : c.muted)),
          ),
          QuizAvatar(initials, highlight: you),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: HazriText.bodyStrong.copyWith(color: c.ink),
                ),
                if (city.isNotEmpty) Text(city, style: HazriText.caption.copyWith(color: c.muted)),
              ],
            ),
          ),
          Text('$score', style: HazriText.bodyStrong.copyWith(color: c.ink)),
        ],
      ),
    );
  }
}
