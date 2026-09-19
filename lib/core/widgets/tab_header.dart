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
    return Padding(
      padding: const EdgeInsets.fromLTRB(HazriSize.gutter, 14, HazriSize.gutter, 6),
      child: Row(
        children: [
          CardIconButton(
            icon: HazriIconData.menu,
            tooltip: l.menuTooltip,
            onPressed: onMenu,
            size: 40,
            iconSize: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: HazriText.display22.copyWith(color: c.ink, fontSize: 24),
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
