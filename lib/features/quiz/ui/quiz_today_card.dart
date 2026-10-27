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
    final l = L.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final dates = HazriDates.of(context);
    final ns = ref.watch(nanakshahiCalendarProvider).value?.dateFor(quiz.date);
    const leafInk = Color(0xFF1C1206);
    final leafSmall = HazriText.captionStrong.copyWith(color: leafInk, fontSize: 11, letterSpacing: 1.1);

    return HazriCard(
      padding: EdgeInsets.zero,
      onTap: () => context.push(Routes.quizPlay(quiz.topic.id)),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 78,
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
            Expanded(
              child: Padding(
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
                      Text(
                        quiz.insight!.explanation,
                        style: HazriText.bodySmall.copyWith(color: c.ink2, height: 1.4),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (quiz.slug != null) ...[
                          Expanded(
                            child: PrimaryButton(
                              label: l.quizKnowMore,
                              secondary: true,
                              minHeight: 44,
                              onPressed: () => context.push(Routes.libraryEntry(quiz.slug!)),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          flex: 5,
                          child: PrimaryButton(
                            label: l.quizTakeQuiz,
                            minHeight: 44,
                            onPressed: () => context.push(Routes.quizPlay(quiz.topic.id)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
