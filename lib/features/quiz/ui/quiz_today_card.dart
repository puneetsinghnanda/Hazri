import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/db/content_repository.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/time/date_format.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/surfaces.dart';
import '../data/quiz_repository.dart';
import '../domain/quiz.dart';
import 'quiz_widgets.dart';

/// Design 1A on Today (14-quiz.md QZ9-QZ11): a calendar leaf with the date,
/// then the day's event (or "Did you know?"), the topic and one explanation
/// from the bank word for word. No buttons (owner, 2026-10-28): the quiz has
/// its own card below ([QuizPickCard]). On a day with an event that has a
/// Vichar page, the whole card opens it, with an arrow (Know more, QZ11);
/// on other days it is still.
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
    final slug = quiz.day != null ? quiz.slug : null;

    return Semantics(
      button: slug != null,
      hint: slug != null ? l.quizKnowMore : null,
      child: HazriCard(
        padding: EdgeInsets.zero,
        onTap: slug == null ? null : () => context.push(Routes.libraryEntry(slug)),
        // The leaf fills the card's left edge whatever height the words take.
        child: Stack(
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _leafMinHeight),
              child: Padding(
                padding: const EdgeInsets.only(left: _leafWidth),
                child: _Words(quiz: quiz, linked: slug != null),
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
      ),
    );
  }
}

const double _leafWidth = 78;
const double _leafMinHeight = 150;

class _Words extends StatelessWidget {
  const _Words({required this.quiz, required this.linked});

  final TodayQuiz quiz;

  /// Whether the card opens the day's Vichar page, so the arrow shows.
  final bool linked;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    final language = Localizations.localeOf(context).languageCode;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  (quiz.day?.label(language) ?? l.quizDidYouKnow).toUpperCase(),
                  style: HazriText.eyebrow.copyWith(color: c.kesriInk),
                ),
              ),
              if (linked) AppIcon(HazriIconData.chevronRight, size: 16, color: c.kesriInk),
            ],
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
        ],
      ),
    );
  }
}

/// Design D on Today (owner, 2026-10-28; 14-quiz.md QZ12): the quiz's own
/// card. Gurmat Quiz with your points and All quizzes; today's topic as a
/// highlighted tile with Start; then the other categories as drawn tiles,
/// each opening the quiz page on that category. Nothing here fetches: the
/// points are the ones the phone already holds (`quiz_me_v1`).
class QuizPickCard extends ConsumerWidget {
  const QuizPickCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quiz = ref.watch(todayQuizProvider).value;
    if (quiz == null) return const SizedBox.shrink();
    final c = context.colors;
    final l = L.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final online = ref.watch(quizOnlineProvider);
    final me = online ? ref.watch(quizMeProvider) : null;
    final d = quiz.date;
    final key =
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final pointsToday = me?.days[key] ?? 0;
    final others = [
      for (final cat in const ['gurus', 'gurdwaras', 'banis', 'heroes', 'culture'])
        if (cat != quiz.topic.category.name) cat,
      'all',
    ];

    return HazriCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 0, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(l.quizTitle, style: HazriText.display22.copyWith(color: c.ink, fontSize: 19)),
                ),
                if (me != null)
                  HazriChip(
                    label: pointsToday > 0 ? l.quizPointsToday(pointsToday) : l.quizPointsShort(me.points),
                    background: pointsToday > 0 ? c.sageSoft : c.kesriSoft,
                    foreground: pointsToday > 0 ? c.sage : c.kesriInk,
                    minHeight: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                TextButton(
                  onPressed: () => context.push(Routes.quiz),
                  style: TextButton.styleFrom(
                    foregroundColor: c.kesriInk,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l.quizAllQuizzes, style: HazriText.captionStrong.copyWith(color: c.kesriInk, fontSize: 13)),
                      AppIcon(HazriIconData.chevronRight, size: 14, color: c.kesriInk),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: c.kesri, width: 2),
                gradient: LinearGradient(colors: [c.kesriSoft, c.card]),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(color: c.card, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: QuizTopicGlyph(quiz.topic, size: 48),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.quizPeriodToday.toUpperCase(), style: HazriText.eyebrow.copyWith(color: c.kesriInk)),
                        Text(
                          quiz.topic.name(language),
                          style: HazriText.display22.copyWith(color: c.ink, fontSize: 19, height: 1.15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          online ? l.quizCardLine : l.quizCardLineNoProfile,
                          style: HazriText.caption.copyWith(color: c.ink2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  PrimaryButton(
                    label: l.quizStart,
                    expanded: false,
                    minHeight: 44,
                    onPressed: () => context.push(Routes.quizPlay(quiz.topic.id)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(l.quizPickAnother.toUpperCase(), style: HazriText.eyebrow.copyWith(color: c.muted)),
          const SizedBox(height: 8),
          SizedBox(
            height: 96,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final cat in others)
                  _CategoryTile(
                    category: cat,
                    label: categoryLabel(l, cat),
                    onTap: () => context.push(Routes.quizCategory(cat)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.label, required this.onTap});

  final String category;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            width: 76,
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(color: c.kesriSoft, borderRadius: BorderRadius.circular(20)),
                  alignment: Alignment.center,
                  child: QuizCategoryDrawing(category, size: 44),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: HazriText.captionStrong.copyWith(color: c.ink2, fontSize: 11.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
