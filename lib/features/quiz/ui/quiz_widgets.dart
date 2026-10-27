import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/db/content_repository.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/widgets/surfaces.dart';
import '../domain/quiz.dart';
import 'quiz_drawings.dart';

/// A category's drawing (design 6A). The Banis book carries content.db's ੴ,
/// never one typed into Dart.
class QuizCategoryDrawing extends ConsumerWidget {
  const QuizCategoryDrawing(this.category, {super.key, this.size = 44});

  /// A [QuizCategory] name, or `all`.
  final String category;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final svg = switch (category) {
      'gurus' => QuizDrawings.gurus,
      'gurdwaras' => QuizDrawings.gurdwaras,
      'banis' => QuizDrawings.banis,
      'heroes' => QuizDrawings.heroes,
      'culture' => QuizDrawings.culture,
      _ => QuizDrawings.all,
    };
    final picture = SvgPicture.string(svg, width: size, height: size);
    if (category != 'banis') return picture;
    final ik = ref.watch(ikOnkarProvider).value ?? '';
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          picture,
          if (ik.isNotEmpty)
            Positioned(
              top: size * 0.02,
              child: Text(
                ik,
                style: HazriText.gurmukhi(size * 0.22, weight: FontWeight.w700).copyWith(color: const Color(0xFFD9730D)),
              ),
            ),
        ],
      ),
    );
  }
}

/// A topic's mark on its row: a Gurmukhi numeral or ੴ from content.db on navy,
/// or its category's drawing.
class QuizTopicGlyph extends StatelessWidget {
  const QuizTopicGlyph(this.topic, {super.key, this.size = 46});

  final QuizTopic topic;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (topic.drawn) {
      return SizedBox(width: size, height: size, child: Center(child: QuizCategoryDrawing(topic.glyph, size: size)));
    }
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E3577), Color(0xFF1A1E48)],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        topic.glyph,
        style: HazriText.gurmukhi(size * (topic.glyph.length > 1 ? 0.36 : 0.44), weight: FontWeight.w700)
            .copyWith(color: const Color(0xFFF6C26B), height: 1.1),
      ),
    );
  }
}

/// "Make a profile to be on the leaderboard" (QZ29), the card Today's
/// profile banner is.
class QuizProfileCard extends StatelessWidget {
  const QuizProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    return HazriCard(
      colour: c.kesriSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.quizProfileCardTitle, style: HazriText.bodyStrong.copyWith(color: c.ink)),
          const SizedBox(height: 4),
          Text(l.quizProfileCardBody, style: HazriText.bodySmall.copyWith(color: c.ink2)),
          const SizedBox(height: 12),
          PrimaryButton(
            label: l.quizMakeProfile,
            expanded: false,
            onPressed: () => context.push(Routes.profileSetup),
          ),
        ],
      ),
    );
  }
}

/// A city's name in the app language, from content.db.
String cityName(WidgetRef ref, String? cityId, String language) {
  if (cityId == null) return '';
  final cities = ref.watch(citiesProvider).value ?? const [];
  for (final c in cities) {
    if (c.id == cityId) {
      return switch (language) {
        'pa' => c.namePa,
        'hi' => c.nameHi,
        _ => c.nameEn,
      };
    }
  }
  return '';
}

/// A round avatar with initials.
class QuizAvatar extends StatelessWidget {
  const QuizAvatar(this.initials, {super.key, this.size = 36, this.highlight = false});

  final String initials;
  final double size;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: highlight ? c.kesri : c.card2),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: HazriText.captionStrong.copyWith(color: highlight ? Colors.white : c.ink2, fontSize: size * 0.36),
      ),
    );
  }
}

/// The category label in the app language.
String categoryLabel(L l, String category) => switch (category) {
  'gurus' => l.quizCatGurus,
  'gurdwaras' => l.quizCatGurdwaras,
  'banis' => l.quizCatBanis,
  'heroes' => l.quizCatHeroes,
  'culture' => l.quizCatCulture,
  _ => l.quizCatAll,
};
