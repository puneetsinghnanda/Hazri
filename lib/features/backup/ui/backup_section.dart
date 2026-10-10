import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/time/date_format.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/surfaces.dart';
import '../../profile/ui/messages.dart';
import '../../profile/ui/profile_icons.dart';
import '../data/backup_controller.dart';
import '../data/backup_service.dart';

// The Profile screen's backup pieces (`10-backup.md` §8.2), shown only with
// a profile. Design 100 sets them apart: Back up now beside Edit profile,
// the last backup as a quiet line, Restore as a text button under it.

/// While a backup started by hand is running, Restore waits.
final _backupRunningProvider = StateProvider.autoDispose<bool>((ref) => false);

/// `backupNowButton` (BK3): runs a backup at once, with progress, then
/// `backupDone`.
class BackupNowButton extends ConsumerWidget {
  const BackupNowButton({super.key});

  Future<void> _backup(BuildContext context, WidgetRef ref) async {
    final l = L.of(context);
    final running = ref.read(_backupRunningProvider.notifier);
    running.state = true;
    final outcome = await ref.read(backupControllerProvider).runNow();
    if (!context.mounted) return;
    running.state = false;
    ProfileMessages.snack(context, switch (outcome) {
      BackupSaved() => l.backupDone,
      BackupFailed(:final error) => ProfileMessages.of(l, error),
      // ST3: a rate limit is waited out, not reported as an error.
      _ => l.backupDone,
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    if (ref.watch(_backupRunningProvider)) {
      return const SizedBox(
        height: HazriSize.buttonMinHeight,
        child: Center(child: SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2.5))),
      );
    }
    return PrimaryButton(
      label: l.backupNowButton,
      icon: ProfileIcons.cloud,
      secondary: true,
      onPressed: () => _backup(context, ref),
    );
  }
}

/// `backupLastLine`, `backupNever` or `backupStale` (ST1), with [suffix]
/// after a middle dot.
class BackupStatusLine extends ConsumerWidget {
  const BackupStatusLine({super.key, this.suffix});

  final String? suffix;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final dates = HazriDates.of(context);
    final status = ref.watch(backupStatusProvider);
    final last = status.lastAt;
    final line = status.stale
        ? l.backupStale
        : last == null
            ? l.backupNever
            : l.backupLastLine('${dates.shortDate(last.toLocal())}, ${dates.time(last.toLocal())}');
    final style = HazriText.bodySmall.copyWith(fontSize: 13, color: c.ink2);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: line, style: status.stale ? style.copyWith(color: c.kesriInk) : null),
          if (suffix != null) TextSpan(text: ' · $suffix'),
        ],
      ),
      style: style,
    );
  }
}

/// `restoreDataButton` (RS1): asks first, saying how old the copy is (RS8),
/// then restores with progress and says how many entries came back.
///
/// [quiet] draws it as the Profile screen's text button (design 100); the
/// Link Result screen keeps the full-width one.
class RestoreDataButton extends ConsumerStatefulWidget {
  const RestoreDataButton({super.key, this.enabled = true, this.quiet = false});

  final bool enabled;
  final bool quiet;

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
    final c = context.colors;
    final l = L.of(context);
    final enabled = widget.enabled && !ref.watch(_backupRunningProvider);
    if (_busy) {
      return const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()));
    }
    if (!widget.quiet) {
      return PrimaryButton(
        label: l.restoreDataButton,
        secondary: true,
        onPressed: enabled ? _restore : null,
      );
    }
    final fg = c.primary;
    return Center(
      child: TextButton(
        onPressed: enabled ? _restore : null,
        style: TextButton.styleFrom(
          foregroundColor: fg,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(ProfileIcons.restore, size: 17, color: enabled ? fg : c.muted),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                l.restoreDataButton,
                style: HazriText.bodySmall.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: enabled ? fg : c.muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
