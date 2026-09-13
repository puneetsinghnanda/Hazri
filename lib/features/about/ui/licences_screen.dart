import 'package:flutter/material.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../settings/ui/settings_screen.dart' show appVersion;

/// Open-source licences, using Flutter's own licence registry so every bundled
/// package and font is listed.
class LicencesScreen extends StatelessWidget {
  const LicencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);

    return Theme(
      data: Theme.of(context),
      child: LicensePage(
        applicationName: l.appName,
        applicationVersion: appVersion,
        applicationLegalese: l.aboutFontsBody,
        applicationIcon: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            l.appNameNative,
            style: HazriText.display22.copyWith(color: c.ink),
          ),
        ),
      ),
    );
  }
}
