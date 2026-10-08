import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/db/content_repository.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/app_mark.dart';
import '../../../core/widgets/surfaces.dart';
import '../../nitnem/domain/bani.dart';

/// Welcome (03-first-run F2, design 92, option D "a day with Hazri"): the
/// mark and name, the headline, one day as a timeline of five cards, and
/// Begin. A fixed illustration, never the reader's own data; bani names
/// from `content.db`. No carousel, no dots, no swipe.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final banis = ref.watch(banisProvider).value ?? const <Bani>[];
    String bani(String id) =>
        banis.where((b) => b.id == id).firstOrNull?.name(l.localeName) ?? '';

    final day = [
      (
        l.welcomeAmritVelaTime,
        HazriIconData.bell,
        l.welcomeAmritVela,
        l.welcomeAmritVelaSub(bani('JAPJ')),
      ),
      (
        l.welcomeHazriTime,
        HazriIconData.check,
        l.hazriMarked,
        l.welcomeHazriSub(bani('JAPJ')),
      ),
      (
        l.welcomeGoalTime,
        HazriIconData.flag,
        l.welcomeGoal,
        l.welcomeGoalSub(bani('JAPJ')),
      ),
      (
        l.welcomeSangatTime,
        HazriIconData.sangat,
        l.welcomeSangat,
        l.welcomeSangatSub(bani('SUKH')),
      ),
      (
        l.welcomeStreakTime,
        HazriIconData.sunArc,
        l.welcomeStreak,
        l.welcomeStreakSub,
      ),
    ];

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: PhoneWidth(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    HazriSize.gutter,
                    24,
                    HazriSize.gutter,
                    12,
                  ),
                  children: [
                    Row(
                      children: [
                        const AppMark(size: 34),
                        const SizedBox(width: 10),
                        Text(
                          l.appName,
                          style: HazriText.brand.copyWith(
                            color: c.ink,
                            fontSize: 24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: '${l.welcomeTitleLead} '),
                          TextSpan(
                            text: l.welcomeTitleWord,
                            style: TextStyle(color: c.kesri),
                          ),
                        ],
                      ),
                      style: HazriText.display26.copyWith(
                        color: c.ink,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 22),
                    for (final (time, icon, title, sub) in day)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 64,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 14),
                                child: Text(
                                  time,
                                  style: HazriText.captionStrong.copyWith(
                                    color: c.muted,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: HazriCard(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    AppIcon(icon, size: 20, color: c.kesri),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            style: HazriText.bodyStrong
                                                .copyWith(color: c.ink),
                                          ),
                                          Text(
                                            sub,
                                            style: HazriText.caption.copyWith(
                                              color: c.muted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  HazriSize.gutter,
                  4,
                  HazriSize.gutter,
                  16,
                ),
                child: Column(
                  children: [
                    Text(
                      [
                        l.chipWorksOffline,
                        l.chipNoLogin,
                        l.chipNoAdsOnGurbani,
                      ].join(' · '),
                      textAlign: TextAlign.center,
                      style: HazriText.caption.copyWith(color: c.muted),
                    ),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      label: l.welcomeBegin,
                      onPressed: () {
                        // F-2: elder mode pre-selected at a large system font
                        // scale, never forced; How you read can turn it off.
                        if (MediaQuery.textScalerOf(context).scale(10) >= 13) {
                          ref
                              .read(settingsProvider.notifier)
                              .setElderMode(true);
                        }
                        context.go(Routes.setup(1));
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
