import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/db/content_repository.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/time/date_format.dart';
import '../../../core/widgets/surfaces.dart';
import '../data/quiz_repository.dart';
import '../domain/quiz.dart';

/// Design 1A on Today (14-quiz.md QZ9-QZ12): a calendar leaf with the date,
/// then the day's event (or "Did you know?"), the topic, one explanation from
/// the bank word for word, Know more and Take the quiz.
class QuizTodayCard extends ConsumerWidget {
  const QuizTodayCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quiz = ref.watch(todayQuizProvider).value;
    if (quiz == null) return const SizedBox.shrink();
    final c = context.colors;
    final language = Localizations.localeOf(context).languageCode;
    final dates = HazriDates.of(context);
    final ns = ref.watch(nanakshahiCalendarProvider).value?.dateFor(quiz.date);
    const leafInk = Color(0xFF1C1206);
    final leafSmall = HazriText.captionStrong.copyWith(color: leafInk, fontSize: 11, letterSpacing: 1.1);

    // Only the buttons act: a tap on the words is reading, not starting
    // (owner, 2026-10-27).
    return HazriCard(
      padding: EdgeInsets.zero,
      // The leaf fills the card's left edge whatever height the words take;
      // a Stack rather than IntrinsicHeight, because the buttons measure the
      // width they are given (_Buttons) and intrinsics cannot.
      child: Stack(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: _leafMinHeight),
            child: Padding(
              padding: const EdgeInsets.only(left: _leafWidth),
              child: _Words(quiz: quiz),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: _leafWidth,
            child: Container(
              color: c.kesri,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(dates.weekdayAbbr(quiz.date).toUpperCase(), style: leafSmall),
                  Text(
                    '${quiz.date.day}',
                    style: HazriText.display34.copyWith(color: leafInk, fontSize: 36, height: 1.05),
                  ),
                  Text(dates.monthAbbrUpper(quiz.date), style: leafSmall),
                  if (ns != null) ...[
                    Container(
                      width: 40,
                      height: 1,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      color: leafInk.withValues(alpha: 0.3),
                    ),
                    Text('${ns.day}', style: HazriText.captionStrong.copyWith(color: leafInk, fontSize: 12)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        ns.monthName(language),
                        textAlign: TextAlign.center,
                        style: HazriText.captionStrong.copyWith(color: leafInk, fontSize: 10.5),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const double _leafWidth = 78;
const double _leafMinHeight = 172;

class _Words extends StatelessWidget {
  const _Words({required this.quiz});

  final TodayQuiz quiz;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    final language = Localizations.localeOf(context).languageCode;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (quiz.day?.label(language) ?? l.quizDidYouKnow).toUpperCase(),
            style: HazriText.eyebrow.copyWith(color: c.kesriInk),
          ),
          const SizedBox(height: 4),
          Text(
            quiz.topic.name(language),
            style: HazriText.display22.copyWith(color: c.ink, fontSize: 20, height: 1.15),
          ),
          if (quiz.insight != null) ...[
            const SizedBox(height: 6),
            // QZ10: word for word from the bank, which is English (QZ6).
            Text(quiz.insight!.explanation, style: HazriText.bodySmall.copyWith(color: c.ink2, height: 1.4)),
          ],
          const SizedBox(height: 10),
          _Buttons(
            knowMore: quiz.slug == null
                ? null
                : PrimaryButton(
                    label: l.quizKnowMore,
                    secondary: true,
                    minHeight: 44,
                    onPressed: () => context.push(Routes.libraryEntry(quiz.slug!)),
                  ),
            takeQuiz: PrimaryButton(
              label: l.quizTakeQuiz,
              minHeight: 44,
              onPressed: () => context.push(Routes.quizPlay(quiz.topic.id)),
            ),
            labels: [if (quiz.slug != null) l.quizKnowMore, l.quizTakeQuiz],
          ),
        ],
      ),
    );
  }
}

/// Know more and Take the quiz side by side when both labels fit whole, as
/// design 1A draws them; stacked, Take the quiz first, when they do not. A
/// narrow phone, a long translation or a large font must never squeeze a
/// label to nothing.
class _Buttons extends StatelessWidget {
  const _Buttons({required this.knowMore, required this.takeQuiz, required this.labels});

  final Widget? knowMore;
  final Widget takeQuiz;
  final List<String> labels;

  /// PrimaryButton's padding either side of its label.
  static const _padding = 2 * 18.0;
  static const _gap = 10.0;

  @override
  Widget build(BuildContext context) {
    if (knowMore == null) return takeQuiz;
    final scaler = MediaQuery.textScalerOf(context);
    final widths = [
      for (final label in labels)
        (TextPainter(
              text: TextSpan(text: label, style: HazriText.button),
              textDirection: TextDirection.ltr,
              textScaler: scaler,
              maxLines: 1,
            )..layout()).width +
            _padding,
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final need = widths.fold(0.0, (a, b) => a + b) + _gap;
        if (need <= constraints.maxWidth) {
          return Row(
            children: [
              Expanded(flex: widths[0].ceil(), child: knowMore!),
              const SizedBox(width: _gap),
              Expanded(flex: widths[1].ceil(), child: takeQuiz),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [takeQuiz, const SizedBox(height: 8), knowMore!],
        );
      },
    );
  }
}
