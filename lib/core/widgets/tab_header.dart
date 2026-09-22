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
    // No side padding of its own. Every tab that carries this header lays it
    // out inside a ListView that already keeps the gutter, and the header
    // used to add the gutter again: the menu button and the tab's name sat
    // 40 dp in while the cards under them sat at 20, which is not where
    // design 30 puts them. The 22 dp above is design 30's own top padding.
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 6),
      child: Row(
        children: [
          CardIconButton(
            icon: HazriIconData.menu,
            tooltip: l.menuTooltip,
            onPressed: onMenu,
            size: 40,
            iconSize: 20,
            radius: 13,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: HazriText.display22
                      .copyWith(color: c.ink, fontSize: 24, height: 1.15),
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
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
