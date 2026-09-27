import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/sangat_account.dart';

/// What happened when somebody tried to join, or to change their details.
///
/// A sealed result rather than an exception, because every one of these is an
/// ordinary outcome the screen has to say something about — the network being
/// down while somebody is on a train is not exceptional, it is Tuesday.
sealed class JoinOutcome {
  const JoinOutcome();
}

class JoinedSangat extends JoinOutcome {
  const JoinedSangat(this.account);
  final SangatAccount account;
}

/// The server is not there: no Firebase on this build, start-up failed, or
/// the phone is offline. The app carries on; the sangat does not.
class SangatUnavailable extends JoinOutcome {
  const SangatUnavailable();
}

/// The address already has an account behind it (screen 53). Restoring and
/// starting fresh are both legitimate, so this is not an error — it is a
/// fork the screen has to offer.
class EmailAlreadyHasAccount extends JoinOutcome {
  const EmailAlreadyHasAccount(this.email);
  final String email;
}

/// The server was reached and said no. Almost always our fault: rules not
/// deployed, or a field the rules do not allow.
///
/// Kept apart from [SangatUnavailable] because conflating them is exactly
/// how an afternoon gets lost. The first build of this told somebody with
/// perfect signal to check their signal, while the real cause was a rules
/// file sitting undeployed in the repository.
class SangatRefused extends JoinOutcome {
  const SangatRefused(this.code);

  /// The Firebase code, for the log. The screen shows its own words.
  final String code;
}

/// Which outcome a Firebase Auth error code becomes.
///
/// A pure function, deliberately, and deliberately not a method on the
/// repository: **this is the seam the bug lived at.** Every unmapped code
/// used to fall through to one bucket that a screen then rendered as "could
/// not reach the sangat" — a sentence about the reader's wifi. The first
/// person to verify an address on a real phone got exactly that, with
/// perfect signal, and the code that would have named the cause was thrown
/// away on the way.
///
/// Taking a `String` rather than a `FirebaseAuthException` is what lets a
/// test name a real code and assert what the reader is told, without
/// Firebase, a device or a widget tree in the way.
JoinOutcome outcomeForAuthCode(String code, {String email = ''}) {
  switch (code) {
    // The address already belongs to somebody — screen 53's fork, not a
    // failure.
    case 'email-already-in-use':
    case 'credential-already-in-use':
    case 'account-exists-with-different-credential':
      return EmailAlreadyHasAccount(email.trim());

    // Genuinely could not get there. The only one of these that is about
    // the reader's circumstances at all.
    case 'network-request-failed':
    case 'timeout':
      return const SangatUnavailable();

    // Reached it, and it said slow down.
    case 'too-many-requests':
      return const SangatBusy();

    // Reached it, and it said no because of how the *project* is set up.
    // Each of these is a console setting that is invisible in git, so
    // [SangatRefused]'s words — wrong at our end, not yours — are the true
    // ones, and the code has to survive to the screen or nobody can tell
    // which setting it was.
    //
    //   operation-not-allowed      email link sign-in is switched off
    //   unauthorized-continue-uri  the continue URL's host is not authorised
    //   unauthorized-domain        same, by its other name
    //   invalid-continue-uri       kVerificationUrl is malformed
    //   missing-android-pkg-name   the package is not on the project
    //   invalid-cert-hash          no signing fingerprint is registered
    case 'operation-not-allowed':
    case 'unauthorized-continue-uri':
    case 'unauthorized-domain':
    case 'invalid-continue-uri':
    case 'missing-android-pkg-name':
    case 'invalid-cert-hash':
      return SangatRefused(code);

    // The account is gone or switched off at the console.
    case 'user-disabled':
    case 'user-not-found':
      return SangatRefused(code);

    default:
      return JoinFailed(code);
  }
}

/// Which link problem a Firebase Auth error code becomes, or null when the
/// code is not about the link at all.
LinkProblem? linkProblemForAuthCode(String code) => switch (code) {
      'invalid-action-code' => LinkProblem.alreadyUsed,
      'expired-action-code' => LinkProblem.expired,
      // The link is ours and still good; it was minted for a different
      // address. A new link changes nothing, so sharing a branch with
      // `invalid-action-code` is what kept people pressing send.
      'invalid-email' => LinkProblem.addressMismatch,
      _ => null,
    };

/// Firebase is throttling us: too many links asked for, too fast.
///
/// Its own fault code is `too-many-requests`, and it used to be reported as
/// [SangatUnavailable] — which sends somebody whose signal is perfect off to
/// look at their wifi, at the exact moment they have asked three times
/// because the mail has not arrived. The network is fine; waiting is the
/// answer.
class SangatBusy extends JoinOutcome {
  const SangatBusy();
}

/// Why a link from an email did not work (design 52).
enum LinkProblem {
  /// Every link works once. A forwarded email is not a way in.
  alreadyUsed,

  /// Firebase's links last an hour. Nobody used this one; it lapsed.
  expired,

  /// What was pasted is not one of our links at all — usually a mail client
  /// that wrapped or rewrote the URL, so only part of it came across.
  wrongAddress,

  /// The link is ours and it is good, but it was minted for a different
  /// address than the one in the box. Sending another will not help until
  /// the address matches; Firebase calls this `invalid-email`, and reporting
  /// it as [alreadyUsed] left people asking for link after link.
  addressMismatch,
}

/// The link did not work, and which of the three reasons it was.
///
/// Told apart because the answer differs: two of them mean send another, and
/// the third means the address is wrong and sending another will not help.
class LinkDidNotWork extends JoinOutcome {
  const LinkDidNotWork(this.problem);
  final LinkProblem problem;
}

/// Something went wrong that the person can act on. [message] is for the
/// developer; the screen shows its own words.
class JoinFailed extends JoinOutcome {
  const JoinFailed(this.message);
  final String message;
}

/// The sangat account, behind an interface.
///
/// **The account is created when somebody joins, not when the app starts.**
/// That is the whole difference between "opt-in" meaning something and
/// meaning nothing: an anonymous sign-in on first launch would put every
/// reader on a server whether they asked or not, and CLAUDE.md rule 4 says
/// somebody who never joins the sangat reads, listens and keeps a diary
/// entirely on their own phone. Nothing in here runs until a person taps
/// Set up.
abstract interface class AccountRepository {
  /// The account on this phone, or null for the great majority who have not
  /// joined. Emits again when the profile or the verified flag changes.
  Stream<SangatAccount?> watch();

  /// The account right now, without waiting for the stream.
  SangatAccount? get current;

  /// Creates the anonymous account and writes the profile. This is the first
  /// network request the app ever makes on this phone.
  Future<JoinOutcome> join({
    required String name,
    required String email,
    required String city,
    String? phone,
  });

  /// Changes the profile of an account that already exists.
  Future<JoinOutcome> updateProfile(SangatAccount account);

  /// Emails the link that confirms the address (screen 34). Safe to call
  /// again; asking twice is how somebody fixes a typo.
  Future<JoinOutcome> sendVerificationLink(String email);

  /// Finishes what [sendVerificationLink] started, from the link in the
  /// email.
  ///
  /// The same call does two jobs, because Firebase makes them the same one:
  /// on a phone with an anonymous account it confirms the address and keeps
  /// everything already on it, and on a fresh phone it signs into the account
  /// that address already has. That is the whole of "restore" — there is no
  /// password to check because there is no password.
  Future<JoinOutcome> continueWithLink({required String email, required String link});

  /// Deletes the account and everything the server holds for it (design 35).
  ///
  /// Not a flag and not a queue: the profile row goes, the memberships go,
  /// and the anonymous user itself goes. What stays is what never left the
  /// phone, which is the diary, the streaks and the reading position — and
  /// the person still has those.
  Future<JoinOutcome> deleteEverything();

  /// Signs out of this phone. The account itself is untouched and comes back
  /// with the email — which is exactly why verifying it matters.
  Future<void> signOut();
}

/// The repository for somebody with no server: almost every test, every
/// widget harness, and any phone where Firebase failed to start.
///
/// It reports no account and refuses politely. It never throws, so no screen
/// needs a try/catch to stay standing.
class NoAccountRepository implements AccountRepository {
  const NoAccountRepository();

  @override
  Stream<SangatAccount?> watch() => const Stream<SangatAccount?>.empty();

  @override
  SangatAccount? get current => null;

  @override
  Future<JoinOutcome> join({
    required String name,
    required String email,
    required String city,
    String? phone,
  }) async =>
      const SangatUnavailable();

  @override
  Future<JoinOutcome> updateProfile(SangatAccount account) async =>
      const SangatUnavailable();

  @override
  Future<JoinOutcome> sendVerificationLink(String email) async =>
      const SangatUnavailable();

  @override
  Future<JoinOutcome> continueWithLink({
    required String email,
    required String link,
  }) async =>
      const SangatUnavailable();

  @override
  Future<JoinOutcome> deleteEverything() async => const SangatUnavailable();

  @override
  Future<void> signOut() async {}
}

/// Overridden in `main.dart` when the backend came up. The default is no
/// account, so a test reaches no server by accident.
final accountRepositoryProvider =
    Provider<AccountRepository>((ref) => const NoAccountRepository());

/// The account on this phone, or null. Null is the normal case.
final sangatAccountProvider = StreamProvider<SangatAccount?>(
  (ref) => ref.watch(accountRepositoryProvider).watch(),
);

/// Whether this person has joined the sangat. Everything sangat-shaped in the
/// UI hangs off this, and it is false unless proven otherwise.
final hasJoinedSangatProvider = Provider<bool>(
  (ref) => ref.watch(sangatAccountProvider).value != null,
);
