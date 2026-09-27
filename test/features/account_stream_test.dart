import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Which Firebase stream the account is watched on.
///
/// This is a source test, and it is one on purpose. The fault it guards
/// against is invisible to every other kind: a fake repository reports
/// whatever it is told to, so the screens agreed with each other and with
/// the tests, while the real app showed **"Your email is confirmed" on one
/// screen and "Not verified" on the next**.
///
/// The cause was a choice of API. `authStateChanges()` notifies about
/// sign-in and sign-out; confirming an email links a credential, which is
/// neither, so the stream never fired. The `User` captured inside it kept
/// the `emailVerified: false` it was born with, and every Firestore snapshot
/// afterwards was mapped through that stale copy. The plugin's own
/// documentation is explicit: `userChanges()` "provides events on all user
/// changes, such as when credentials are linked".
///
/// No fake can see that, and no widget test can either. The file can.
void main() {
  /// The file with its comments taken out.
  ///
  /// The first version of this test read the whole file and failed on its
  /// own explanation -- the comment recording *why* authStateChanges was
  /// wrong contains the word authStateChanges. A guard that cannot tell a
  /// call from a sentence about a call is a guard that punishes writing
  /// things down.
  String code() {
    final raw =
        File('lib/features/sangat/data/firebase_account_repository.dart')
            .readAsStringSync();
    return raw
        .split('\n')
        .where((line) => !line.trimLeft().startsWith('//'))
        .join('\n');
  }

  final source = code();

  test('the account is watched on userChanges', () {
    expect(source, contains('.userChanges()'),
        reason: 'linking an email credential is not a sign-in, so '
            'authStateChanges never fires for it');
  });

  test('and not on authStateChanges', () {
    expect(source, isNot(contains('authStateChanges')),
        reason: 'it misses exactly the event that confirms an email, and '
            'the symptom is two screens disagreeing about one fact');
  });

  test('the token refresh does not restart the Firestore listener', () {
    // userChanges is a superset of idTokenChanges, so it also fires hourly.
    // Without a distinct() the document would be re-read on every refresh,
    // and reads are the thing that bills (docs/features/00-platform.md).
    expect(source, contains('.distinct()'),
        reason: 'userChanges fires on every token refresh too');
  });
}
