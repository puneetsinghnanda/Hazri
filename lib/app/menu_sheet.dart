import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n/gen/app_localizations.dart';
import '../core/theme/hazri_colors.dart';
import '../core/theme/hazri_text.dart';
import '../core/theme/icon_data.dart';
import '../core/widgets/app_icon.dart';
import '../core/widgets/surfaces.dart';
import '../features/sangat/data/account_repository.dart';
import '../features/today/ui/help_sheet.dart';
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
    final account = ref.watch(sangatAccountProvider).value;

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
              // The account sits at the top, as design 37 has it, and is the
              // way in for somebody who has joined. For everybody else it is
              // the invitation, and it is the only sangat-shaped thing in
              // this sheet.
              HazriCard(
                colour: c.card2,
                onTap: () => go(account == null ? Routes.sangatJoin : Routes.account),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration:
                          BoxDecoration(color: c.kesriSoft, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: account == null
                          ? AppIcon(HazriIconData.sangat, size: 20, color: c.kesriInk)
                          : Text(
                              _initials(account.name),
                              style: HazriText.captionStrong.copyWith(color: c.kesriInk),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            account?.name.isNotEmpty == true
                                ? account!.name
                                : l.sangatSheetTitle,
                            style: HazriText.bodyStrong.copyWith(color: c.ink),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            account == null ? l.sangatBannerBody : account.city,
                            style: HazriText.caption.copyWith(color: c.muted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    AppIcon(HazriIconData.chevronRight, size: 18, color: c.muted),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              HazriCard(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
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

  static String _initials(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '';
    String first(String w) => String.fromCharCodes(w.runes.take(1));
    if (words.length == 1) return first(words.first).toUpperCase();
    return (first(words.first) + first(words.last)).toUpperCase();
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
