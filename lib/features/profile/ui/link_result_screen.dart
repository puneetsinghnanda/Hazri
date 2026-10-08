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
import '../../backup/ui/backup_section.dart';
import 'email_sent_screen.dart';
import 'messages.dart';

/// What a tapped link came to (`01-accounts.md` §8.9). The success message is
/// shown only after the server answered 200, which it does only once the
/// write committed (Req 5).
class LinkResultScreen extends ConsumerStatefulWidget {
  const LinkResultScreen({super.key, required this.token});

  final String token;

  @override
  ConsumerState<LinkResultScreen> createState() => _LinkResultScreenState();
}

enum _Button { home, sendNew, tryAgain, retry, restoreData }

class _Outcome {
  const _Outcome(this.title, this.message, this.buttons);

  final String title;
  final String message;
  final List<_Button> buttons;
}

class _LinkResultScreenState extends ConsumerState<LinkResultScreen> {
  _Outcome? _outcome;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  Future<void> _check() async {
    final l = L.of(context);
    final controller = ref.read(profileControllerProvider.notifier);
    setState(() => _outcome = null);
    _Outcome out;
    try {
      final r = await ref.read(profileApiProvider).verifyToken(widget.token);
      if (r.profile != null) await controller.setProfile(r.profile!);
      out = switch (r.result) {
        // 10-backup §8.3: the data restore is offered straight away.
        'PROFILE_RESTORED' => _Outcome(l.linkRestoredTitle, l.linkRestored(r.profile?.name ?? ''),
            const [_Button.restoreData, _Button.home]),
        'EMAIL_ALREADY_VERIFIED' =>
          _Outcome(l.linkEmailVerifiedTitle, l.linkEmailAlreadyVerified, const [_Button.home]),
        'EMAIL_CHANGED' => _Outcome(l.linkEmailVerifiedTitle, l.linkEmailChanged, const [_Button.home]),
        _ => _Outcome(l.linkEmailVerifiedTitle, l.linkEmailVerified, const [_Button.home]),
      };
    } on ApiException catch (e) {
      final rule = _buttonsFor(e.purpose);
      switch (e.code) {
        case 'TOKEN_EXPIRED':
          out = _Outcome(l.linkExpiredTitle, l.linkExpired, rule);
        case 'TOKEN_INVALID':
          out = _Outcome(l.linkInvalidTitle, l.linkInvalid, rule);
        case 'TOKEN_ALREADY_USED':
          out = _Outcome(l.linkUsedTitle, l.linkUsed, rule);
        case 'RESTORE_WRONG_DEVICE':
          out = _Outcome(l.linkWrongPhoneTitle, l.linkWrongPhone, const [_Button.home]);
        case 'DEVICE_HAS_PROFILE':
          await controller.refresh();
          out = _Outcome(l.linkDeviceHasProfileTitle, l.linkDeviceHasProfile, const [_Button.home]);
        case 'INVALID_REQUEST':
          out = _Outcome(l.linkInvalidTitle, l.linkBadRequest, const [_Button.home]);
        default:
          out = _Outcome(l.linkCouldNotCheckTitle, l.msgGeneric, const [_Button.retry, _Button.home]);
      }
    } on NetworkException {
      out = _Outcome(l.linkCouldNotCheckTitle, l.msgNetwork, const [_Button.retry, _Button.home]);
    }
    if (mounted) setState(() => _outcome = out);
  }

  /// §8.9's button rule for an expired, invalid or used link.
  List<_Button> _buttonsFor(String? purpose) {
    final state = ref.read(profileControllerProvider);
    if ((purpose == 'VERIFY_EMAIL' || purpose == 'CHANGE_EMAIL') &&
        state is ProfileLoaded &&
        !state.profile.emailVerified) {
      return const [_Button.sendNew, _Button.home];
    }
    if (purpose == 'RESTORE_PROFILE' && state is! ProfileLoaded) {
      return const [_Button.tryAgain, _Button.home];
    }
    return const [_Button.home];
  }

  Future<void> _sendNew() async {
    final l = L.of(context);
    final router = GoRouter.of(context);
    final email = ref.read(profileProvider)?.email ?? '';
    setState(() => _sending = true);
    try {
      final cooldown = await ref.read(profileApiProvider).sendVerification();
      router.push(Routes.emailSent, extra: EmailSentArgs(EmailPurpose.verifyEmail, email, cooldown));
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == 'EMAIL_ALREADY_VERIFIED') {
        await ref.read(profileControllerProvider.notifier).refresh();
      } else if (e.code == 'NO_PROFILE') {
        await ref.read(profileControllerProvider.notifier).markNone();
      } else if (mounted) {
        ProfileMessages.snack(context, ProfileMessages.of(l, e));
      }
    } on NetworkException {
      if (mounted) ProfileMessages.snack(context, l.msgNetwork);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    final out = _outcome;

    return HazriScreen(
      title: l.linkResultTitle,
      children: [
        const SizedBox(height: 24),
        if (out == null) ...[
          const Center(child: CircularProgressIndicator()),
          const SizedBox(height: 16),
          Text(l.linkChecking, textAlign: TextAlign.center, style: HazriText.body.copyWith(color: c.ink2)),
        ] else ...[
          Text(out.title, style: HazriText.display22.copyWith(color: c.ink)),
          const SizedBox(height: 8),
          Text(out.message, style: HazriText.body.copyWith(color: c.ink2)),
          const SizedBox(height: 24),
          for (final b in out.buttons) ...[
            switch (b) {
              _Button.home => PrimaryButton(
                  label: l.linkGoHome,
                  secondary: out.buttons.length > 1,
                  onPressed: () => context.go(Routes.today),
                ),
              _Button.sendNew => PrimaryButton(label: l.linkSendNew, onPressed: _sending ? null : _sendNew),
              _Button.tryAgain => PrimaryButton(
                  label: l.linkTryAgain,
                  onPressed: () => context.pushReplacement(Routes.profileSetup),
                ),
              _Button.retry => PrimaryButton(label: l.profileRetry, onPressed: _check),
              _Button.restoreData => const RestoreDataButton(),
            },
            const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }
}
