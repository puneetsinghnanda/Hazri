import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/surfaces.dart';
import '../../settings/ui/screen_scaffold.dart';
import '../data/library_repository.dart';
import '../domain/library_entry.dart';

/// Designs 43 and 46 — the library, and searching it.
///
/// Not the daily Vichar: that is one line from Sri Guru Granth Sahib Ji and
/// lives on Today (PRD 1.11). This is the reading and looking-up section the
/// reader described — articles, Gurdwaras, the Guru Sahibans, the banis and
/// the Sikh days — and **no line of it is written in the app**. Every word
/// comes from the server, is reviewed before it is published, and is
/// corrected in one place.
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    final loading = ref.watch(libraryEntriesProvider).isLoading;
    final all = ref.watch(libraryEntriesProvider).value ?? const <LibraryEntry>[];
    final results = ref.watch(libraryResultsProvider);
    final query = ref.watch(librarySearchProvider);
    final kind = ref.watch(libraryKindProvider);

    return HazriScreen(
      title: l.libraryTitle,
      subtitle: l.librarySubtitle,
      children: [
        const SizedBox(height: 6),
        TextField(
          controller: _search,
          onChanged: (v) => ref.read(librarySearchProvider.notifier).state = v,
          style: HazriText.body.copyWith(color: c.ink),
          decoration: InputDecoration(
            hintText: l.librarySearchHint,
            hintStyle: HazriText.body.copyWith(color: c.muted),
            prefixIcon: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 10, 0),
              child: AppIcon(HazriIconData.help, size: 18, color: c.muted),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            suffixIcon: query.isEmpty
                ? null
                : IconButton(
                    tooltip: l.libraryClear,
                    onPressed: () {
                      _search.clear();
                      ref.read(librarySearchProvider.notifier).state = '';
                    },
                    icon: AppIcon(HazriIconData.close, size: 16, color: c.muted),
                  ),
            filled: true,
            fillColor: c.card,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: c.rule),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: c.kesri, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final k in EntryKind.topics) ...[
                if (k != EntryKind.topics.first) const SizedBox(width: 8),
                _KindChip(
                  label: kindLabel(l, k),
                  selected: kind == k,
                  onTap: () => ref.read(libraryKindProvider.notifier).state = k,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (query.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              l.libraryResults(results.length, query),
              style: HazriText.caption.copyWith(color: c.muted),
            ),
          ),
        if (loading)
          const Center(child: Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: CircularProgressIndicator(),
          ))
        else if (results.isEmpty)
          HazriCard(
            colour: c.card2,
            child: Text(
              // Three different silences, and they are not the same thing:
              // nothing published yet, nothing matching what was typed, and
              // nothing because there is no connection.
              all.isNotEmpty
                  ? l.libraryNothingMatches
                  : (query.isEmpty ? l.libraryEmpty : l.libraryNothingMatches),
              style: HazriText.bodySmall.copyWith(color: c.ink2),
            ),
          )
        else
          for (final entry in results) ...[
            _EntryCard(entry: entry),
            const SizedBox(height: 10),
          ],
        const SizedBox(height: 16),
        Text(
          l.libraryNeedsConnection,
          style: HazriText.caption.copyWith(color: c.muted),
        ),
      ],
    );
  }
}

/// The eyebrow above every card, and the chip that filters by it.
String kindLabel(L l, EntryKind kind) => switch (kind) {
      EntryKind.article => l.libraryKindArticle,
      EntryKind.gurdwara => l.libraryKindGurdwara,
      EntryKind.guru => l.libraryKindGuru,
      EntryKind.bani => l.libraryKindBani,
      EntryKind.day => l.libraryKindDay,
    };

class _KindChip extends StatelessWidget {
  const _KindChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return HazriChip(
      label: label,
      background: selected ? c.kesriSoft : c.card,
      foreground: selected ? c.kesriInk : c.ink2,
      onTap: onTap,
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry});

  final LibraryEntry entry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    return HazriCard(
      onTap: () => context.push(Routes.libraryEntry(entry.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Eyebrow(kindLabel(l, entry.kind)),
          const SizedBox(height: 6),
          Text(entry.title, style: HazriText.bodyStrong.copyWith(color: c.ink)),
          if (entry.place.isNotEmpty)
            Text(entry.place, style: HazriText.caption.copyWith(color: c.muted)),
          if (entry.summary.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              entry.summary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: HazriText.caption.copyWith(color: c.ink2),
            ),
          ],
          if (entry.minutes > 0) ...[
            const SizedBox(height: 6),
            Text(l.libraryMinutes(entry.minutes),
                style: HazriText.caption.copyWith(color: c.muted)),
          ],
        ],
      ),
    );
  }
}
