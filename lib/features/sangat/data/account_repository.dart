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
