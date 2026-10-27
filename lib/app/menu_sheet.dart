import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n/gen/app_localizations.dart';
import '../core/theme/hazri_colors.dart';
import '../core/theme/hazri_text.dart';
import '../core/theme/icon_data.dart';
import '../core/widgets/app_icon.dart';
import '../features/today/ui/help_sheet.dart';
import '../core/db/content_db.dart';
import '../core/db/content_repository.dart';
import '../features/badges/data/badge_controller.dart';
import '../features/badges/ui/badge_widgets.dart';
import '../features/profile/data/profile_controller.dart';
import '../features/profile/ui/city_picker_sheet.dart';
import '../features/saakhi/data/saakhi_repository.dart';
import 'router.dart';

/// A question in a circle: the Gurmat Quiz's row in the menu.
const _quizIcon = '<circle cx="12" cy="12" r="9"/><path d="M9.6 9.4a2.5 2.5 0 1 1 3.4 2.4c-.6.3-1 .8-1 1.5v.5"/>'
    '<path d="M12 16.8v.2"/>';

/// A stack of pages: the saakhis' row in the menu.
const _saakhiIcon = '<rect x="4" y="3.5" width="12" height="17" rx="2"/>'
    '<path d="M16 6.5h2a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2h-8"/>';

/// What the menu button on every tab opens: a left drawer, option A of
/// 2026-10-25 (13-saakhi.md SK11, design 112), replacing the bottom sheet of
/// designs 37 and 99. The navy header (name, city, badges), then one list:
/// Today, Saakhis with a count, Library, Badges, then Notifications,
/// Settings, Privacy and data, About and credits, Help. Tap outside it,
/// swipe it left or press Back to close it.
Future<void> showMenuDrawer(BuildContext context) {
  // Read where we are from the tab that opened it: the drawer's own route is
  // not one of the router's, so it has no GoRouterState of its own.
  final location = GoRouter.maybeOf(context)?.routeInformationProvider.value.uri.path ?? '';
  return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, _, _) => _MenuDrawer(location: location),
      transitionBuilder: (_, animation, _, child) => SlideTransition(
        position: Tween(begin: const Offset(-1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );
}

class _MenuDrawer extends ConsumerWidget {
  const _MenuDrawer({required this.location});

  /// The path of the tab underneath, so Today can show as the one you are on.
  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final saakhis = ref.watch(saakhisProvider).value?.length ?? 0;
    final width = (MediaQuery.sizeOf(context).width * 0.82).clamp(0.0, 340.0);

    void go(String route) {
      Navigator.of(context).pop();
      context.push(route);
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onHorizontalDragEnd: (d) {
          if ((d.primaryVelocity ?? 0) < -200) Navigator.of(context).pop();
        },
        child: Material(
          color: c.card,
          borderRadius: const BorderRadius.horizontal(right: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: width,
            height: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _MenuHeader(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
                    children: [
                      _Row(
                        icon: HazriIconData.sunArc,
                        label: l.navToday,
                        selected: location == Routes.today,
                        onTap: () {
                          Navigator.of(context).pop();
                          if (location != Routes.today) context.go(Routes.today);
                        },
                      ),
                      _Row(
                        icon: _saakhiIcon,
                        label: l.saakhiTitle,
                        count: saakhis,
                        onTap: () => go(Routes.saakhis),
                      ),
                      // 14-quiz.md QZ33: after Saakhis.
                      _Row(icon: _quizIcon, label: l.quizTitle, onTap: () => go(Routes.quiz)),
                      _Row(icon: HazriIconData.book, label: l.libraryTitle, onTap: () => go(Routes.library)),
                      _Row(icon: HazriIconData.sparkle, label: l.badgesTitle, onTap: () => go(Routes.badges)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Divider(height: 1, color: c.rule),
                      ),
                      _Row(icon: HazriIconData.bell, label: l.notifTitle, onTap: () => go(Routes.notifications)),
                      _Row(icon: HazriIconData.sliders, label: l.settingsTitle, onTap: () => go(Routes.settings)),
                      _Row(icon: HazriIconData.lock, label: l.privacyDataTitle, onTap: () => go(Routes.privacy)),
                      _Row(icon: HazriIconData.book, label: l.settingsAboutCredits, onTap: () => go(Routes.about)),
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
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, required this.onTap, this.selected = false, this.count = 0});

  final String icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      selected: selected,
      child: Material(
        color: selected ? c.kesriSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  AppIcon(icon, size: 20, color: selected ? c.kesriInk : c.muted),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(label,
                        style: HazriText.bodyStrong.copyWith(
                          color: selected ? c.kesriInk : c.ink,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                        )),
                  ),
                  if (count > 0)
                    Container(
                      constraints: const BoxConstraints(minWidth: 22),
                      height: 22,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: c.kesri, borderRadius: BorderRadius.circular(11)),
                      child: Text('$count', style: HazriText.captionStrong.copyWith(color: Colors.white, fontSize: 12)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The navy header of design 112 (and 99's 5C before it): the avatar, the
/// name and city, then the badge count and the ten emblems. It opens the
/// profile, or the way to make one (01-accounts §8.7). Without a profile
/// there is no name or city, and the row of ten still shows.
class _MenuHeader extends ConsumerWidget {
  const _MenuHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final profile = ref.watch(profileProvider);
    final lang = Localizations.localeOf(context).languageCode;
    final cities = ref.watch(citiesProvider).value ?? const <CityRow>[];
    final city = profile == null ? null : cities.where((x) => x.id == profile.cityId).firstOrNull;
    final earned = (ref.watch(earnedBadgesProvider).value ?? const []).length;
    const white = Colors.white;

    return Material(
      color: dark ? c.card2 : const Color(0xFF262C63),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop();
          context.push(Routes.profile);
        },
        child: SafeArea(
          bottom: false,
          right: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: c.kesriSoft,
                      child: profile == null
                          ? AppIcon(HazriIconData.mail, size: 22, color: c.kesriInk)
                          : Text(profile.name.characters.first,
                              style: HazriText.bodyStrong.copyWith(color: c.kesriInk, fontSize: 20)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(profile?.name ?? l.profileBannerTitle,
                              style: HazriText.bodyStrong.copyWith(color: white, fontSize: 17)),
                          if (city != null)
                            Text(cityName(city, lang),
                                style: HazriText.caption.copyWith(color: white.withValues(alpha: 0.78))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Text(l.badgesTitle, style: HazriText.captionStrong.copyWith(color: white.withValues(alpha: 0.85))),
                    const Spacer(),
                    Text(l.badgesMenuCount(earned),
                        style: HazriText.caption.copyWith(color: white.withValues(alpha: 0.78))),
                  ],
                ),
                const SizedBox(height: 8),
                const BadgeRow10(size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
