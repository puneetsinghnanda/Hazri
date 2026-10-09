import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../theme/hazri_colors.dart';
import '../theme/hazri_text.dart';
import '../theme/icon_data.dart';
import 'surfaces.dart';

/// The top of every tab: the menu button, the tab's name and a line under it.
///
/// This replaced the brand bar. The app's name and mark belonged on the
/// splash and on About; carrying them above every screen spent the top of the
/// page on something the reader already knew and made Today look like it was
/// still starting up. Every Phase 2 design puts the screen's own name there
/// instead, with the menu beside it.
class TabHeader extends StatelessWidget {
  const TabHeader({
    super.key,
    required this.title,
    this.subtitle,
    required this.onMenu,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final VoidCallback onMenu;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    // No side padding: every tab's list already gutters its content, and a
    // second gutter here put the menu 40 dp in, where Today's is 20. The menu
    // is Today's size and height too (05-today T11), so it does not move
    // between tabs.
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 6),
      child: Row(
        // The menu holds its place whether or not there is a subtitle; the
        // title centres on it.
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardIconButton(
            icon: HazriIconData.menu,
            tooltip: l.menuTooltip,
            onPressed: onMenu,
            size: 44,
            iconSize: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: HazriText.display22.copyWith(
                      color: c.ink,
                      fontSize: 24,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: HazriText.caption.copyWith(color: c.muted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
