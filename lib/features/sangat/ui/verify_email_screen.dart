import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/surfaces.dart';
import '../data/account_repository.dart';
import '../domain/sangat_account.dart';
import 'sangat_field.dart';

/// Design 34 — confirming the address.
///
/// Reached only from the account screen, never from setup and never from
/// Today: the reader asked for verification to live in one place and nowhere
/// else.
///
/// Two departures from the design, both deliberate:
///
/// * **No six-digit code.** The design shows one, but a code needs a server
///   that can mint and check it, and Phase 2 runs on Firebase's Spark plan
///   with no functions. The email link is what Firebase gives us for free
///   and it does the same job. The boxes come back if a backend ever does.
/// * **The address is editable here.** Design 34 sends "wrong address?"
///   somewhere else; there is nowhere else yet, and the reader asked that
///   somebody be able to correct a typo at exactly this moment rather than
///   go back and start again.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  final _email = TextEditingController();

  bool _editing = false;
  bool _busy = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  /// The address the link goes to: what is in the box while it is open,
  /// otherwise what the account already holds.
  String _address(SangatAccount? account) =>
      _editing ? _email.text.trim() : (account?.email ?? '').trim();

  Future<void> _send(SangatAccount? account) async {
    final l = L.of(context);
    final email = _address(account);
    if (email.isEmpty) {
      setState(() => _error = l.sangatNeedEmail);
      return;
    }
    if (!SangatAccount.looksLikeEmail(email)) {
      setState(() => _error = l.sangatBadEmail);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final repo = ref.read(accountRepositoryProvider);
    // A corrected address is saved before the link goes out, so the account
    // screen and the mail agree even if the person never taps the link.
    if (account != null && email != account.email) {
      final saved = await repo.updateProfile(account.copyWith(email: email));
      if (!mounted) return;
      if (saved is! JoinedSangat) {
        setState(() {
          _busy = false;
          _error = _wordsFor(saved, l);
        });
        return;
      }
    }

    final outcome = await repo.sendVerificationLink(email);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _editing = false;
      _sent = outcome is JoinedSangat;
      _error = outcome is JoinedSangat ? null : _wordsFor(outcome, l);
    });
  }

  /// What to put on screen for an outcome that is not success. The switch is
  /// exhaustive on purpose: a new outcome should not compile until somebody
  /// has decided what the reader is told about it.
  String _wordsFor(JoinOutcome outcome, L l) => switch (outcome) {
        JoinedSangat() => '',
        EmailAlreadyHasAccount() => l.sangatEmailInUse,
        SangatUnavailable() => l.sangatUnavailable,
        SangatRefused() => l.sangatRefused,
        JoinFailed() => l.sangatUnavailable,
      };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    final account = ref.watch(sangatAccountProvider).value;
    final address = _address(account);

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: PhoneWidth(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
            children: [
              Row(
                children: [
                  CardIconButton(
                    icon: HazriIconData.chevronLeft,
                    tooltip: l.actionBack,
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(l.verifyTitle,
                        style: HazriText.display22.copyWith(color: c.ink)),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration:
                      BoxDecoration(color: c.kesriSoft, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: AppIcon(HazriIconData.mail, size: 38, color: c.kesriInk),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _sent ? l.verifyCheckInbox : l.accountVerifyTitle,
                textAlign: TextAlign.center,
                style: HazriText.display22.copyWith(color: c.ink),
              ),
              const SizedBox(height: 8),
              Text(
                _sent && address.isNotEmpty
                    ? l.verifySentTo(address)
                    : l.accountVerifyBody,
                textAlign: TextAlign.center,
                style: HazriText.body.copyWith(color: c.ink2),
              ),
              const SizedBox(height: 18),
              if (_editing)
                SangatField(
                  label: l.sangatFieldEmail,
                  controller: _email,
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                )
              else
                HazriCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  onTap: () {
                    setState(() {
                      _email.text = account?.email ?? '';
                      _editing = true;
                      _error = null;
                    });
                  },
                  child: Row(
                    children: [
                      AppIcon(HazriIconData.mail, size: 19, color: c.teal),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l.verifyWrongAddress,
                                style: HazriText.captionStrong.copyWith(color: c.ink)),
                            Text(
                              address.isEmpty
                                  ? l.verifyChangeIt
                                  : '$address — ${l.verifyChangeIt}',
                              style: HazriText.caption.copyWith(color: c.muted),
                            ),
                          ],
                        ),
                      ),
                      AppIcon(HazriIconData.chevronRight, size: 18, color: c.muted),
                    ],
                  ),
                ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(_error!, style: HazriText.bodySmall.copyWith(color: c.kesriInk)),
              ],
              if (_sent && _error == null) ...[
                const SizedBox(height: 14),
                Center(
                  child: Text(l.verifySent,
                      style: HazriText.bodySmall.copyWith(color: c.sage)),
                ),
              ],
              const SizedBox(height: 16),
              PrimaryButton(
                label: _sent ? l.verifySendAgain : l.verifySend,
                onPressed: _busy ? null : () => _send(account),
              ),
              const SizedBox(height: 16),
              HazriCard(
                colour: c.card2,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppIcon(HazriIconData.alert, size: 18, color: c.kesriInk),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(l.verifyUntilThen,
                          style: HazriText.caption.copyWith(color: c.ink2)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => context.pop(),
                  child: Text(l.verifyLater,
                      style: HazriText.captionStrong.copyWith(color: c.muted)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
