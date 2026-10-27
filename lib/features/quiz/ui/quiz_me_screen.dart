import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/time/clock.dart';
import '../../../core/widgets/surfaces.dart';
import '../../profile/data/profile_controller.dart';
import '../../settings/ui/screen_scaffold.dart';
import '../data/quiz_repository.dart';
import '../domain/quiz.dart';
import 'quiz_widgets.dart';

/// Design 7A (14-quiz.md QZ34): a navy card with the name, city, total and
/// places, then the month as a calendar with each day's points.
class QuizMeScreen extends ConsumerWidget {
  const QuizMeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final profile = ref.watch(profileControllerProvider);
    final me = ref.watch(quizMeProvider);
    if (profile is! ProfileLoaded || me == null) {
      return HazriScreen(title: l.quizYourNumbers, children: const [SizedBox(height: 8), QuizProfileCard()]);
    }
    final p = profile.profile;
    final today = ref.watch(clockProvider).today();
    final first = DateTime(today.year, today.month);
    final daysInMonth = DateTime(today.year, today.month + 1, 0).day;
    String key(int d) =>
        '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
    final monthTotal = [for (var d = 1; d <= daysInMonth; d++) me.days[key(d)] ?? 0].fold(0, (a, b) => a + b);
    final number = NumberFormat.decimalPattern(language == 'en' ? 'en_IN' : '${language}_IN');
    final lead = (first.weekday + 6) % 7; // Monday first
    final weekdays = [for (var i = 0; i < 7; i++) DateFormat.E(language == 'en' ? 'en' : '${language}_IN').format(DateTime(2026, 10, 26 + i))];

    Widget place(int? n, String label) => Expanded(
      child: Column(
        children: [
          Text(n == null ? '–' : '#$n', style: HazriText.display22.copyWith(color: Colors.white, fontSize: 20)),
          Text(label, style: HazriText.caption.copyWith(color: Colors.white.withValues(alpha: 0.72))),
        ],
      ),
    );

    return HazriScreen(
      title: l.quizYourNumbers,
      children: [
        const SizedBox(height: 4),
        HazriCard(
          colour: c.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  QuizAvatar(initialsOf(p.name), size: 44, highlight: true),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name, style: HazriText.bodyStrong.copyWith(color: Colors.white)),
                        Text(
                          cityName(ref, p.cityId, language),
                          style: HazriText.caption.copyWith(color: Colors.white.withValues(alpha: 0.72)),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(number.format(me.points), style: HazriText.display26.copyWith(color: c.kesri, height: 1)),
                      Text(l.quizPointsLabel, style: HazriText.caption.copyWith(color: Colors.white.withValues(alpha: 0.72))),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  place(me.places['day'], l.quizPlaceToday),
                  place(me.places['week'], l.quizPlaceWeek),
                  place(me.places['month'], l.quizPlaceMonth),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        HazriCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      DateFormat('MMMM', language == 'en' ? 'en' : '${language}_IN').format(first),
                      style: HazriText.display22.copyWith(color: c.ink, fontSize: 18),
                    ),
                  ),
                  Text(l.quizMonthTotal(monthTotal), style: HazriText.bodyStrong.copyWith(color: c.kesriInk)),
                ],
              ),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 7,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 0.82,
                children: [
                  for (final w in weekdays)
                    Center(child: Text(w.characters.first, style: HazriText.captionStrong.copyWith(color: c.muted))),
                  for (var i = 0; i < lead; i++) const SizedBox.shrink(),
                  for (var d = 1; d <= daysInMonth; d++)
                    _DayCell(day: d, points: me.days[key(d)] ?? 0, today: d == today.day, future: d > today.day),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.points, required this.today, required this.future});

  final int day;
  final int points;
  final bool today;
  final bool future;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: points > 0 ? c.kesriSoft : null,
        borderRadius: BorderRadius.circular(10),
        border: today ? Border.all(color: c.kesri, width: 1.5) : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$day', style: HazriText.caption.copyWith(color: future ? c.muted : c.ink, fontSize: 12)),
          if (points > 0)
            Text('$points', style: HazriText.captionStrong.copyWith(color: c.kesriInk, fontSize: 10.5)),
        ],
      ),
    );
  }
}
