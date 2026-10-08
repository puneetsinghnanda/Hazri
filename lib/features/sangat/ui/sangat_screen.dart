import 'package:flutter/material.dart';

import '../../../app/menu_sheet.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/widgets/surfaces.dart';
import '../../../core/widgets/tab_header.dart';

/// The Sangat tab while the Sangat is being rebuilt (PRD §11.4, steps 4–6).
///
/// The old Sangat wrote Firestore straight from the phone, which the
/// deny-all rules of step 4 refuse. Until the new one arrives in step 6 the
/// tab says the one true thing it can — the Sangat cannot be reached — and
/// nothing else in the app depends on it (rule 4: the Sangat is opt-in).
class SangatScreen extends StatelessWidget {
  const SangatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: ListView(
          children: [
            TabHeader(title: l.sangatTitle, onMenu: () => showMenuSheet(context)),
            Padding(
              padding: const EdgeInsets.all(HazriSize.gutter),
              child: HazriCard(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l.sangatUnavailable,
                  style: HazriText.body.copyWith(color: c.ink2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
