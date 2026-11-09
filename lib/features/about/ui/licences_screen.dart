import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../settings/ui/settings_screen.dart' show appVersion;

/// The Gurbani text and its transliteration are MIT-licensed data, shipped in
/// content.db. About & credits no longer names them (owner, 2026-11-09), so
/// their notices are kept on this screen, which the MIT licence needs.
/// Called once, from main().
void registerDataLicences() {
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(const [
      'Shabad OS Database',
    ], await rootBundle.loadString('assets/licences/shabados-database.txt'));
    yield LicenseEntryWithLineBreaks(const [
      'gurmukhi-utils',
    ], await rootBundle.loadString('assets/licences/gurmukhi-utils.txt'));
  });
}

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
