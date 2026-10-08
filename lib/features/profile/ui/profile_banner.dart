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
import '../data/profile_controller.dart';

/// "Set up your profile" (`01-accounts.md` §8.4, `05-today.md` T2): only in
/// ProfileNone or ProfileUnavailable; not dismissible; the whole banner opens
/// Profile Setup.
class ProfileBanner extends ConsumerWidget {
  const ProfileBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileControllerProvider);
    if (state is! ProfileNone && state is! ProfileUnavailable) return const SizedBox.shrink();
    final c = context.colors;
    final l = L.of(context);
    return HazriCard(
      onTap: () => context.push(Routes.profileSetup),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: c.kesriSoft, borderRadius: BorderRadius.circular(14)),
            alignment: Alignment.center,
            child: Icon(Icons.person, size: 22, color: c.kesriInk),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.profileBannerTitle, style: HazriText.bodyStrong.copyWith(color: c.ink)),
                const SizedBox(height: 2),
                Text(l.profileBannerSubtitle, style: HazriText.bodySmall.copyWith(color: c.ink2)),
              ],
            ),
          ),
          AppIcon(HazriIconData.chevronRight, size: 18, color: c.muted),
        ],
      ),
    );
  }
}

/// `Welcome, {name}` with a profile, else `Welcome` (§8.4).
String greeting(L l, ProfileState s) => s is ProfileLoaded ? l.profileWelcomeName(s.profile.name) : l.profileWelcome;
