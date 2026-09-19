import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/widgets/surfaces.dart';
import '../../settings/ui/screen_scaffold.dart';
import '../data/library_repository.dart';
import 'library_screen.dart' show kindLabel;

/// Designs 44 and 45 — one entry, whether it is an article to read or a place
/// to look up.
///
/// One screen for both because the difference is in the data, not the layout:
/// a Gurdwara has labelled facts and an article has paragraphs, and an entry
/// with both shows both.
class LibraryEntryScreen extends ConsumerWidget {
  const LibraryEntryScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final entry = ref.watch(libraryEntryProvider(id)).value;

    if (entry == null) {
      return HazriScreen(
        title: l.libraryTitle,
        children: [
          const SizedBox(height: 40),
          Center(
            child: Text(l.libraryNothingMatches,
                style: HazriText.body.copyWith(color: c.muted)),
          ),
        ],
      );
    }

    final paragraphs = entry.body
        .split(RegExp(r'\n\s*\n'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    return HazriScreen(
      title: entry.title,
      subtitle: entry.place.isEmpty ? null : entry.place,
      children: [
        const SizedBox(height: 4),
        Row(
          children: [
            Eyebrow(kindLabel(l, entry.kind)),
            if (entry.minutes > 0) ...[
              const SizedBox(width: 10),
              Text(l.libraryMinutes(entry.minutes),
                  style: HazriText.caption.copyWith(color: c.muted)),
            ],
          ],
        ),
        if (entry.summary.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(entry.summary,
              style: HazriText.body.copyWith(color: c.ink, height: 1.6)),
        ],
        if (entry.facts.isNotEmpty) ...[
          const SizedBox(height: 14),
          HazriCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final fact in entry.facts.entries) ...[
                  if (fact.key != entry.facts.keys.first) const SizedBox(height: 12),
                  Text(fact.key, style: HazriText.eyebrow.copyWith(color: c.muted)),
                  const SizedBox(height: 2),
                  Text(fact.value,
                      style: HazriText.bodySmall.copyWith(color: c.ink)),
                ],
              ],
            ),
          ),
        ],
        for (final paragraph in paragraphs) ...[
          const SizedBox(height: 14),
          Text(paragraph,
              style: HazriText.body.copyWith(color: c.ink2, height: 1.7)),
        ],
        const SizedBox(height: 20),
        Text(l.libraryCorrections,
            style: HazriText.caption.copyWith(color: c.muted)),
      ],
    );
  }
}
