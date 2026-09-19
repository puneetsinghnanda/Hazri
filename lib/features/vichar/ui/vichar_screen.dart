import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/content_repository.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/widgets/surfaces.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/widgets/app_icon.dart';
import '../../settings/ui/screen_scaffold.dart';
import 'vichar_share.dart';

/// The Vichar in full: the line, and its meaning in both languages.
class VicharScreen extends ConsumerWidget {
  const VicharScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final vichar = ref.watch(todayVicharProvider).value;

    if (vichar == null) {
      return HazriScreen(
        title: l.vicharTitle,
        children: [
          HazriCard(
            child: Text(l.vicharNone, style: HazriText.body.copyWith(color: c.ink2)),
          ),
        ],
      );
    }

    return HazriScreen(
      title: l.vicharTitle,
      subtitle: l.vicharSource,
      children: [
        HazriCard(
          child: Text(
            vichar.gurmukhi,
            style: HazriText.gurmukhi(25).copyWith(color: c.word, height: 1.85),
          ),
        ),
        const SizedBox(height: 12),
        _Meaning(label: l.vicharMeaningPa, body: vichar.meaningPa),
        if (vichar.hasEnglish) ...[
          const SizedBox(height: 12),
          _Meaning(label: l.vicharMeaningEn, body: vichar.meaningEn),
        ],
        const SizedBox(height: 18),
        PrimaryButton(
          label: l.shareCardShare,
          onPressed: () => showVicharShareSheet(context, vichar),
        ),
        const SizedBox(height: 18),
        // The library is a different thing from the day's line, and this is
        // the only door to it. Design 43's own header is a back chevron.
        HazriCard(
          colour: context.colors.card2,
          onTap: () => context.push(Routes.library),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.libraryMoreToRead,
                        style: HazriText.bodyStrong.copyWith(color: c.ink)),
                    Text(l.librarySubtitle,
                        style: HazriText.caption.copyWith(color: c.muted)),
                  ],
                ),
              ),
              AppIcon(HazriIconData.chevronRight, size: 18, color: c.muted),
            ],
          ),
        ),
      ],
    );
  }
}

class _Meaning extends StatelessWidget {
  const _Meaning({required this.label, required this.body});

  final String label;
  final String body;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return HazriCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Eyebrow(label, colour: c.muted),
          const SizedBox(height: 8),
          Text(body, style: HazriText.body.copyWith(color: c.ink, height: 1.55)),
        ],
      ),
    );
  }
}
