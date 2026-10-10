import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/backend/api_exception.dart';
import '../../../core/db/content_db.dart';
import '../../../core/db/content_repository.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/time/clock.dart';
import '../../../core/time/date_format.dart';
import '../../../core/time/solar.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/surfaces.dart';
import '../../reminders/data/reminders_controller.dart';
import '../../settings/ui/screen_scaffold.dart';
import '../data/profile_api.dart';
import '../data/profile_controller.dart';
import '../domain/profile.dart';
import '../domain/validators.dart';
import 'change_email_dialog.dart';
import 'city_field.dart';
import 'city_picker_sheet.dart';
import 'messages.dart';
import 'profile_icons.dart';

/// Edit profile (`01-accounts.md` §13.8; design 101, owner 2026-10-10):
/// first what the chosen city means today, then name and city, and the
/// email with Change email on its own row; the phone is not editable.
class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  String? _cityId;
  bool _busy = false;
  String? _nameServerError;

  @override
  void initState() {
    super.initState();
    final p = ref.read(profileProvider);
    _name = TextEditingController(text: p?.name ?? '');
    _cityId = p?.cityId;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _changed {
    final p = ref.read(profileProvider);
    if (p == null) return false;
    return normalizeName(_name.text) != p.name || _cityId != p.cityId;
  }

  Future<void> _save() async {
    final l = L.of(context);
    final p = ref.read(profileProvider);
    if (p == null || !_form.currentState!.validate()) return;
    final name = normalizeName(_name.text);
    setState(() {
      _busy = true;
      _nameServerError = null;
    });
    try {
      final updated = await ref.read(profileApiProvider).update(
            name: name == p.name ? null : name,
            cityId: _cityId == p.cityId ? null : _cityId,
          );
      await ref.read(profileControllerProvider.notifier).setProfile(updated);
      // A new city moves the sunrise in the Amrit Vela message.
      ref.read(reminderSchedulerProvider).requestReschedule();
      if (!mounted) return;
      ProfileMessages.snack(context, l.profileUpdated);
      context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        if (e.code == 'VALIDATION_ERROR' && e.fields['name'] != null) {
          _nameServerError = ProfileMessages.serverField(l, e.fields['name']!);
        }
      });
      if (e.code == 'NO_PROFILE') {
        await ref.read(profileControllerProvider.notifier).markNone();
      } else if (e.code == 'NOTHING_CHANGED') {
        // P-3: the button is disabled for this; nothing to say.
      } else if (e.code != 'VALIDATION_ERROR') {
        ProfileMessages.snack(context, ProfileMessages.of(l, e));
      }
    } on NetworkException {
      if (!mounted) return;
      setState(() => _busy = false);
      ProfileMessages.snack(context, l.msgNetwork);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    final p = ref.watch(profileProvider);
    final help = HazriText.caption.copyWith(fontSize: 12.5, height: 1.4, color: c.ink2);

    return HazriScreen(
      title: l.profileEditTitle,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      footer: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: _busy
            ? const SizedBox(
                height: HazriSize.buttonMinHeight,
                child: Center(child: CircularProgressIndicator()),
              )
            : PrimaryButton(
                label: l.profileEditSave,
                icon: HazriIconData.check,
                onPressed: _changed ? _save : null,
              ),
      ),
      children: [
        if (_cityId != null) ...[
          _TodayInCity(cityId: _cityId!, savedCityId: p?.cityId),
          const SizedBox(height: 14),
        ],
        HazriCard(
          padding: const EdgeInsets.fromLTRB(14, 22, 14, 16),
          child: Form(
            key: _form,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _name,
                  enabled: !_busy,
                  textCapitalization: TextCapitalization.words,
                  style: HazriText.body.copyWith(fontSize: 16, color: c.ink),
                  decoration: outlinedFieldDecoration(context, l.profileRowName).copyWith(
                    helperText: l.profileEditNameHelp,
                    errorText: _nameServerError,
                  ),
                  onChanged: (_) => setState(() => _nameServerError = null),
                  validator: (v) {
                    final e = validateName(v ?? '');
                    return e == null ? null : ProfileMessages.field(l, e);
                  },
                ),
                const SizedBox(height: 20),
                CityField(
                  cityId: _cityId,
                  enabled: !_busy,
                  outlined: true,
                  label: l.profileRowCity,
                  onChanged: (id) => setState(() => _cityId = id),
                ),
                const SizedBox(height: 20),
                if (p != null) _EmailRow(profile: p, enabled: !_busy),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(l.profileEditEmailHelp, style: help),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The email on an outlined row: the address, a small green mark when it
/// is verified, and Change email inside the row (design 101). A pending
/// change is said quietly under the address.
class _EmailRow extends StatelessWidget {
  const _EmailRow({required this.profile, required this.enabled});

  final Profile profile;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    return InputDecorator(
      decoration: outlinedFieldDecoration(context, l.profileRowEmail).copyWith(
        enabled: enabled,
        contentPadding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  profile.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: HazriText.body.copyWith(fontSize: 15.5, color: c.ink),
                ),
                if (profile.pendingEmail != null)
                  Text(
                    l.profileEmailPending(profile.pendingEmail!),
                    style: HazriText.caption.copyWith(fontSize: 12, color: c.ink2),
                  ),
              ],
            ),
          ),
          if (profile.emailVerified) ...[
            const SizedBox(width: 6),
            Tooltip(
              message: l.profileVerified,
              child: AppIcon(ProfileIcons.verified, size: 18, color: c.sage, semanticLabel: l.profileVerified),
            ),
          ],
          const SizedBox(width: 8),
          Material(
            color: c.kesriSoft,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: enabled ? () => showChangeEmailDialog(context) : null,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Center(
                    widthFactor: 1,
                    child: Text(
                      l.profileChangeEmail,
                      style: HazriText.bodySmall.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: c.kesriInk,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Today in {city}": the chosen city's sunrise and sunset today, worked
/// out on the phone as Today does, and where the city was changed, what it
/// was (design 101).
class _TodayInCity extends ConsumerWidget {
  const _TodayInCity({required this.cityId, required this.savedCityId});

  final String cityId;
  final String? savedCityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final dates = HazriDates.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final cities = ref.watch(citiesProvider).value ?? const <CityRow>[];
    CityRow? find(String? id) => cities.where((x) => x.id == id).firstOrNull;
    final city = find(cityId);
    final was = savedCityId != null && savedCityId != cityId ? find(savedCityId) : null;
    final today = ref.watch(clockProvider).today();
    final sunrise = city == null ? null : SolarService.sunrise(today, city.lat, city.lon)?.toLocal();
    final sunset = city == null ? null : SolarService.sunset(today, city.lat, city.lon)?.toLocal();

    Widget tile(String icon, String label, DateTime? at, {required bool rise}) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: rise ? c.kesriSoft : c.card2,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              AppIcon(icon, size: 22, color: rise ? c.kesriInk : c.primary),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: HazriText.caption.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: rise ? c.kesriInk : c.ink2,
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        at == null ? '—' : dates.time(at),
                        style: HazriText.display22.copyWith(fontSize: 20, height: 1.1, color: c.ink),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

    return HazriCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                l.profileEditTodayIn(city == null ? cityId : cityName(city, lang)),
                style: HazriText.bodyStrong.copyWith(fontSize: 15, fontWeight: FontWeight.w700, color: c.ink),
              ),
              if (was != null)
                HazriChip(
                  label: l.profileEditChangedFrom(cityName(was, lang)),
                  background: c.kesriSoft,
                  foreground: c.kesriInk,
                  minHeight: 26,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: tile(ProfileIcons.sunrise, l.profileEditSunrise, sunrise, rise: true)),
              const SizedBox(width: 10),
              Expanded(child: tile(ProfileIcons.sunset, l.profileEditSunset, sunset, rise: false)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l.profileEditCityHelp,
            style: HazriText.caption.copyWith(fontSize: 12.5, height: 1.4, color: c.ink2),
          ),
        ],
      ),
    );
  }
}
