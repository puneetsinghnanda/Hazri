import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/backend/api_exception.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/surfaces.dart';
import '../data/profile_api.dart';
import '../data/profile_controller.dart';
import '../domain/profile.dart';
import 'email_sent_screen.dart';
import 'messages.dart';

/// "Welcome, {name}" (design 131, 03-first-run F10, 01-accounts §8.6 as
/// amended 2026-11-18): after a profile is made, at first run or from the
/// Profile banner. With an email, Confirm my email or Later; without one, a
/// line that an email can be added from the profile, and Go to Today.
class ProfileMadeScreen extends ConsumerStatefulWidget {
  const ProfileMadeScreen({super.key});

  @override
  ConsumerState<ProfileMadeScreen> createState() => _ProfileMadeScreenState();
}

class _ProfileMadeScreenState extends ConsumerState<ProfileMadeScreen> {
  bool _busy = false;

  void _today() => context.go(Routes.today);

  Future<void> _confirm(Profile p) async {
    final l = L.of(context);
    final router = GoRouter.of(context);
    setState(() => _busy = true);
    try {
      final cooldown = await ref.read(profileApiProvider).sendVerification();
      if (!mounted) return;
      router.go(Routes.today);
      router.push(Routes.emailSent, extra: EmailSentArgs(EmailPurpose.verifyEmail, p.email ?? '', cooldown));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      if (e.code == 'EMAIL_ALREADY_VERIFIED') {
        await ref.read(profileControllerProvider.notifier).refresh();
        if (mounted) _today();
      } else if (e.code == 'RATE_LIMITED') {
        ProfileMessages.snack(context, ProfileMessages.of(l, e));
      } else {
        ProfileMessages.snack(context, e.code == 'EMAIL_NOT_CONFIGURED' ? l.msgEmailNotConfigured : l.profileSendFailed);
        _today();
      }
    } on NetworkException {
      if (!mounted) return;
      ProfileMessages.snack(context, l.profileSendFailed);
      _today();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    final p = ref.watch(profileProvider);
    final email = p?.email;
    final first = (p?.name ?? '').split(' ').first;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: PhoneWidth(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(HazriSize.gutter, 24, HazriSize.gutter, 16),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(color: c.sageSoft, shape: BoxShape.circle),
                  child: Center(child: AppIcon(HazriIconData.check, size: 40, color: c.sage)),
                ),
                const SizedBox(height: 18),
                Text(
                  l.profileMadeTitle(first),
                  textAlign: TextAlign.center,
                  style: HazriText.display26.copyWith(color: c.ink),
                ),
                const SizedBox(height: 8),
                Text(
                  email == null ? l.profileMadeNoEmailBody : l.profileMadeConfirmBody(email),
                  textAlign: TextAlign.center,
                  style: HazriText.body.copyWith(color: c.ink2),
                ),
                const Spacer(),
                if (email != null && p != null && !p.emailVerified) ...[
                  _busy
                      ? const SizedBox(
                          height: 52,
                          child: Center(
                            child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4)),
                          ),
                        )
                      : PrimaryButton(label: l.profileConfirmEmail, icon: HazriIconData.mail, onPressed: () => _confirm(p)),
                  const SizedBox(height: 10),
                  PrimaryButton(label: l.profileMadeLater, secondary: true, onPressed: _busy ? null : _today),
                ] else
                  PrimaryButton(label: l.profileMadeToday, onPressed: _today),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
