import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router.dart';
import '../../../core/backend/api_exception.dart';
import '../../../core/db/content_db.dart';
import '../../../core/db/content_repository.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/app_mark.dart';
import '../../../core/widgets/surfaces.dart';
import '../../profile/data/profile_controller.dart';
import '../../profile/domain/validators.dart';
import '../../profile/ui/city_field.dart';
import '../../profile/ui/city_picker_sheet.dart';
import '../../profile/ui/messages.dart';
import '../../profile/ui/profile_setup_screen.dart';
import 'setup_screen.dart';

/// Step 3 of setup, the profile (03-first-run F10, design 130; owner
/// 2026-11-18, option C): your Hazri card at the top, filling in as you
/// type, then your name, your city and, if you like, your email. Create my
/// profile makes it, or with no connection keeps it to send at the next
/// start; Not now, in the header, ends setup without one.
class SetupProfileStep extends ConsumerStatefulWidget {
  const SetupProfileStep({super.key});

  @override
  ConsumerState<SetupProfileStep> createState() => _SetupProfileStepState();
}

class _SetupProfileStepState extends ConsumerState<SetupProfileStep> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  String? _cityId;
  String? _cityError;
  Map<String, String> _serverErrors = const {};
  bool _submitted = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _name.addListener(_redraw);
    _email.addListener(_redraw);
  }

  void _redraw() => setState(() {});

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final l = L.of(context);
    final known = {for (final CityRow c in ref.read(citiesProvider).value ?? const []) c.id};
    setState(() {
      _submitted = true;
      _serverErrors = const {};
      final e = validateCity(_cityId, known);
      _cityError = e == null ? null : ProfileMessages.field(l, e);
    });
    if (!_form.currentState!.validate() || _cityError != null) return;
    setState(() => _busy = true);
    final email = normalizeEmail(_email.text);
    try {
      final outcome = await ref.read(profileControllerProvider.notifier).create(
            name: normalizeName(_name.text),
            email: email.isEmpty ? null : email,
            cityId: _cityId!,
          );
      if (!mounted) return;
      switch (outcome) {
        case ProfileCreated():
          await finishSetup(context, ref, then: Routes.profileMade);
        case ProfileKept():
          ProfileMessages.snack(context, l.setupProfileKept);
          await finishSetup(context, ref);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      switch (e.code) {
        case 'VALIDATION_ERROR':
          setState(() {
            _serverErrors = {for (final f in e.fields.entries) f.key: ProfileMessages.serverField(l, f.value)};
            _cityError = _serverErrors['cityId'];
          });
          _form.currentState!.validate();
        case 'EMAIL_EXISTS':
          // Somebody who used Hazri before: offer to restore it (§8.8).
          // Setup counts as done first, or the router would send the Email
          // sent screen the restore opens back to the start of setup.
          await ref.read(settingsProvider.notifier).setOnboardingDone(true);
          if (mounted) await showEmailExistsDialog(context, email);
        case 'PROFILE_ALREADY_EXISTS':
          await ref.read(profileControllerProvider.notifier).refresh();
          if (mounted) await finishSetup(context, ref);
        default:
          ProfileMessages.snack(context, ProfileMessages.of(l, e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    String? fieldError(String key, FieldError? Function(String) check, String value) {
      final server = _serverErrors[key];
      if (server != null) return server;
      final e = check(value);
      return e == null ? null : ProfileMessages.field(l, e);
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(HazriSize.gutter, 8, HazriSize.gutter, 12),
            children: [
              Text(l.setupProfileTitle, style: HazriText.display26.copyWith(color: c.ink)),
              const SizedBox(height: 6),
              Text(l.setupProfileLead, style: HazriText.bodySmall.copyWith(color: c.ink2)),
              const SizedBox(height: 14),
              _CardPreview(name: _name.text.trim(), cityId: _cityId, email: _email.text.trim()),
              const SizedBox(height: 14),
              HazriCard(
                padding: const EdgeInsets.fromLTRB(14, 20, 14, 14),
                child: Form(
                  key: _form,
                  autovalidateMode: _submitted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _name,
                        enabled: !_busy,
                        textCapitalization: TextCapitalization.words,
                        decoration: outlinedFieldDecoration(context, l.profileRowName),
                        validator: (v) => fieldError('name', validateName, v ?? ''),
                      ),
                      const SizedBox(height: 18),
                      CityField(
                        cityId: _cityId,
                        enabled: !_busy,
                        outlined: true,
                        errorText: _cityError,
                        onChanged: (id) => setState(() {
                          _cityId = id;
                          _cityError = null;
                        }),
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _email,
                        enabled: !_busy,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        decoration: outlinedFieldDecoration(context, l.profileFieldEmail),
                        validator: (v) =>
                            normalizeEmail(v ?? '').isEmpty ? null : fieldError('email', validateEmail, v ?? ''),
                        onChanged: (_) => _serverErrors.containsKey('email')
                            ? setState(() => _serverErrors = {..._serverErrors}..remove('email'))
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(HazriSize.gutter, 8, HazriSize.gutter, 16),
          child: _busy
              ? const SizedBox(
                  height: 52,
                  child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4))),
                )
              : PrimaryButton(label: l.setupProfileCreate, onPressed: _create),
        ),
      ],
    );
  }
}

/// The navy identity card of the Profile screen (design 100), drawn from
/// what has been typed so far: "Your name", "Your city" and "Your email"
/// until each is filled.
class _CardPreview extends ConsumerWidget {
  const _CardPreview({required this.name, required this.cityId, required this.email});

  final String name;
  final String? cityId;
  final String email;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    const white = Colors.white;
    final cities = ref.watch(citiesProvider).value ?? const <CityRow>[];
    final city = cities.where((x) => x.id == cityId).firstOrNull;
    final line = HazriText.bodySmall.copyWith(color: white.withValues(alpha: 0.85));
    final empty = line.copyWith(color: white.withValues(alpha: 0.55));
    Widget row(String icon, String? text, String placeholder) => Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Row(
            children: [
              AppIcon(icon, size: 15, color: white.withValues(alpha: 0.8)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  text == null || text.isEmpty ? placeholder : text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text == null || text.isEmpty ? empty : line,
                ),
              ),
            ],
          ),
        );
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment(-0.5, -0.87),
            end: Alignment(0.5, 0.87),
            colors: [Color(0xFF2E3577), Color(0xFF262C63), Color(0xFF1A1E48)],
            stops: [0, 0.55, 1],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const AppMark(size: 22, arcColor: white, sunColor: Color(0xFFF2A24E)),
                  const SizedBox(width: 8),
                  Text(l.appBarTitle, style: HazriText.display22.copyWith(fontSize: 16, color: white)),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                name.isEmpty ? l.cardYourName : name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: HazriText.display22.copyWith(
                  fontSize: 26,
                  height: 1.1,
                  color: name.isEmpty ? white.withValues(alpha: 0.55) : white,
                ),
              ),
              row(HazriIconData.pin, city == null ? null : cityName(city, lang), l.cardYourCity),
              row(HazriIconData.mail, email, l.cardYourEmail),
            ],
          ),
        ),
      ),
    );
  }
}
