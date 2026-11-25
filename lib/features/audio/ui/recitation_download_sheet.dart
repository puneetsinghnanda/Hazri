import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router.dart';
import '../../../core/db/content_db.dart' show AudioTrackRow;
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/surfaces.dart';
import '../data/recitation_downloads.dart';

/// What a press of play does for a recitation the app downloads, when it is
/// not on the phone yet: the download sheet, which fetches it with its
/// progress. Returns the kept path, or null when it was cancelled or could
/// not be had. Overridden in tests; with no screen up it fetches nothing.
final recitationPromptProvider = Provider<Future<String?> Function(AudioTrackRow row, String title)>(
  (ref) => (row, title) async {
    final context = rootNavigatorKey.currentContext;
    if (context == null || !context.mounted) return null;
    return showModalBottomSheet<String>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      builder: (_) => RecitationDownloadSheet(row: row, title: title),
    );
  },
);

/// The download sheet (owner, 2026-11-19): the recitation's name, that it is
/// downloaded once and then plays without internet, a progress ring with
/// "8 of 21 MB", and Cancel. It closes itself and plays when the file is in.
class RecitationDownloadSheet extends ConsumerStatefulWidget {
  const RecitationDownloadSheet({super.key, required this.row, required this.title});

  final AudioTrackRow row;
  final String title;

  @override
  ConsumerState<RecitationDownloadSheet> createState() => _RecitationDownloadSheetState();
}

class _RecitationDownloadSheetState extends ConsumerState<RecitationDownloadSheet> {
  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    unawaited(ref.read(recitationDownloadsProvider.notifier).download(widget.row).then((path) {
      if (path != null && mounted) Navigator.of(context).pop(path);
    }));
  }

  String _mb(int bytes) => (bytes / 1048576).toStringAsFixed(bytes < 10 * 1048576 ? 1 : 0);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    final s = ref.watch(recitationDownloadsProvider)[widget.row.file] ?? const RecitationMissing();
    final total = widget.row.bytes ?? 0;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: HazriText.display22.copyWith(color: c.ink)),
            const SizedBox(height: 6),
            Text(l.recitationDownloadOnce, style: HazriText.bodySmall.copyWith(color: c.ink2)),
            const SizedBox(height: 20),
            switch (s) {
              RecitationFailed(:final offline) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        AppIcon(HazriIconData.alert, size: 22, color: c.kesriInk),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            offline ? l.recitationNoInternet : l.recitationDownloadFailed,
                            style: HazriText.body.copyWith(color: c.ink),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(label: l.actionRetry, onPressed: () => setState(_start)),
                  ],
                ),
              _ => Row(
                  children: [
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        value: s is RecitationDownloading && s.total > 0 ? s.fraction : null,
                        strokeWidth: 4,
                        color: c.kesri,
                        backgroundColor: c.kesriSoft,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        l.recitationDownloading(
                          _mb(s is RecitationDownloading ? s.received : 0),
                          _mb(total),
                        ),
                        style: HazriText.body.copyWith(color: c.ink),
                      ),
                    ),
                  ],
                ),
            },
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                ref.read(recitationDownloadsProvider.notifier).cancel(widget.row);
                Navigator.of(context).pop();
              },
              child: Text(l.actionCancel),
            ),
          ],
        ),
      ),
    );
  }
}
