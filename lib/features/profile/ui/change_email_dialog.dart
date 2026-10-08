import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/backend/api_exception.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../data/profile_api.dart';
import '../data/profile_controller.dart';
import '../domain/profile.dart';
import '../domain/validators.dart';
import 'email_sent_screen.dart';
import 'messages.dart';

/// Change email (`01-accounts.md` §8.11, §13.8). Not dismissible by tapping
/// outside. [fromEmailSent]: opened on the Email Sent screen, which the new
/// one replaces rather than stacks on.
Future<void> showChangeEmailDialog(BuildContext context, {bool fromEmailSent = false}) =>
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ChangeEmailDialog(fromEmailSent: fromEmailSent),
    );

class _ChangeEmailDialog extends ConsumerStatefulWidget {
  const _ChangeEmailDialog({required this.fromEmailSent});

  final bool fromEmailSent;

  @override
  ConsumerState<_ChangeEmailDialog> createState() => _ChangeEmailDialogState();
}

class _ChangeEmailDialogState extends ConsumerState<_ChangeEmailDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _email;
  bool _busy = false;
  String? _error;

  Profile? get _profile => ref.read(profileProvider);

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: _profile?.email ?? '');
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = L.of(context);
    final router = GoRouter.of(context);
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    final value = normalizeEmail(_email.text);
    final current = _profile;
    if (current != null && emailKey(value) == emailKey(current.email)) {
      setState(() => _error = l.changeEmailSame);
      return;
    }
    setState(() => _busy = true);
    final controller = ref.read(profileControllerProvider.notifier);
    try {
      final r = await ref.read(profileApiProvider).changeEmail(value);
      await controller.setProfile(r.profile);
      nav.pop();
      // EMAIL_CHANGE_PENDING (§13.8): the link went to the new address.
      final args = EmailSentArgs(EmailPurpose.verifyEmail, value, r.cooldownSeconds);
      if (widget.fromEmailSent) {
        router.pushReplacement(Routes.emailSent, extra: args);
      } else {
        router.push(Routes.emailSent, extra: args);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      switch (e.code) {
        case 'VALIDATION_ERROR':
          setState(() {
            _busy = false;
            _error = ProfileMessages.serverField(l, e.fields['email'] ?? e.message);
          });
        case 'EMAIL_UNCHANGED':
          await controller.refresh();
          setState(() {
            _busy = false;
            _error = l.changeEmailSame;
          });
        case 'EMAIL_EXISTS':
          setState(() {
            _busy = false;
            _error = l.changeEmailExists;
          });
        case 'EMAIL_ALREADY_VERIFIED':
          nav.pop();
          await controller.refresh();
          messenger.showSnackBar(SnackBar(content: Text(l.changeEmailAlreadyVerified)));
        case 'NO_PROFILE':
          nav.pop();
          await controller.markNone();
          router.go(Routes.today);
        default:
          setState(() => _busy = false);
          messenger.showSnackBar(SnackBar(content: Text(ProfileMessages.of(l, e))));
      }
    } on NetworkException {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(content: Text(l.msgNetwork)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return AlertDialog(
      title: Text(l.changeEmailTitle),
      content: Form(
        key: _form,
        child: TextFormField(
          controller: _email,
          enabled: !_busy,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: l.changeEmailField,
            helperText: l.changeEmailHelper,
            helperMaxLines: 3,
            errorText: _error,
            errorMaxLines: 3,
          ),
          validator: (v) {
            final e = validateEmail(v ?? '');
            return e == null ? null : ProfileMessages.field(l, e);
          },
        ),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.of(context).pop(), child: Text(l.actionCancel)),
        _busy
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              )
            : TextButton(onPressed: _save, child: Text(l.changeEmailSave)),
      ],
    );
  }
}
