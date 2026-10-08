import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/backend/api_exception.dart';
import '../../../core/db/content_db.dart';
import '../../../core/db/content_repository.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/widgets/surfaces.dart';
import '../../settings/ui/screen_scaffold.dart';
import '../data/profile_api.dart';
import '../data/profile_controller.dart';
import '../domain/profile.dart';
import '../domain/validators.dart';
import 'city_field.dart';
import 'email_sent_screen.dart';
import 'messages.dart';

/// Profile Setup (`01-accounts.md` §8.5): Name, Email, Phone, City and Save
/// Profile.
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  String? _cityId;
  bool _submitted = false;
  bool _busy = false;

  /// Errors from a `400 VALIDATION_ERROR`, shown under their fields.
  Map<String, String> _serverErrors = const {};
  String? _cityError;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = L.of(context);
    final known = {for (final CityRow c in ref.read(citiesProvider).value ?? const []) c.id};
    setState(() {
      _submitted = true;
      _serverErrors = const {};
      final e = validateCity(_cityId, known);
      _cityError = e == null ? null : ProfileMessages.field(l, e);
    });
    final ok = _form.currentState!.validate();
    if (!ok || _cityError != null) return;

    setState(() => _busy = true);
    try {
      final p = await ref.read(profileApiProvider).create(
            name: normalizeName(_name.text),
            email: normalizeEmail(_email.text),
            phone: normalizePhone(_phone.text),
            cityId: _cityId!,
          );
      await ref.read(profileControllerProvider.notifier).setProfile(p);
      if (mounted) await showProfileSavedDialog(context, p);
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
          await _showEmailExists(normalizeEmail(_email.text));
        case 'PROFILE_ALREADY_EXISTS':
          await ref.read(profileControllerProvider.notifier).refresh();
          if (mounted) context.pushReplacement(Routes.profile);
        default:
          ProfileMessages.snack(context, ProfileMessages.of(l, e));
      }
    } on NetworkException {
      if (!mounted) return;
      setState(() => _busy = false);
      ProfileMessages.snack(context, l.msgNetwork);
    }
  }

  Future<void> _showEmailExists(String email) => showDialog<void>(
        context: context,
        builder: (_) => _EmailExistsDialog(email: email),
      );

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    String? fieldError(String key, FieldError? Function(String) check, String value) {
      final server = _serverErrors[key];
      if (server != null) return server;
      final e = check(value);
      return e == null ? null : ProfileMessages.field(l, e);
    }

    return HazriScreen(
      title: l.profileSetupTitle,
      children: [
        Form(
          key: _form,
          autovalidateMode: _submitted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _name,
                enabled: !_busy,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: l.profileFieldName),
                validator: (v) => fieldError('name', validateName, v ?? ''),
                onChanged: (_) => _serverErrors.containsKey('name')
                    ? setState(() => _serverErrors = {..._serverErrors}..remove('name'))
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                enabled: !_busy,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: InputDecoration(labelText: l.profileFieldEmail),
                validator: (v) => fieldError('email', validateEmail, v ?? ''),
                onChanged: (_) => _serverErrors.containsKey('email')
                    ? setState(() => _serverErrors = {..._serverErrors}..remove('email'))
                    : null,
              ),
              const SizedBox(height: 12),
              // No prefix, no formatter, no limit (§13 D2).
              TextFormField(
                controller: _phone,
                enabled: !_busy,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: l.profileFieldPhone),
              ),
              const SizedBox(height: 12),
              CityField(
                cityId: _cityId,
                enabled: !_busy,
                errorText: _cityError,
                onChanged: (id) => setState(() {
                  _cityId = id;
                  _cityError = null;
                }),
              ),
              const SizedBox(height: 24),
              _BusyButton(label: l.profileSave, busy: _busy, onPressed: _save),
            ],
          ),
        ),
      ],
    );
  }
}

/// A full-width button that shows a small spinner while [busy].
class _BusyButton extends StatelessWidget {
  const _BusyButton({required this.label, required this.busy, required this.onPressed});

  final String label;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => busy
      ? const SizedBox(
          height: 52,
          child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4))),
        )
      : PrimaryButton(label: label, onPressed: onPressed);
}

/// §8.6. Not dismissible by tapping outside.
Future<void> showProfileSavedDialog(BuildContext context, Profile p) => showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ProfileSavedDialog(profile: p),
    );

class _ProfileSavedDialog extends ConsumerStatefulWidget {
  const _ProfileSavedDialog({required this.profile});

  final Profile profile;

  @override
  ConsumerState<_ProfileSavedDialog> createState() => _ProfileSavedDialogState();
}

class _ProfileSavedDialogState extends ConsumerState<_ProfileSavedDialog> {
  bool _busy = false;

  late final GoRouter _router = GoRouter.of(context);

  void _home() {
    Navigator.of(context).pop();
    _router.go(Routes.today);
  }

  Future<void> _confirm() async {
    final l = L.of(context);
    final router = _router;
    setState(() => _busy = true);
    try {
      final cooldown = await ref.read(profileApiProvider).sendVerification();
      if (!mounted) return;
      Navigator.of(context).pop();
      router.pushReplacement(
        Routes.emailSent,
        extra: EmailSentArgs(EmailPurpose.verifyEmail, widget.profile.email, cooldown),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == 'EMAIL_ALREADY_VERIFIED') {
        await ref.read(profileControllerProvider.notifier).refresh();
        if (mounted) _home();
      } else if (e.code == 'RATE_LIMITED') {
        setState(() => _busy = false);
        ProfileMessages.snack(context, ProfileMessages.of(l, e));
      } else {
        ProfileMessages.snack(context, e.code == 'EMAIL_NOT_CONFIGURED' ? l.msgEmailNotConfigured : l.profileSendFailed);
        _home();
      }
    } on NetworkException {
      if (!mounted) return;
      ProfileMessages.snack(context, l.profileSendFailed);
      _home();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return AlertDialog(
      title: Text(l.profileSavedTitle),
      content: Text(l.profileSavedBody(widget.profile.email)),
      actions: [
        TextButton(onPressed: _busy ? null : _home, child: Text(l.profileSkipForNow)),
        _busy
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              )
            : TextButton(onPressed: _confirm, child: Text(l.profileConfirmEmail)),
      ],
    );
  }
}

/// §8.8: the email belongs to a profile; offer to restore it here.
class _EmailExistsDialog extends ConsumerStatefulWidget {
  const _EmailExistsDialog({required this.email});

  final String email;

  @override
  ConsumerState<_EmailExistsDialog> createState() => _EmailExistsDialogState();
}

class _EmailExistsDialogState extends ConsumerState<_EmailExistsDialog> {
  bool _busy = false;

  Future<void> _send() async {
    final l = L.of(context);
    final router = GoRouter.of(context);
    setState(() => _busy = true);
    try {
      final cooldown = await ref.read(profileApiProvider).requestRestore(widget.email);
      if (!mounted) return;
      Navigator.of(context).pop();
      router.pushReplacement(
        Routes.emailSent,
        extra: EmailSentArgs(EmailPurpose.restoreProfile, widget.email, cooldown),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      switch (e.code) {
        case 'EMAIL_NOT_FOUND':
          Navigator.of(context).pop();
          ProfileMessages.snack(context, l.profileEmailNotFound);
        case 'DEVICE_HAS_PROFILE':
          Navigator.of(context).pop();
          await ref.read(profileControllerProvider.notifier).refresh();
          router.pushReplacement(Routes.profile);
        default:
          setState(() => _busy = false);
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
    final l = L.of(context);
    return AlertDialog(
      title: Text(l.profileEmailExistsTitle),
      content: Text(l.profileEmailExistsBody(widget.email)),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.of(context).pop(), child: Text(l.actionCancel)),
        _busy
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              )
            : TextButton(onPressed: _send, child: Text(l.profileSendLink)),
      ],
    );
  }
}
