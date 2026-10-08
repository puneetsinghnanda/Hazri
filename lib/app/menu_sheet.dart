import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n/gen/app_localizations.dart';
import '../core/theme/hazri_colors.dart';
import '../core/theme/hazri_text.dart';
import '../core/theme/icon_data.dart';
import '../core/widgets/app_icon.dart';
import '../core/widgets/surfaces.dart';
import '../features/today/ui/help_sheet.dart';
import '../features/profile/data/profile_controller.dart';
import 'router.dart';

/// Design 37 — what the menu button opens.
///
/// Settings left the bottom nav when Sangat took its place, and this is where
/// it went. Everything that is not a daily habit lives here: the account,
/// reminders, the settings themselves, privacy and the credits.
Future<void> showMenuSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _MenuSheet(),
    );

class _MenuSheet extends ConsumerWidget {
  const _MenuSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);

    void go(String route) {
      Navigator.of(context).pop();
      context.push(route);
    }

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.rule,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              HazriCard(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // The profile, or the way to make one (01-accounts §8.7).
                    _Row(
                      icon: HazriIconData.mail,
                      label: switch (ref.watch(profileControllerProvider)) {
                        ProfileLoaded(:final profile) => profile.name,
                        _ => l.profileBannerTitle,
                      },
                      onTap: () => go(Routes.profile),
                    ),
                    Divider(height: 1, color: c.rule),
                    // Vichar is a section, not a setting, and it had no door
                    // at all: the only way in was a link at the bottom of the
                    // day's Vichar screen, which nobody would think to look
                    // behind. It goes first, above the settings.
                    _Row(
                      icon: HazriIconData.sparkle,
                      label: l.libraryTitle,
                      onTap: () => go(Routes.library),
                    ),
                    Divider(height: 1, color: c.rule),
                    _Row(
                      icon: HazriIconData.bell,
                      label: l.notifTitle,
                      onTap: () => go(Routes.notifications),
                    ),
                    Divider(height: 1, color: c.rule),
                    _Row(
                      icon: HazriIconData.sliders,
                      label: l.settingsTitle,
                      onTap: () => go(Routes.settings),
                    ),
                    Divider(height: 1, color: c.rule),
                    _Row(
                      icon: HazriIconData.lock,
                      label: l.privacyDataTitle,
                      onTap: () => go(Routes.privacy),
                    ),
                    Divider(height: 1, color: c.rule),
                    _Row(
                      icon: HazriIconData.book,
                      label: l.settingsAboutCredits,
                      onTap: () => go(Routes.about),
                    ),
                    Divider(height: 1, color: c.rule),
                    _Row(
                      icon: HazriIconData.help,
                      label: l.helpSheetTitle,
                      onTap: () {
                        Navigator.of(context).pop();
                        showHelpSheet(context);
                      },
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

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, required this.onTap});

  final String icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: c.card2,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: AppIcon(icon, size: 19, color: c.ink2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: HazriText.bodyStrong.copyWith(color: c.ink)),
            ),
            AppIcon(HazriIconData.chevronRight, size: 18, color: c.muted),
          ],
        ),
      ),
    );
  }
}
