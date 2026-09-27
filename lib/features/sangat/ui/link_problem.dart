import 'package:flutter/material.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/surfaces.dart';
import '../data/account_repository.dart';

/// Design 52 — why a link did not work, in the words that tell somebody what
/// to do next.
///
/// The three cases are kept apart because the answer differs. Two of them
/// mean send another; the third means sending another will not help, because
/// what was pasted was not our link at all.
class LinkProblemCard extends StatelessWidget {
  const LinkProblemCard({super.key, required this.problem});

  final LinkProblem problem;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);

    final (title, body) = wordsForLinkProblem(problem, l);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.linkProblemTitle,
            style: HazriText.bodyStrong.copyWith(color: c.kesriInk)),
        const SizedBox(height: 8),
        HazriCard(
          colour: c.card2,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppIcon(HazriIconData.alert, size: 18, color: c.kesriInk),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: HazriText.captionStrong.copyWith(color: c.ink)),
                    const SizedBox(height: 2),
                    Text(body, style: HazriText.caption.copyWith(color: c.ink2)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(l.linkWrongAddressNote,
            style: HazriText.caption.copyWith(color: c.muted)),
      ],
    );
  }
}

/// What a link problem says, as a title and a body.
///
/// Out here rather than inside `build` so a test can assert the four stay
/// apart. They must: two of them mean send another link and two mean that
/// sending another will not help, so a shared sentence is a reader stuck in
/// a loop. `invalid-email` and `invalid-action-code` shared one until
/// 2026-09-27.
(String, String) wordsForLinkProblem(LinkProblem problem, L l) =>
    switch (problem) {
      LinkProblem.alreadyUsed => (l.linkUsedTitle, l.linkUsedBody),
      LinkProblem.expired => (l.linkExpiredTitle, l.linkExpiredBody),
      LinkProblem.wrongAddress => (l.linkWrongTitle, l.linkWrongBody),
      LinkProblem.addressMismatch => (l.linkMismatchTitle, l.linkMismatchBody),
    };
