import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/content_db.dart';
import '../../../core/db/content_repository.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/surfaces.dart';
import '../data/reminders_controller.dart';

/// The offline city picker (PRD 1.2). The list ships with the app, so this
/// works in airplane mode.
Future<void> showCityPickerSheet(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => const _CityPickerSheet(),
);

class _CityPickerSheet extends ConsumerStatefulWidget {
  const _CityPickerSheet();

  @override
  ConsumerState<_CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends ConsumerState<_CityPickerSheet> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _name(CityRow c, String lang) => switch (lang) {
    'pa' => c.namePa,
    'hi' => c.nameHi,
    _ => c.nameEn,
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final selected = ref.watch(settingsProvider).cityId;
    final all = ref.watch(citiesProvider).value ?? const <CityRow>[];

    final query = _search.text.trim().toLowerCase();
    final cities = query.isEmpty
        ? all
        : all
            .where((x) =>
                x.nameEn.toLowerCase().contains(query) ||
                x.namePa.contains(query) ||
                x.nameHi.contains(query) ||
                x.countryCode.toLowerCase() == query)
            .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(HazriSize.gutter, 12, HazriSize.gutter, 8),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.rule,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l.cityPickerTitle,
                        style: HazriText.display22.copyWith(color: c.ink),
                      ),
                    ),
                    CardIconButton(
                      icon: HazriIconData.close,
                      tooltip: l.actionClose,
                      background: c.card2,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  style: HazriText.body.copyWith(color: c.ink),
                  decoration: InputDecoration(
                    hintText: l.cityPickerSearch,
                    hintStyle: HazriText.body.copyWith(color: c.muted),
                    filled: true,
                    fillColor: c.card2,
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(12),
                      child: AppIcon(HazriIconData.eye, size: 20, color: c.muted),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(HazriRadius.button),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: cities.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        l.cityPickerNoResults,
                        textAlign: TextAlign.center,
                        style: HazriText.body.copyWith(color: c.muted),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: HazriSize.gutter),
                    itemCount: cities.length,
                    itemBuilder: (context, i) {
                      final city = cities[i];
                      final isSelected = city.id == selected;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          _name(city, lang),
                          style: HazriText.body.copyWith(
                            color: c.ink,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                        subtitle: Text(
                          city.countryCode,
                          style: HazriText.caption.copyWith(color: c.muted),
                        ),
                        trailing: isSelected
                            ? AppIcon(HazriIconData.check, size: 20, color: c.sage)
                            : null,
                        onTap: () async {
                          await ref.read(settingsProvider.notifier).setCityId(city.id);
                          ref.invalidate(sunLocationProvider);
                          await ref.read(reminderSchedulerProvider).reschedule();
                          if (context.mounted) Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              HazriSize.gutter,
              8,
              HazriSize.gutter,
              12 + MediaQuery.viewPaddingOf(context).bottom,
            ),
            child: Text(
              l.cityPickerNote,
              textAlign: TextAlign.center,
              style: HazriText.caption.copyWith(color: c.muted),
            ),
          ),
        ],
      ),
    );
  }
}
