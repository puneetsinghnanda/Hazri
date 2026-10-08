import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/time/date_format.dart';
import '../../../core/widgets/surfaces.dart';
import '../../profile/ui/messages.dart';
import '../data/backup_controller.dart';
import '../data/backup_service.dart';

/// The Profile screen's backup block (`10-backup.md` §8.2), shown only with
/// a profile.
class BackupSection extends ConsumerStatefulWidget {
  const BackupSection({super.key});

  @override
  ConsumerState<BackupSection> createState() => _BackupSectionState();
}

class _BackupSectionState extends ConsumerState<BackupSection> {
  bool _busy = false;

  Future<void> _backup() async {
    final l = L.of(context);
    setState(() => _busy = true);
    final outcome = await ref.read(backupControllerProvider).runNow();
    if (!mounted) return;
    setState(() => _busy = false);
    ProfileMessages.snack(context, switch (outcome) {
      BackupSaved() => l.backupDone,
      BackupFailed(:final error) => ProfileMessages.of(l, error),
      // ST3: a rate limit is waited out, not reported as an error.
      _ => l.backupDone,
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    final dates = HazriDates.of(context);
    final status = ref.watch(backupStatusProvider);
    final last = status.lastAt;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: HazriCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Eyebrow(l.backupSectionTitle),
            const SizedBox(height: 6),
            Text(
              status.stale
                  ? l.backupStale
                  : last == null
                      ? l.backupNever
                      : l.backupLastLine('${dates.shortDate(last.toLocal())}, ${dates.time(last.toLocal())}'),
              style: HazriText.bodySmall.copyWith(color: status.stale ? c.kesriInk : c.ink2),
            ),
            const SizedBox(height: 12),
            _busy
                ? const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()))
                : PrimaryButton(label: l.backupNowButton, secondary: true, onPressed: _backup),
            const SizedBox(height: 10),
            RestoreDataButton(enabled: !_busy),
          ],
        ),
      ),
    );
  }
}

/// `restoreDataButton` (RS1): asks first, saying how old the copy is (RS8),
/// then restores with progress and says how many entries came back.
class RestoreDataButton extends ConsumerStatefulWidget {
  const RestoreDataButton({super.key, this.enabled = true});

  final bool enabled;

  @override
  ConsumerState<RestoreDataButton> createState() => _RestoreDataButtonState();
}

class _RestoreDataButtonState extends ConsumerState<RestoreDataButton> {
  bool _busy = false;

  Future<void> _restore() async {
    final l = L.of(context);
    final dates = HazriDates.of(context);
    final last = ref.read(backupServiceProvider).lastBackupAt;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l.restoreConfirmTitle),
        content: Text([
          l.restoreConfirmBody,
          if (last != null) l.restoreAsOf(dates.shortDate(last.toLocal())),
        ].join('\n\n')),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialog).pop(false), child: Text(l.actionCancel)),
          TextButton(onPressed: () => Navigator.of(dialog).pop(true), child: Text(l.restoreButton)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    final outcome = await ref.read(backupControllerProvider).restore();
    if (!mounted) return;
    setState(() => _busy = false);
    ProfileMessages.snack(context, switch (outcome) {
      RestoreDone(:final added) => l.restoreDone(added),
      RestoreNothing() => l.restoreNothing,
      BackupFailed(:final error) => ProfileMessages.of(l, error),
      _ => l.msgGeneric,
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return _busy
        ? const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()))
        : PrimaryButton(
            label: l.restoreDataButton,
            secondary: true,
            onPressed: widget.enabled ? _restore : null,
          );
  }
}
