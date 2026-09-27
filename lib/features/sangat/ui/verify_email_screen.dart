import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/surfaces.dart';
import '../data/account_repository.dart';
import '../data/pending_verification.dart';
import '../domain/sangat_account.dart';
import 'join_outcome_words.dart';
import 'link_problem.dart';
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
  const VerifyEmailScreen({super.key, this.arrivedWith});

  /// A sign-in link the app was *opened* with, rather than one somebody
  /// typed. The router puts it here when Android hands over a tapped link
  /// (`IncomingLink`), and the screen finishes the job on its own — nobody
  /// copies a URL, which is the whole point of the exercise.
  ///
  /// Nullable because this screen is still reachable by hand, and the paste
  /// box stays for a link that arrived on a desktop, in a mail client that
  /// mangles the tap, or on a phone whose manufacturer mishandles App Link
  /// verification. Removing the manual path would trade one dead end for
  /// another.
  final String? arrivedWith;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  final _email = TextEditingController();

  final _link = TextEditingController();

  bool _editing = false;
  bool _busy = false;
  bool _sent = false;
  bool _confirmed = false;
  String? _error;
  LinkProblem? _problem;

  @override
  void initState() {
    super.initState();
    final link = widget.arrivedWith;
    if (link == null || link.isEmpty) return;
    // Tapped, not typed. Fill the box so the reader can see what is being
    // used, then finish without asking -- after the first frame, because the
    // account this needs is read from a provider.
    _link.text = link;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // The remembered address first, and the account's only after.
      //
      // Not a preference -- a race. Opening from a tapped link is a cold
      // start, and `sangatAccountProvider` is fed by Firebase's auth stream,
      // which has usually not emitted yet one frame in. Reading the account
      // here would hand `continueWithLink` an empty address about as often
      // as not, and the failure would look like a bad link.
      //
      // The remembered address is also the more correct of the two: it is by
      // definition the one this link was minted for, which is precisely what
      // Firebase wants back alongside it.
      final account = ref.read(sangatAccountProvider).value;
      final remembered = ref.read(pendingVerificationProvider).address ?? '';
      final address = remembered.isNotEmpty
          ? remembered
          : (account?.email ?? '').trim();

      if (address.isEmpty) {
        // A link, and nothing to pair it with -- a second phone that never
        // asked for this one. Ask for the address rather than firing a call
        // that can only fail and then blaming the link for it.
        setState(() => _editing = true);
        return;
      }

      _confirm(account, address: address);
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _link.dispose();
    super.dispose();
  }

  /// Finishes the job with the link out of the email.
  ///
  /// Pasted rather than tapped: tapping needs Android App Links, which need a
  /// release fingerprint this project does not have. Pasting needs nothing,
  /// so verification can actually complete today.
  Future<void> _confirm(SangatAccount? account, {String? address}) async {
    final l = L.of(context);
    setState(() {
      _busy = true;
      _error = null;
      _problem = null;
    });

    final outcome = await ref
        .read(accountRepositoryProvider)
        .continueWithLink(
          email: address ?? _address(account),
          link: _link.text,
        );
    if (!mounted) return;

    switch (outcome) {
      case JoinedSangat():
        // Used, so no longer pending. Leaving it behind would mean the next
        // link tried against a stale address.
        await ref.read(pendingVerificationProvider).forget();
        if (!mounted) return;
        setState(() {
          _busy = false;
          _confirmed = true;
        });
      case LinkDidNotWork(problem: final problem):
        setState(() {
          _busy = false;
          _problem = problem;
        });
      default:
        setState(() {
          _busy = false;
          _error = wordsForOutcome(outcome, l);
        });
    }
  }

  /// The address the link goes to: what is in the box while it is open,
  /// otherwise what the account already holds -- and failing both, the
  /// address written down just before the link was sent.
  ///
  /// That last fallback is what makes a tapped link work at all on a phone
  /// with no account yet: Firebase wants the address back alongside the
  /// link, and there is nothing to read it from.
  String _address(SangatAccount? account) {
    if (_editing) return _email.text.trim();
    final onAccount = (account?.email ?? '').trim();
    if (onAccount.isNotEmpty) return onAccount;
    return (ref.read(pendingVerificationProvider).address ?? '').trim();
  }

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
          _error = wordsForOutcome(saved, l);
        });
        return;
      }
    }

    // Written down before the send, not after: if the app is killed between
    // the two, the link in the inbox still has an address to pair with.
    await ref.read(pendingVerificationProvider).remember(email);

    final outcome = await repo.sendVerificationLink(email);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _editing = false;
      _sent = outcome is JoinedSangat;
      _error = outcome is JoinedSangat ? null : wordsForOutcome(outcome, l);
    });
  }

  /// Leaves the screen, whichever way it was arrived at.
  ///
  /// A tapped link lands here by a router redirect, so there is nothing
  /// underneath to pop back to: the back button did nothing, the system back
  /// gesture did nothing, and the only way out anybody found was killing the
  /// app. Popping is right when this was pushed from the account screen and
  /// wrong when it was not, so ask rather than assume.
  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.account);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    final account = ref.watch(sangatAccountProvider).value;
    final address = _address(account);

    // Confirmed is confirmed, whether it happened a moment ago on this screen
    // or on another phone entirely.
    final done = _confirmed || (account?.emailVerified ?? false);

    return PopScope(
      canPop: context.canPop(),
      // Fires when there was nothing to pop. Without it, Android's back
      // gesture on a screen reached by a redirect does nothing at all.
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(Routes.account);
      },
      child: Scaffold(
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
                      onPressed: _leave,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l.verifyTitle,
                        style: HazriText.display22.copyWith(color: c.ink),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: c.kesriSoft,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: AppIcon(
                      HazriIconData.mail,
                      size: 38,
                      color: c.kesriInk,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  done
                      ? l.verifyDoneTitle
                      : (_sent ? l.verifyCheckInbox : l.accountVerifyTitle),
                  textAlign: TextAlign.center,
                  style: HazriText.display22.copyWith(color: c.ink),
                ),
                const SizedBox(height: 8),
                Text(
                  done
                      ? l.verifyDoneBody
                      : (_sent && address.isNotEmpty
                            ? l.verifySentTo(address)
                            : l.accountVerifyBody),
                  textAlign: TextAlign.center,
                  style: HazriText.body.copyWith(color: c.ink2),
                ),
                const SizedBox(height: 18),
                // Everything from here to the way out is about getting an
                // address confirmed. Once it is, none of it has anything left
                // to say -- and a screen that announces success while still
                // offering to send the link, and still warning that nothing is
                // recoverable, is telling somebody two opposite things at once.
                if (!done) ...[
                  if (_editing)
                    SangatField(
                      label: l.sangatFieldEmail,
                      controller: _email,
                      autofocus: true,
                      keyboardType: TextInputType.emailAddress,
                    )
                  else
                    HazriCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 13,
                      ),
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
                                Text(
                                  l.verifyWrongAddress,
                                  style: HazriText.captionStrong.copyWith(
                                    color: c.ink,
                                  ),
                                ),
                                Text(
                                  address.isEmpty
                                      ? l.verifyChangeIt
                                      : '$address — ${l.verifyChangeIt}',
                                  style: HazriText.caption.copyWith(
                                    color: c.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AppIcon(
                            HazriIconData.chevronRight,
                            size: 18,
                            color: c.muted,
                          ),
                        ],
                      ),
                    ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      _error!,
                      style: HazriText.bodySmall.copyWith(color: c.kesriInk),
                    ),
                  ],
                  if (_sent && _error == null) ...[
                    const SizedBox(height: 14),
                    Center(
                      child: Text(
                        l.verifySent,
                        style: HazriText.bodySmall.copyWith(color: c.sage),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: _sent ? l.verifySendAgain : l.verifySend,
                    secondary: _sent,
                    onPressed: _busy ? null : () => _send(account),
                  ),
                  if (_sent) ...[
                    const SizedBox(height: 18),
                    SangatField(
                      label: l.restorePasteLabel,
                      controller: _link,
                      hint: l.restorePasteHint,
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 14),
                    PrimaryButton(
                      label: l.sangatContinue,
                      onPressed: _busy ? null : () => _confirm(account),
                    ),
                  ],
                  if (_problem != null) ...[
                    const SizedBox(height: 18),
                    LinkProblemCard(problem: _problem!),
                  ],
                  const SizedBox(height: 16),
                  HazriCard(
                    colour: c.card2,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppIcon(
                          HazriIconData.alert,
                          size: 18,
                          color: c.kesriInk,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l.verifyUntilThen,
                            style: HazriText.caption.copyWith(color: c.ink2),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: _leave,
                      child: Text(
                        l.verifyLater,
                        style: HazriText.captionStrong.copyWith(color: c.muted),
                      ),
                    ),
                  ),
                ],
                if (done) ...[
                  const SizedBox(height: 24),
                  PrimaryButton(label: l.actionDone, onPressed: _leave),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
