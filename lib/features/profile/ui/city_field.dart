import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/content_db.dart';
import '../../../core/db/content_repository.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import 'city_picker_sheet.dart';

/// The City field: a picker over the app's city list, never free text
/// (`01-accounts.md` §13 D9).
class CityField extends ConsumerWidget {
  const CityField({
    super.key,
    required this.cityId,
    required this.onChanged,
    this.errorText,
    this.enabled = true,
  });

  final String? cityId;
  final ValueChanged<String> onChanged;
  final String? errorText;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final cities = ref.watch(citiesProvider).value ?? const <CityRow>[];
    final city = cities.where((x) => x.id == cityId).firstOrNull;

    return InkWell(
      onTap: !enabled
          ? null
          : () async {
              final picked = await showCityPickerSheet(context, selected: cityId);
              if (picked != null) onChanged(picked);
            },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: l.profileFieldCity,
          errorText: errorText,
          enabled: enabled,
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        isEmpty: city == null,
        child: city == null
            ? null
            : Text(cityName(city, lang), style: HazriText.body.copyWith(color: c.ink)),
      ),
    );
  }
}
