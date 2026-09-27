import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Rule 4: **no password and no sign-in screen, ever.**
///
/// This used to be guaranteed twice over — the app never asked for a
/// password, and the project had no provider that could accept one. The
/// second half went on 2026-09-27, and not by choice: Firebase's email link
/// is a *mode* of the Email/Password provider, not a provider of its own, so
/// `sendSignInLinkToEmail` cannot work unless that provider is enabled. The
/// console offers two switches and they move together.
///
/// So the backend can now technically take a password, and the only thing
/// keeping the promise is that nothing in Hazri ever sets, asks for or uses
/// one. That is a guarantee living entirely in source, which is exactly the
/// kind that rots quietly — somebody adds a "sign in" convenience, and the
/// provider is already there to accept it.
///
/// Hence this. It reads the source rather than the behaviour because there
/// is no behaviour to observe: the failure mode is a call site appearing,
/// not a call going wrong.
void main() {
  /// Every Firebase Auth entry point that involves a password.
  ///
  /// `EmailAuthProvider.credential(` is the password constructor and is
  /// banned; `EmailAuthProvider.credentialWithLink(` is the email-link one
  /// and is what Hazri uses. The trailing bracket is what keeps them apart.
  const banned = <String, String>{
    'signInWithEmailAndPassword': 'signing in with a password',
    'createUserWithEmailAndPassword': 'creating an account with a password',
    'EmailAuthProvider.credential(': 'building a password credential',
    'updatePassword': 'setting a password',
    'sendPasswordResetEmail': 'a password reset, which implies a password',
    'confirmPasswordReset': 'a password reset, which implies a password',
    'verifyPasswordResetCode': 'a password reset, which implies a password',
  };

  test('nothing in the app touches a password', () {
    final offences = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = entity.readAsStringSync();
      banned.forEach((needle, what) {
        if (source.contains(needle)) {
          offences.add('${entity.path}: $needle — $what');
        }
      });
    }

    expect(
      offences,
      isEmpty,
      reason: 'Rule 4 says no password and no sign-in screen, ever. The '
          'Firebase project can accept one now, because the email link '
          'cannot be enabled without the Email/Password provider, so this '
          'file is the only thing left holding the promise:\n'
          '${offences.join('\n')}',
    );
  });

  test('the email link is still what the app signs in with', () {
    // The inverse. If this stops being true, the test above is guarding a
    // door in a wall that is no longer there.
    final repository = File(
      'lib/features/sangat/data/firebase_account_repository.dart',
    ).readAsStringSync();

    expect(repository, contains('EmailAuthProvider.credentialWithLink'));
    expect(repository, contains('sendSignInLinkToEmail'));
  });
}
