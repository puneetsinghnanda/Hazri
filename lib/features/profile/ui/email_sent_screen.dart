import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/backend/api_exception.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/widgets/surfaces.dart';
import '../../settings/ui/screen_scaffold.dart';
import '../data/profile_api.dart';
import '../data/profile_controller.dart';
import '../domain/profile.dart';
import 'change_email_dialog.dart';
import 'messages.dart';

/// The arguments of `/email-sent` (ARCHITECTURE §2.4).
class EmailSentArgs {
  const EmailSentArgs(this.purpose, this.email, this.cooldownSeconds);

  final EmailPurpose purpose;
  final String email;
  final int cooldownSeconds;
}

/// Check your email (`01-accounts.md` §8.9).
class EmailSentScreen extends ConsumerStatefulWidget {
  const EmailSentScreen({super.key, required this.args});

  final EmailSentArgs args;

  @override
  ConsumerState<EmailSentScreen> createState() => _EmailSentScreenState();
}

class _EmailSentScreenState extends ConsumerState<EmailSentScreen> {
  Timer? _timer;
  int _left = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _countdown(widget.args.cooldownSeconds);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _countdown(int seconds) {
    _timer?.cancel();
    setState(() => _left = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _left = _left > 0 ? _left - 1 : 0);
      if (_left == 0) t.cancel();
    });
  }

  Future<void> _resend() async {
    final l = L.of(context);
    final api = ref.read(profileApiProvider);
    setState(() => _busy = true);
    try {
      final cooldown = widget.args.purpose == EmailPurpose.verifyEmail
          ? await api.sendVerification()
          : await api.requestRestore(widget.args.email);
      if (mounted) _countdown(cooldown);
    } on ApiException catch (e) {
      if (!mounted) return;
      final wait = e.retryAfterSeconds;
      if (e.code == 'RATE_LIMITED' && wait != null && wait <= 120) {
        _countdown(wait);
      } else {
        ProfileMessages.snack(context, ProfileMessages.of(l, e));
      }
    } on NetworkException {
      if (mounted) ProfileMessages.snack(context, l.msgNetwork);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    final verify = widget.args.purpose == EmailPurpose.verifyEmail;
    final state = ref.watch(profileControllerProvider);
    final canChange = verify && state is ProfileLoaded && !state.profile.emailVerified;

    return HazriScreen(
      title: l.emailSentTitle,
      children: [
        const SizedBox(height: 8),
        Text(
          verify ? l.emailSentVerify(widget.args.email) : l.emailSentRestore(widget.args.email),
          style: HazriText.body.copyWith(color: c.ink),
        ),
        if (canChange)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: () => showChangeEmailDialog(context, fromEmailSent: true),
              child: Text(l.emailSentWrongEmail),
            ),
          ),
        const SizedBox(height: 24),
        PrimaryButton(
          label: _left > 0 ? l.emailSentResendIn(_left) : l.emailSentResend,
          secondary: true,
          onPressed: _left > 0 || _busy ? null : _resend,
        ),
        const SizedBox(height: 12),
        PrimaryButton(label: l.emailSentBackHome, onPressed: () => context.go(Routes.today)),
      ],
    );
  }
}
