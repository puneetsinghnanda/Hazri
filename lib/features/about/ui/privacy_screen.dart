
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/surfaces.dart';
import '../../settings/ui/screen_scaffold.dart';

/// Design 35, as PRD §8.3 words it: what stays on the phone, what a profile
/// sends, what a group sends. PRD §8.1 is the closed list this must agree
/// with, and Google Play's Data safety form with both; neither runs ahead of
/// the build.
class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);

    return HazriScreen(
      title: l.privacyDataTitle,
      children: [
        const SizedBox(height: 6),
        Text(l.privacyBody, style: HazriText.body.copyWith(color: c.ink2)),
        const SizedBox(height: 16),
        HazriCard(
          colour: c.sageSoft,
          child: Text(l.privacyNothingUnless, style: HazriText.bodySmall.copyWith(color: c.sage)),
        ),
        const SizedBox(height: 6),
        _Section(title: l.privacyOnPhoneOnly, icon: HazriIconData.lock, items: [
          l.privacyPhoneDiary,
          l.privacyPhoneProgress,
          l.privacyPhoneContent,
          l.privacyPhoneSignIn,
        ]),
        _Section(title: l.privacyWithProfile, icon: HazriIconData.mail, items: [
          l.privacyProfileDetails,
          l.privacyProfileMail,
          l.privacyProfileAttendance,
          l.privacyProfileBackup,
          // 14-quiz.md QZ14, QZ27: the quiz with a profile, and the boards.
          l.privacyProfileQuiz,
          l.privacyProfileLeaderboard,
        ]),
        _Section(title: l.privacyWithGroup, icon: HazriIconData.sangat, items: [
          l.privacyGroupCounts,
          l.privacyGroupName,
          l.privacyGroupToken,
          // 08-sangat GG7: a group's globe, counts per city only.
          l.privacyGroupGlobe,
        ]),
        const SizedBox(height: 18),
        HazriCard(
          colour: c.card2,
          child: Text(l.privacyGlobe, style: HazriText.bodySmall.copyWith(color: c.ink2)),
        ),
      ],
    );
  }
}

/// One heading and the plain list under it.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.icon, required this.items});

  final String title;
  final String icon;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
          child: Row(
            children: [
              AppIcon(icon, size: 16, color: c.muted),
              const SizedBox(width: 8),
              Flexible(child: Eyebrow(title)),
            ],
          ),
        ),
        HazriCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(color: c.muted, shape: BoxShape.circle),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(items[i],
                          style: HazriText.bodySmall.copyWith(color: c.ink2)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
