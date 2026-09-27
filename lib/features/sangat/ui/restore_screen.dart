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
import '../../settings/ui/screen_scaffold.dart';
import '../data/account_repository.dart';
import '../domain/sangat_account.dart';
import '../../sync/data/diary_sync.dart';
import 'join_outcome_words.dart';
import 'link_problem.dart';
import 'sangat_field.dart';

/// Designs 53, 54 and 52 — coming back to an account on a new phone.
///
/// There is no password to check, because there is no password. What proves
/// the account is yours is reaching the email on it: we send a link there and
/// you bring it back. Firebase makes verifying and restoring the same call,
/// so the same screen does both — on a phone that already has an anonymous
/// account it confirms the address and keeps everything, and on a fresh phone
/// it signs into the account that address already has.
///
/// **The link is pasted, not tapped.** Tapping it needs Android App Links,
/// which need a release signing fingerprint this project does not have yet.
/// Pasting works today and needs nothing, so restoring is possible now rather
/// than in Phase 3.
class RestoreScreen extends ConsumerStatefulWidget {
  const RestoreScreen({super.key, this.email});

  /// The address that turned out to have an account already, when the person
  /// arrived here from the join form.
  final String? email;

  @override
  ConsumerState<RestoreScreen> createState() => _RestoreScreenState();
}

class _RestoreScreenState extends ConsumerState<RestoreScreen> {
  late final _email = TextEditingController(text: widget.email ?? '');
  final _link = TextEditingController();

  bool _busy = false;
  bool _sent = false;
  bool _done = false;
  String? _error;
  LinkProblem? _problem;

  @override
  void dispose() {
    _email.dispose();
    _link.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l = L.of(context);
    final email = _email.text.trim();
    if (!SangatAccount.looksLikeEmail(email)) {
      setState(() => _error = l.sangatBadEmail);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _problem = null;
    });

    final outcome = await ref.read(accountRepositoryProvider).sendVerificationLink(email);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _sent = outcome is JoinedSangat;
      _error = outcome is JoinedSangat ? null : wordsForOutcome(outcome, l);
    });
  }

  Future<void> _continue() async {
    final l = L.of(context);
    setState(() {
      _busy = true;
      _error = null;
      _problem = null;
    });

    final outcome = await ref.read(accountRepositoryProvider).continueWithLink(
          email: _email.text.trim(),
          link: _link.text,
        );
    if (!mounted) return;

    switch (outcome) {
      case JoinedSangat():
        // This is the whole of "your diary came back". It is a merge, so a
        // day marked on this phone and on the server stays marked once, and
        // it does nothing at all when sync was never on -- which the next
        // screen says out loud rather than leaving somebody to wonder.
        await ref.read(diarySyncProvider).pull();
        if (!mounted) return;
        setState(() {
          _busy = false;
          _done = true;
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


  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);

    if (_done) return _Restored(l: l);

    return HazriScreen(
      title: l.restoreTitle,
      children: [
        const SizedBox(height: 6),
        HazriCard(
          colour: c.card2,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppIcon(HazriIconData.sangat, size: 19, color: c.teal),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.restoreBeenHere,
                        style: HazriText.captionStrong.copyWith(color: c.ink)),
                    const SizedBox(height: 2),
                    Text(l.restoreNothingSignedOut,
                        style: HazriText.caption.copyWith(color: c.ink2)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SangatField(
          label: l.sangatFieldEmail,
          controller: _email,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          label: _sent ? l.linkSendAnother : l.restoreSendLink,
          secondary: _sent,
          onPressed: _busy ? null : _send,
        ),
        if (_sent) ...[
          const SizedBox(height: 14),
          // Restore used to go straight from the button to the paste box,
          // saying nothing about where the link had gone. Firebase's own
          // mailer sends from noreply@<project>.firebaseapp.com, a domain
          // shared by every Firebase project on earth, and the first mail
          // this project ever sent landed in spam -- so somebody staring at
          // an empty inbox has no idea the mail is two taps away.
          Text(l.verifySent, style: HazriText.caption.copyWith(color: c.ink2)),
          const SizedBox(height: 18),
          SangatField(
            label: l.restorePasteLabel,
            controller: _link,
            hint: l.restorePasteHint,
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            label: l.restoreThisAccount,
            onPressed: _busy ? null : _continue,
          ),
        ],
        if (_problem != null) ...[
          const SizedBox(height: 18),
          LinkProblemCard(problem: _problem!),
        ],
        if (_error != null) ...[
          const SizedBox(height: 14),
          Text(_error!, style: HazriText.bodySmall.copyWith(color: c.kesriInk)),
        ],
        const SizedBox(height: 22),
        Center(
          child: Text(l.restoreOr, style: HazriText.caption.copyWith(color: c.muted)),
        ),
        const SizedBox(height: 10),
        // The other half of the reader's fork: somebody on a borrowed phone,
        // or somebody who would rather not go and find an email, can just
        // start again. It is not hidden and it is not discouraged.
        HazriCard(
          onTap: () => context.pushReplacement(Routes.sangatJoin),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.restoreStartFresh,
                        style: HazriText.bodyStrong.copyWith(color: c.ink)),
                    Text(l.restoreStartFreshSub,
                        style: HazriText.caption.copyWith(color: c.muted)),
                  ],
                ),
              ),
              AppIcon(HazriIconData.chevronRight, size: 18, color: c.muted),
            ],
          ),
        ),
      ],
    );
  }
}

/// Design 54 — what came back.
class _Restored extends ConsumerWidget {
  const _Restored({required this.l});

  final L l;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final account = ref.watch(sangatAccountProvider).value;

    return HazriScreen(
      title: l.restoreDone,
      children: [
        const SizedBox(height: 18),
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: c.sageSoft, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: AppIcon(HazriIconData.check, size: 32, color: c.sage),
          ),
        ),
        const SizedBox(height: 18),
        if (account != null) ...[
          HazriCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (account.name.isNotEmpty)
                  Text(account.name,
                      style: HazriText.display22.copyWith(color: c.ink, fontSize: 20)),
                if (account.city.isNotEmpty)
                  Text(account.city, style: HazriText.caption.copyWith(color: c.muted)),
                if (account.email != null) ...[
                  const SizedBox(height: 6),
                  Text(account.email!,
                      style: HazriText.bodySmall.copyWith(color: c.ink2)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        // Said plainly rather than discovered later: the diary is the one
        // thing that does not always come back, and why.
        HazriCard(
          colour: c.card2,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Text(l.restoreDiaryNote,
              style: HazriText.caption.copyWith(color: c.ink2)),
        ),
        const SizedBox(height: 20),
        PrimaryButton(
          label: l.restoreOpenToday,
          onPressed: () => context.go(Routes.today),
        ),
      ],
    );
  }
}
