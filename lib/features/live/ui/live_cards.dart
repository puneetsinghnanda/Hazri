import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/db/content_repository.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../data/live_controller.dart';
import '../domain/live_group.dart';
import 'live_scene.dart';

/// A live group on Discover (LS4, design 125, option B): its scene, LIVE, the
/// kind and name, how many are listening, and Join or Joined. Tapping it
/// opens the group, where joining happens.
class LiveCard extends ConsumerWidget {
  const LiveCard({super.key, required this.def, required this.status, this.waiting = false});

  final LiveGroupDef def;
  final LiveGroupStatus status;
  final bool waiting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final listening = _shownListening(ref, status);
    final name = def.nameFor(Localizations.localeOf(context).languageCode);
    const white = Colors.white;
    return Semantics(
      button: true,
      label: '${l.liveTag}, $name, ${waiting ? l.liveWaiting : l.liveListening(listening)}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => context.push(Routes.live(def.id)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              LiveSceneView(
                scene: def.scene,
                compact: true,
                word: switch (def.scene) {
                  LiveScene.globe => l.simranWaheguru,
                  LiveScene.ikonkar => ref.watch(ikOnkarProvider).value ?? '',
                  LiveScene.jot => '',
                },
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0x00000000), Color(0xCC000000)],
                    stops: [0, 0.45, 1],
                  ),
                ),
              ),
              const Positioned(left: 8, top: 8, child: LiveTagPill(small: true)),
              Positioned(
                left: 10,
                right: 8,
                bottom: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (def.kind == LiveKind.jaap ? l.liveKindJaap : l.liveKindMeditation).toUpperCase(),
                      maxLines: 1,
                      style: HazriText.eyebrow.copyWith(color: const Color(0xFFF2C27A), fontSize: 9),
                    ),
                    Text(
                      name,
                      maxLines: 2,
                      style: HazriText.bodyStrong.copyWith(color: white, height: 1.15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      waiting ? l.liveWaiting : l.liveListening(listening),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: HazriText.caption.copyWith(color: white.withValues(alpha: 0.8), fontSize: 11),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: status.joined ? const Color(0xFF2E7D5B) : const Color(0xFFF2A24E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status.joined ? l.liveJoined : l.liveJoin,
                        style: HazriText.captionStrong.copyWith(
                          color: status.joined ? white : const Color(0xFF2A1606),
                          fontSize: 11,
                        ),
                      ),
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

/// A live group you are in, on My groups (LS4a, design 126): how many are
/// listening, your minutes today and Listen.
class LiveRow extends ConsumerWidget {
  const LiveRow({
    super.key,
    required this.def,
    required this.status,
    required this.minutesToday,
    this.waiting = false,
  });

  final LiveGroupDef def;
  final LiveGroupStatus status;
  final int minutesToday;
  final bool waiting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final listening = _shownListening(ref, status);
    final name = def.nameFor(Localizations.localeOf(context).languageCode);
    return InkWell(
      onTap: () => context.push(Routes.live(def.id)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: [
            SizedBox(
              width: 52,
              height: 52,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LiveSceneView(scene: def.scene, compact: true, animate: false),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const LiveTagPill(small: true),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          waiting ? l.liveWaiting : l.liveListening(listening),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: HazriText.caption.copyWith(color: c.ink2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(name, style: HazriText.bodyStrong.copyWith(color: c.ink)),
                  Text(l.liveYouListened(minutesToday), style: HazriText.caption.copyWith(color: c.muted)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => context.push(Routes.live(def.id)),
              style: FilledButton.styleFrom(backgroundColor: c.primary, foregroundColor: c.onPrimary),
              child: Text(l.liveListen),
            ),
          ],
        ),
      ),
    );
  }
}

/// The count with you in it for a day after you listened (LS7b).
int _shownListening(WidgetRef ref, LiveGroupStatus status) => liveShown(
      status,
      heardAt: ref.watch(liveHeardProvider)[status.id],
      now: DateTime.now(),
    ).listening;

/// The red LIVE tag.
class LiveTagPill extends StatelessWidget {
  const LiveTagPill({super.key, this.small = false});

  final bool small;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(horizontal: small ? 6 : 8, vertical: small ? 2 : 3),
        decoration: BoxDecoration(color: const Color(0xFFE5484D), borderRadius: BorderRadius.circular(6)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: small ? 5 : 6,
              height: small ? 5 : 6,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            ),
            SizedBox(width: small ? 4 : 5),
            Text(
              L.of(context).liveTag,
              style: HazriText.captionStrong.copyWith(
                color: Colors.white,
                letterSpacing: 0.8,
                fontSize: small ? 10 : null,
              ),
            ),
          ],
        ),
      );
}
