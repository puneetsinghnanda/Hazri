import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/time/date_format.dart';
import '../../../core/widgets/app_icon.dart';
import '../data/audio_controller.dart';

/// The strip above the bottom nav that says a paath is still going.
///
/// Leaving the reader does not stop the recitation (PRD 1.8), and without this
/// the only sign of that is the sound itself: to pause, someone had to find
/// their way back to Nitnem and into the bani that was playing. It shows
/// whenever a bani is loaded, paused included, so it is also the way back to
/// one that was left half-finished.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playbackStateProvider).value;
    final item = ref.watch(currentMediaItemProvider).value;

    // Nothing loaded, or stopped: the strip would be a dead control.
    if (item == null ||
        state == null ||
        state.processingState == AudioProcessingState.idle) {
      return const SizedBox.shrink();
    }

    final c = context.colors;
    final l = L.of(context);
    final elder = ref.watch(settingsProvider.select((s) => s.elderMode));
    final position = ref.watch(positionProvider).value ?? Duration.zero;
    final total = item.duration ?? Duration.zero;
    final playing = state.playing;
    final progress = total.inMilliseconds == 0
        ? 0.0
        : (position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);

    return Semantics(
      container: true,
      label: '${l.playerStillPlaying}. ${item.title}',
      child: Material(
        color: c.card,
        child: InkWell(
          onTap: () => context.push(Routes.reader(item.id)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // A hairline of progress, so the strip says how far in the paath
              // is without spending a row on it.
              Container(
                height: 2,
                color: c.rule,
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: progress == 0 ? 0.001 : progress,
                  child: Container(color: c.kesri),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(14, elder ? 10 : 8, 8, elder ? 10 : 8),
                child: Row(
                  children: [
                    _Round(
                      icon: playing ? HazriIconData.pause : HazriIconData.play,
                      tooltip: playing ? l.actionPause : l.actionResume,
                      elder: elder,
                      onTap: () {
                        final player = ref.read(paathPlayerProvider);
                        playing ? player?.pause() : player?.play();
                      },
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: HazriText.bodyStrong.copyWith(
                              fontSize: elder ? 17 : 15,
                              color: c.ink,
                            ),
                          ),
                          Text(
                            '${HazriDates.duration(position)} / ${HazriDates.duration(total)}',
                            maxLines: 1,
                            style: HazriText.caption.copyWith(
                              color: c.muted,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _Round(
                      icon: HazriIconData.close,
                      tooltip: l.actionStop,
                      elder: elder,
                      filled: false,
                      onTap: () => ref.read(paathPlayerProvider)?.stop(),
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

class _Round extends StatelessWidget {
  const _Round({
    required this.icon,
    required this.tooltip,
    required this.elder,
    required this.onTap,
    this.filled = true,
  });

  final String icon;
  final String tooltip;
  final bool elder;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // 48 dp of touch target, 64 in elder mode (PRD §11).
    final size = elder ? 64.0 : 48.0;
    return Semantics(
      button: true,
      label: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: size / 2,
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: Container(
              width: elder ? 48 : 36,
              height: elder ? 48 : 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled ? c.kesri : c.card2,
              ),
              child: Center(
                child: AppIcon(
                  icon,
                  size: elder ? 24 : 18,
                  color: filled ? c.onPrimary : c.ink2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
