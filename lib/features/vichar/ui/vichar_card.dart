import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/db/content_repository.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/surfaces.dart';
import 'vichar_share.dart';

/// ਅੱਜ ਦਾ ਵਿਚਾਰ — one line of Gurbani a day on Today (PRD 1.11).
class VicharCard extends ConsumerWidget {
  const VicharCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final vichar = ref.watch(todayVicharProvider).value;

    if (vichar == null) {
      return HazriCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.vicharTitle, style: HazriText.bodyStrong.copyWith(color: c.ink)),
            const SizedBox(height: 6),
            Text(l.vicharNone, style: HazriText.bodySmall.copyWith(color: c.muted)),
          ],
        ),
      );
    }

    return HazriCard(
      onTap: () => context.push(Routes.vichar),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: c.kesriSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: AppIcon(HazriIconData.sparkle, size: 19, color: c.kesriInk),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.vicharTitle,
                        style: HazriText.bodyStrong.copyWith(color: c.ink)),
                    Text(l.vicharSource,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: HazriText.caption.copyWith(color: c.muted)),
                  ],
                ),
              ),
              AppIcon(HazriIconData.chevronRight, size: 18, color: c.muted),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            vichar.gurmukhi,
            style: HazriText.gurmukhi(21).copyWith(color: c.word, height: 1.75),
          ),
          const SizedBox(height: 10),
          Text(
            vichar.meaningIn(language),
            style: HazriText.body.copyWith(color: c.ink2, height: 1.5),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: l.vicharExplore,
                  secondary: true,
                  onPressed: () => context.push(Routes.vichar),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PrimaryButton(
                  label: l.shareCardShare,
                  onPressed: () => showVicharShareSheet(context, vichar),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
