import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/content_db.dart';
import '../../../core/db/content_repository.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/widgets/app_icon.dart';
import 'city_picker_sheet.dart';
import 'profile_icons.dart';

/// The outlined field with its label on the border (design 101): a 14 dp
/// radius, a grey outline that turns navy and thicker with focus.
InputDecoration outlinedFieldDecoration(BuildContext context, String label) {
  final c = context.colors;
  final error = Theme.of(context).colorScheme.error;
  final radius = BorderRadius.circular(14);
  OutlineInputBorder side(Color colour, double width) =>
      OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: colour, width: width));
  final outline = Color.alphaBlend(c.muted.withValues(alpha: 0.45), c.card);
  final labelStyle = HazriText.caption.copyWith(fontSize: 12.5, fontWeight: FontWeight.w700, color: c.ink2);
  return InputDecoration(
    labelText: label,
    floatingLabelBehavior: FloatingLabelBehavior.always,
    labelStyle: labelStyle,
    floatingLabelStyle: WidgetStateTextStyle.resolveWith((states) => labelStyle.copyWith(
          color: states.contains(WidgetState.error)
              ? error
              : states.contains(WidgetState.focused)
                  ? c.primary
                  : c.ink2,
        )),
    helperStyle: HazriText.caption.copyWith(fontSize: 12.5, color: c.ink2, height: 1.4),
    helperMaxLines: 3,
    errorMaxLines: 3,
    contentPadding: const EdgeInsets.fromLTRB(14, 16, 8, 16),
    border: side(outline, 1.5),
    enabledBorder: side(outline, 1.5),
    disabledBorder: side(outline.withValues(alpha: 0.5), 1.5),
    focusedBorder: side(c.primary, 2),
    errorBorder: side(error, 1.5),
    focusedErrorBorder: side(error, 2),
  );
}

/// The City field: a picker over the app's city list, never free text
/// (`01-accounts.md` §13 D9). [outlined] is Edit profile's style (design
/// 101), with a pin before the city and a search mark after it.
class CityField extends ConsumerWidget {
  const CityField({
    super.key,
    required this.cityId,
    required this.onChanged,
    this.errorText,
    this.enabled = true,
    this.label,
    this.outlined = false,
  });

  final String? cityId;
  final ValueChanged<String> onChanged;
  final String? errorText;
  final bool enabled;

  /// Defaults to `profileFieldCity`.
  final String? label;
  final bool outlined;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final cities = ref.watch(citiesProvider).value ?? const <CityRow>[];
    final city = cities.where((x) => x.id == cityId).firstOrNull;
    final text = label ?? l.profileFieldCity;

    final name = city == null ? null : cityName(city, lang);
    final value = name == null
        ? null
        : Text(
            name,
            style: HazriText.body.copyWith(color: c.ink, fontSize: 16),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );

    final decoration = outlined
        // The pin sits inside the value rather than as a prefix icon, so the
        // label on the border lines up with the Name field's.
        ? outlinedFieldDecoration(context, text).copyWith(
            errorText: errorText,
            enabled: enabled,
            suffixIcon: Padding(
              padding: const EdgeInsetsDirectional.only(end: 14),
              child: AppIcon(ProfileIcons.search, size: 18, color: c.ink2),
            ),
            suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          )
        : InputDecoration(
            labelText: text,
            errorText: errorText,
            enabled: enabled,
            suffixIcon: const Icon(Icons.arrow_drop_down),
          );

    return InkWell(
      borderRadius: outlined ? BorderRadius.circular(14) : null,
      onTap: !enabled
          ? null
          : () async {
              final picked = await showCityPickerSheet(context, selected: cityId);
              if (picked != null) onChanged(picked);
            },
      child: InputDecorator(
        decoration: decoration,
        isEmpty: city == null,
        child: !outlined
            ? value
            : Row(
                children: [
                  AppIcon(HazriIconData.pin, size: 19, color: c.primary),
                  const SizedBox(width: 10),
                  Expanded(child: value ?? const SizedBox.shrink()),
                ],
              ),
      ),
    );
  }
}
