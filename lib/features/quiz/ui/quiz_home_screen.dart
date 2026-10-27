import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/time/date_format.dart';
import '../../../core/widgets/surfaces.dart';
import '../../settings/ui/screen_scaffold.dart';
import '../data/quiz_repository.dart';
import '../domain/quiz.dart';
import 'quiz_widgets.dart';

/// Design 6A (14-quiz.md QZ33): the total, Coming up on the calendar, the
/// featured categories as drawn tiles, and the chosen category's quizzes.
class QuizHomeScreen extends ConsumerStatefulWidget {
  const QuizHomeScreen({super.key});

  @override
  ConsumerState<QuizHomeScreen> createState() => _QuizHomeScreenState();
}

class _QuizHomeScreenState extends ConsumerState<QuizHomeScreen> {
  String? _category;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final topics = ref.watch(quizTopicsProvider).value ?? const <QuizTopic>[];
    final today = ref.watch(todayQuizProvider).value;
    final coming = ref.watch(comingUpQuizProvider).value ?? const <TodayQuiz>[];
    final me = ref.watch(quizMeProvider);
    final online = ref.watch(quizOnlineProvider);
    final category = _category ?? today?.topic.category.name ?? 'gurus';
    final shown = [
      for (final t in topics)
        if (category == 'all' || t.category.name == category) t,
    ];
    // The next date each topic has on the calendar, for its row's chip.
    final nextDate = {for (final q in coming.reversed) q.topic.id: q.date};
    final dates = HazriDates.of(context);

    return HazriScreen(
      title: l.quizTitle,
      actions: [
        if (online)
          HazriChip(
            label: l.quizPointsShort(me?.points ?? 0),
            background: c.kesriSoft,
            foreground: c.kesriInk,
            minHeight: 40,
            onTap: () => context.push(Routes.quizMe),
          ),
        IconButton(
          tooltip: l.quizLeaderboardTitle,
          onPressed: () => context.push(Routes.quizBoard()),
          icon: Icon(Icons.leaderboard_outlined, color: c.ink2),
        ),
      ],
      children: [
        if (topics.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Text(l.quizEmpty, textAlign: TextAlign.center, style: HazriText.body.copyWith(color: c.muted)),
          )
        else ...[
          if (!online)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: HazriCard(
                onTap: () => context.push(Routes.profileSetup),
                child: Text(l.quizMakeProfileHeader, style: HazriText.bodyStrong.copyWith(color: c.kesriInk)),
              ),
            ),
          // Coming up on the calendar: today's topic first, with Start.
          HazriCard(
            colour: c.primary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.quizComingUp.toUpperCase(), style: HazriText.eyebrow.copyWith(color: c.kesri)),
                const SizedBox(height: 10),
                if (today != null)
                  _ComingRow(
                    day: '${today.date.day}',
                    month: dates.monthAbbrUpper(today.date),
                    title: today.topic.name(language),
                    subtitle: [l.quizPeriodToday, ?today.day?.label(language)].join(' · '),
                    onStart: () => context.push(Routes.quizPlay(today.topic.id)),
                    startLabel: l.quizStart,
                  ),
                for (final q in coming) ...[
                  Divider(height: 18, color: c.onPrimary.withValues(alpha: 0.15)),
                  _ComingRow(
                    day: '${q.date.day}',
                    month: dates.monthAbbrUpper(q.date),
                    title: q.topic.name(language),
                    subtitle: q.day?.label(language) ?? '',
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(l.quizFeatured, style: HazriText.display22.copyWith(color: c.ink, fontSize: 18)),
          const SizedBox(height: 10),
          SizedBox(
            height: 104,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final cat in const ['all', 'gurus', 'gurdwaras', 'banis', 'heroes', 'culture'])
                  _CategoryTile(
                    category: cat,
                    label: categoryLabel(l, cat),
                    selected: cat == category,
                    onTap: () => setState(() => _category = cat),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(categoryLabel(l, category), style: HazriText.display22.copyWith(color: c.ink, fontSize: 18)),
              ),
              Text(l.quizCount(shown.length), style: HazriText.caption.copyWith(color: c.muted)),
            ],
          ),
          const SizedBox(height: 8),
          for (final t in shown)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: HazriCard(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                onTap: () => context.push(Routes.quizPlay(t.id)),
                child: Row(
                  children: [
                    QuizTopicGlyph(t),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  t.name(language),
                                  maxLines: 2,
                                  style: HazriText.bodyStrong.copyWith(color: c.ink),
                                ),
                              ),
                              if (t.id == today?.topic.id || nextDate[t.id] != null) ...[
                                const SizedBox(width: 6),
                                HazriChip(
                                  label: t.id == today?.topic.id ? l.quizPeriodToday : dates.shortDate(nextDate[t.id]!),
                                  background: c.kesriSoft,
                                  foreground: c.kesriInk,
                                  minHeight: 22,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            online ? l.quizRowLine(me?.topics[t.id] ?? 0) : l.quizRowLineNoProfile,
                            style: HazriText.caption.copyWith(color: c.muted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    PrimaryButton(
                      label: l.quizStart,
                      expanded: false,
                      minHeight: 40,
                      onPressed: () => context.push(Routes.quizPlay(t.id)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _ComingRow extends StatelessWidget {
  const _ComingRow({
    required this.day,
    required this.month,
    required this.title,
    required this.subtitle,
    this.onStart,
    this.startLabel,
  });

  final String day;
  final String month;
  final String title;
  final String subtitle;
  final VoidCallback? onStart;
  final String? startLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        SizedBox(
          width: 44,
          child: Column(
            children: [
              Text(day, style: HazriText.display22.copyWith(color: c.onPrimary, fontSize: 22, height: 1)),
              Text(month, style: HazriText.captionStrong.copyWith(color: c.onPrimary.withValues(alpha: 0.7), fontSize: 10.5)),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: HazriText.bodyStrong.copyWith(color: c.onPrimary)),
              if (subtitle.isNotEmpty)
                Text(subtitle, style: HazriText.caption.copyWith(color: c.onPrimary.withValues(alpha: 0.72))),
            ],
          ),
        ),
        if (onStart != null)
          PrimaryButton(
            label: startLabel!,
            expanded: false,
            minHeight: 40,
            background: c.kesri,
            foreground: Colors.white,
            onPressed: onStart,
          ),
      ],
    );
  }
}

/// A rounded saffron tile with its drawing; the chosen one outlined (6A).
class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.label, required this.selected, required this.onTap});

  final String category;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: GestureDetector(
          onTap: onTap,
          child: SizedBox(
            width: 74,
            child: Column(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: c.kesriSoft,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: selected ? c.kesri : Colors.transparent, width: 2.5),
                  ),
                  alignment: Alignment.center,
                  child: QuizCategoryDrawing(category, size: 46),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: HazriText.captionStrong.copyWith(color: selected ? c.kesriInk : c.ink2, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
