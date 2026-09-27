import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// What "verified" has to mean, and why it cannot be one Firebase boolean.
///
/// A reader saw "Your email is confirmed" and, one tap later, "Not verified"
/// about the same account. Three explanations were tried before the right
/// one: the two screens were never measuring the same thing. The verify
/// screen said confirmed because the **call succeeded**; the account screen
/// read `user.emailVerified`, which had stayed false.
///
/// The fact this app actually promises (A5: recovery is possible if and only
/// if an email was verified) is neither of those. It is that an email
/// credential is **linked to this uid** -- because that, and only that, is
/// what makes `signInWithCredential` on a new phone return this account
/// instead of minting an empty one. Following the link is what does it, and
/// the link cannot be followed without receiving the mail.
///
/// A source test, like the stream one beside it, because a fake reports
/// whatever it is told and would have agreed with every wrong version of
/// this so far.
void main() {
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

  test('recovery is decided in one place', () {
    expect(source, contains('static bool _recoverable(User user)'),
        reason: 'one rule, or the screens drift apart again');
  });

  test('a linked email credential counts, not just the flag', () {
    expect(source, contains("p.providerId == 'password'"),
        reason: 'emailVerified was observed staying false on an account '
            'whose credential was linked and which was therefore '
            'recoverable; the link is the proof, not the flag');
  });

  test('nothing below the helpers reads emailVerified directly', () {
    // _recoverable and the diagnostic are allowed to read the raw flag --
    // one to combine it, one to report it. Everything after them has to go
    // through _recoverable, or two screens answer the same question
    // differently, which is the entire bug.
    const marker = 'END VERIFIED HELPERS';
    final whole = File(
      'lib/features/sangat/data/firebase_account_repository.dart',
    ).readAsStringSync();
    expect(whole, contains(marker), reason: 'the boundary went missing');

    final below = whole.substring(whole.indexOf(marker));
    final direct = RegExp(r'\b(user|fresh|who|credential)\.emailVerified\b')
        .allMatches(below)
        .map((m) => m.group(0))
        .toList();

    expect(direct, isEmpty,
        reason: 'read through _recoverable instead: $direct');
  });
}
