import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../theme/hazri_colors.dart';
import '../theme/hazri_text.dart';
import '../theme/icon_data.dart';
import 'app_mark.dart';
import 'surfaces.dart';

/// The app's name and mark, above every tab.
///
/// It sits in the shell rather than in each screen, so the brand is in one
/// place and Today does not repeat it as a heading of its own.
class BrandBar extends StatelessWidget {
  const BrandBar({super.key, this.onHelp});

  final VoidCallback? onHelp;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(HazriSize.gutter, 14, HazriSize.gutter, 6),
      child: Row(
        children: [
          const AppMark(size: 30),
          const SizedBox(width: 10),
          Expanded(
            child: Text(l.appName, style: HazriText.brand.copyWith(color: c.ink)),
          ),
          if (onHelp != null)
            CardIconButton(
              icon: HazriIconData.help,
              tooltip: l.helpSheetTitle,
              onPressed: onHelp!,
            ),
        ],
      ),
    );
  }
}
