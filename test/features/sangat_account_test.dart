import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/features/sangat/data/account_repository.dart';
import 'package:hazri/features/sangat/domain/sangat_account.dart';

/// The sangat is optional, and these tests are what keep it optional.
///
/// The failure they exist to prevent is not a bug in Firebase. It is a screen
/// quietly assuming an account exists, so that somebody who never joined —
/// which will be most people — opens the app to a crash or an empty state
/// where Phase 1 gave them their nitnem.
void main() {
  group('by default nobody has joined', () {
    test('the repository reports no account', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(accountRepositoryProvider).current, isNull);
      expect(container.read(hasJoinedSangatProvider), isFalse);
    });

    test('every call refuses politely rather than throwing', () async {
      const repo = NoAccountRepository();

      expect(
        await repo.join(name: 'Harjit Singh', email: 'a@b.c', city: 'Amritsar'),
        isA<SangatUnavailable>(),
      );
      expect(await repo.sendVerificationLink('a@b.c'), isA<SangatUnavailable>());
      await expectLater(repo.signOut(), completes);
      await expectLater(repo.watch().toList(), completion(isEmpty));
    });
  });

  group('what can go wrong', _outcomes);

  group('the account itself', () {
    const account = SangatAccount(
      id: 'uid-1',
      name: 'Harjit Singh',
      city: 'Amritsar, Punjab',
      email: 'harjit@example.com',
    );

    test('is not recoverable until the email is verified', () {
      expect(account.isRecoverable, isFalse,
          reason: 'an unverified address cannot bring an account back');
      expect(account.copyWith(emailVerified: true).isRecoverable, isTrue);
    });

    test('with no email is never recoverable, verified or not', () {
      const noEmail = SangatAccount(id: 'uid-2', name: 'X', city: 'Y');
      expect(noEmail.copyWith(emailVerified: true).isRecoverable, isFalse);
    });

    test('sends only the keys firestore.rules allows', () {
      // The rules pin `users/{uid}` to an exact key list. Anything added to
      // the model without a matching rule is rejected at the door, so this
      // test is the early warning rather than a mysterious permission denial.
      const allowed = {
        'name', 'email', 'phone', 'city', 'lat', 'lon',
        'createdAt', 'updatedAt', 'showName',
      };
      expect(account.toFirestore().keys, everyElement(isIn(allowed)));
    });

    test('never sends a field the rules treat as privileged', () {
      // `verified`, `role` and `groupTotal` are decided by the server. A
      // phone that could set them could mark itself verified or inflate a
      // shared goal.
      const privileged = {'verified', 'role', 'groupTotal'};
      final sent = account.copyWith(emailVerified: true).toFirestore().keys;
      expect(sent.toSet().intersection(privileged), isEmpty);
    });

    test('omits an absent email rather than writing null', () {
      const noEmail = SangatAccount(id: 'u', name: 'N', city: 'C');
      expect(noEmail.toFirestore().containsKey('email'), isFalse);
    });

    test('survives a Firestore document with fields missing', () {
      // A document written by an older build, or a partial write.
      final parsed = SangatAccount.fromFirestore('uid-3', {}, emailVerified: false);
      expect(parsed.name, isEmpty);
      expect(parsed.showName, isTrue, reason: 'the safe default is the drawn one');
      expect(parsed.isRecoverable, isFalse);
    });
  });
}

/// Separating "could not reach it" from "it said no".
///
/// The first build of the joining screen collapsed both into one message and
/// told somebody with perfect signal to check their signal, while the real
/// cause was firestore.rules sitting undeployed in the repository. These are
/// different failures with opposite fixes and the type system now says so.
void _outcomes() {
  test('a refusal and an outage are different outcomes', () {
    const refused = SangatRefused('permission-denied');
    const offline = SangatUnavailable();

    expect(refused, isNot(isA<SangatUnavailable>()));
    expect(offline, isNot(isA<SangatRefused>()));
    expect(refused.code, 'permission-denied',
        reason: 'the code has to reach the log or the cause stays invisible');
  });

  test('every outcome is handled, or the compiler says so', () {
    // JoinOutcome is sealed, so a screen that forgets a case does not build.
    // That is what caught SangatRefused the moment it was added.
    String describe(JoinOutcome o) => switch (o) {
          JoinedSangat() => 'joined',
          SangatUnavailable() => 'offline',
          SangatRefused() => 'refused',
          EmailAlreadyHasAccount() => 'exists',
          LinkDidNotWork(problem: final p) => 'link:${p.name}',
          SangatBusy() => 'busy',
          JoinFailed() => 'failed',
        };

    expect(describe(const SangatRefused('permission-denied')), 'refused');
    expect(describe(const SangatUnavailable()), 'offline');
    expect(describe(const SangatBusy()), 'busy');
    // The four link problems stay apart, because the answer differs: two
    // mean send another, and two mean sending another will not help.
    expect(describe(const LinkDidNotWork(LinkProblem.alreadyUsed)), 'link:alreadyUsed');
    expect(describe(const LinkDidNotWork(LinkProblem.expired)), 'link:expired');
    expect(describe(const LinkDidNotWork(LinkProblem.wrongAddress)), 'link:wrongAddress');
    expect(
      describe(const LinkDidNotWork(LinkProblem.addressMismatch)),
      'link:addressMismatch',
    );
  });

}
