import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/time/date_format.dart';
import '../../../core/widgets/app_icon.dart';
import '../data/audio_controller.dart';
import 'sleep_timer_sheet.dart';

/// The player bar at the foot of the reader (Design 13).
class PlayerBar extends ConsumerWidget {
  const PlayerBar({super.key, required this.following, this.onBackToPaath});

  /// True when the bani on screen is the one playing.
  final bool following;
  final VoidCallback? onBackToPaath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final state = ref.watch(playbackStateProvider).value;
    final position = ref.watch(positionProvider).value ?? Duration.zero;
    final item = ref.watch(currentMediaItemProvider).value;
    final speed = ref.watch(settingsProvider.select((s) => s.speed));
    final controller = ref.read(playbackControllerProvider);

    final total = item?.duration ?? Duration.zero;
    final playing = state?.playing ?? false;
    final progress = total.inMilliseconds == 0
        ? 0.0
        : (position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(18, 12, 18, 12 + MediaQuery.viewPaddingOf(context).bottom),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF14162D).withValues(alpha: 0.10),
            blurRadius: 30,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (following)
                _Pill(
                  label: l.readerFollowingAudio,
                  background: c.sageSoft,
                  foreground: c.sage,
                  dot: c.sage,
                )
              else if (onBackToPaath != null)
                _Pill(
                  label: l.readerAutoScrollPaused,
                  background: c.card2,
                  foreground: c.ink2,
                  onTap: onBackToPaath,
                ),
              const SizedBox(width: 8),
              // Tapping flips between normal pace and 1.5x; the full set of
              // speeds is in the sleep/speed sheet.
              _Pill(
                label: '${speed.toStringAsFixed(speed == speed.roundToDouble() ? 1 : 2)}×',
                background: speed > 1.0 ? c.kesriSoft : c.card2,
                foreground: speed > 1.0 ? c.kesriInk : c.ink2,
                onTap: controller.toggleSpeed,
                onLongPress: () => showPlaybackOptionsSheet(context),
                semanticsLabel: l.playerSpeed,
              ),
              const Spacer(),
              Text(
                '${HazriDates.duration(position)} / ${HazriDates.duration(total)}',
                style: HazriText.caption.copyWith(
                  color: c.muted,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _Scrubber(
            progress: progress,
            onSeek: (fraction) => ref.read(audioHandlerProvider)?.seek(
              Duration(milliseconds: (total.inMilliseconds * fraction).round()),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Control(
                icon: HazriIconData.prev,
                tooltip: l.actionBack,
                onTap: (state?.queueIndex ?? 0) > 0
                    ? () => ref.read(audioHandlerProvider)?.skipToPrevious()
                    : null,
              ),
              _SeekControl(
                icon: HazriIconData.replay10,
                tooltip: '-10s',
                onTap: () => ref.read(audioHandlerProvider)?.rewind(),
              ),
              _PlayButton(playing: playing, onTap: controller.togglePlayPause),
              _SeekControl(
                icon: HazriIconData.forward10,
                tooltip: '+10s',
                onTap: () => ref.read(audioHandlerProvider)?.fastForward(),
              ),
              _Control(
                icon: HazriIconData.next,
                tooltip: l.actionNext,
                onTap: ref.read(audioHandlerProvider) != null &&
                        (ref.read(audioHandlerProvider)!.tracks.length > 1)
                    ? () => ref.read(audioHandlerProvider)?.skipToNext()
                    : null,
              ),
              _Control(
                icon: HazriIconData.clock,
                tooltip: l.playerSleepTimer,
                onTap: () => showPlaybackOptionsSheet(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.background,
    required this.foreground,
    this.dot,
    this.onTap,
    this.onLongPress,
    this.semanticsLabel,
  });

  final String label;
  final Color background;
  final Color foreground;
  final Color? dot;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final body = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(HazriRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot != null) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(label, style: HazriText.chip.copyWith(color: foreground)),
        ],
      ),
    );
    if (onTap == null) return body;
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(HazriRadius.chip),
        child: body,
      ),
    );
  }
}

/// The 4 dp seek bar from the design, with a 14 dp thumb.
class _Scrubber extends StatelessWidget {
  const _Scrubber({required this.progress, required this.onSeek});

  final double progress;
  final ValueChanged<double> onSeek;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return LayoutBuilder(
      builder: (context, constraints) {
        void seekTo(Offset local) =>
            onSeek((local.dx / constraints.maxWidth).clamp(0.0, 1.0));
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => seekTo(d.localPosition),
          onHorizontalDragUpdate: (d) => seekTo(d.localPosition),
          child: SizedBox(
            height: 20,
            child: Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 4,
                    width: constraints.maxWidth,
                    decoration: BoxDecoration(
                      color: c.rule,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Container(
                    height: 4,
                    width: constraints.maxWidth * progress,
                    decoration: BoxDecoration(
                      color: c.kesri,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Positioned(
                    left: constraints.maxWidth * progress - 7,
                    top: -5,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(color: c.kesri, shape: BoxShape.circle),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Control extends StatelessWidget {
  const _Control({required this.icon, required this.tooltip, required this.onTap});

  final String icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: AppIcon(icon, size: 22, color: onTap == null ? c.muted : c.ink),
          ),
        ),
      ),
    );
  }
}

class _SeekControl extends StatelessWidget {
  const _SeekControl({required this.icon, required this.tooltip, required this.onTap});

  final String icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(child: SeekIcon(icon, color: context.colors.ink)),
      ),
    ),
  );
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.playing, required this.onTap});

  final bool playing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    return Semantics(
      button: true,
      label: playing ? l.actionPause : l.actionStart,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle),
          child: Center(
            child: AppIcon(
              playing ? HazriIconData.pause : HazriIconData.play,
              size: 26,
              color: c.onPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
