import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/widgets/surfaces.dart';
import '../data/audio_controller.dart';

/// Speed and sleep timer (PRD 1.7, 1.8).
Future<void> showPlaybackOptionsSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (_) => const _PlaybackOptionsSheet(),
    );

class _PlaybackOptionsSheet extends ConsumerWidget {
  const _PlaybackOptionsSheet();

  /// The speeds from the PRD. Pitch is preserved by the platform player.
  static const _speeds = [0.75, 0.9, 1.0, 1.1, 1.25, 1.5];

  static const _sleepOptions = <(String, Duration?)>[
    ('off', null),
    ('15', Duration(minutes: 15)),
    ('30', Duration(minutes: 30)),
    ('60', Duration(minutes: 60)),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final speed = ref.watch(settingsProvider.select((s) => s.speed));
    final remaining = ref.watch(sleepRemainingProvider).value;
    final controller = ref.read(playbackControllerProvider);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(HazriSize.gutter, 12, HazriSize.gutter, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: c.rule,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(l.playerSpeed, style: HazriText.bodyStrong.copyWith(color: c.ink)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in _speeds)
                  HazriChip(
                    label: '${s.toStringAsFixed(s == s.roundToDouble() ? 1 : 2)}×',
                    minHeight: 40,
                    background: speed == s ? c.kesriSoft : c.card2,
                    foreground: speed == s ? c.kesriInk : c.ink2,
                    onTap: () => controller.setSpeed(s),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text(l.playerSleepTimer, style: HazriText.bodyStrong.copyWith(color: c.ink)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (label, duration) in _sleepOptions)
                  HazriChip(
                    label: duration == null ? l.off : l.minutes(duration.inMinutes),
                    minHeight: 40,
                    background: (remaining == null) == (duration == null)
                        ? c.kesriSoft
                        : c.card2,
                    foreground: (remaining == null) == (duration == null)
                        ? c.kesriInk
                        : c.ink2,
                    onTap: () {
                      ref.read(audioHandlerProvider)?.setSleepTimer(duration);
                      Navigator.of(context).pop();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: l.actionDone,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
