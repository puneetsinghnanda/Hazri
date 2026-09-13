import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n/gen/app_localizations.dart';
import '../core/settings/settings_controller.dart';
import '../core/theme/hazri_colors.dart';
import '../core/theme/hazri_text.dart';
import '../core/theme/icon_data.dart';
import '../core/widgets/app_icon.dart';
import '../features/audio/ui/mini_player.dart';

/// The five tabs, in branch order.
enum HomeTab { today, nitnem, simran, diary, settings }

/// The bottom-navigation shell.
///
/// Elder mode shows three tabs rather than five (PRD 1.12); the hidden tabs
/// stay routable, so Simran and the Diary are still reachable from Today and
/// Settings.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const _elderTabs = [HomeTab.today, HomeTab.nitnem, HomeTab.settings];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elder = ref.watch(settingsProvider).elderMode;
    final tabs = elder ? _elderTabs : HomeTab.values;
    final c = context.colors;

    final onToday = shell.currentIndex == HomeTab.today.index;

    // Back always returns to Today first, and only leaves the app from there,
    // so the hardware button never drops someone out of the app mid-Nitnem.
    return PopScope(
      canPop: onToday,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        shell.goBranch(HomeTab.today.index);
      },
      child: Scaffold(
        backgroundColor: c.bg,
        body: shell,
        // The mini player rides above the nav rather than floating over the
        // page, so nothing it covers is content.
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MiniPlayer(),
            _BottomNav(
              tabs: tabs,
              currentIndex: shell.currentIndex,
              elder: elder,
              onSelect: (tab) => shell.goBranch(
                tab.index,
                initialLocation: tab.index == shell.currentIndex,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.tabs,
    required this.currentIndex,
    required this.elder,
    required this.onSelect,
  });

  final List<HomeTab> tabs;
  final int currentIndex;
  final bool elder;
  final ValueChanged<HomeTab> onSelect;

  static String _icon(HomeTab tab) => switch (tab) {
    HomeTab.today => HazriIconData.sunArc,
    HomeTab.nitnem => HazriIconData.book,
    HomeTab.simran => HazriIconData.simranDots,
    HomeTab.diary => HazriIconData.calendar,
    HomeTab.settings => HazriIconData.sliders,
  };

  static String _label(L l, HomeTab tab) => switch (tab) {
    HomeTab.today => l.navToday,
    HomeTab.nitnem => l.navNitnem,
    HomeTab.simran => l.navSimran,
    HomeTab.diary => l.navDiary,
    HomeTab.settings => l.navSettings,
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.card,
        border: Border(top: BorderSide(color: c.rule)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(4, 10, 4, 10 + (bottomInset > 0 ? bottomInset : 12)),
        child: Row(
          children: [
            for (final tab in tabs)
              Expanded(
                child: _NavItem(
                  icon: _icon(tab),
                  label: _label(l, tab),
                  selected: currentIndex == tab.index,
                  elder: elder,
                  onTap: () => onSelect(tab),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.elder,
    required this.onTap,
  });

  final String icon;
  final String label;
  final bool selected;
  final bool elder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = selected ? c.kesriInk : c.muted;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HazriRadius.navPill),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: elder ? 72 : HazriSize.navPill.width,
                height: elder ? 40 : HazriSize.navPill.height,
                decoration: BoxDecoration(
                  color: selected ? c.kesriSoft : Colors.transparent,
                  borderRadius: BorderRadius.circular(HazriRadius.navPill),
                ),
                child: Center(child: AppIcon(icon, size: elder ? 26 : 22, color: fg)),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: HazriText.navLabel.copyWith(
                  fontSize: elder ? 14 : 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? c.ink : c.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
