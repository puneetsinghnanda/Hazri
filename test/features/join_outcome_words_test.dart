import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';
import 'package:hazri/features/sangat/data/account_repository.dart';
import 'package:hazri/features/sangat/domain/sangat_account.dart';
import 'package:hazri/features/sangat/ui/join_outcome_words.dart';
import 'package:hazri/features/sangat/ui/link_problem.dart';

/// What the reader is told when joining, verifying or restoring fails.
///
/// These exist because of a real afternoon. The first time anybody verified
/// an address on a real phone, the app said **"Could not reach the sangat.
/// Your paath is safe on this phone — try again when you have signal."** The
/// signal was fine. The project simply had a console setting unset, and
/// every unmapped auth code fell into one bucket that two of the three
/// screens rendered with that sentence. The cause was undiagnosable from the
/// message, and the Firebase code that named it was discarded on the way.
///
/// So the rule these hold is not "the mapping function returns the right
/// enum" — the old tests asserted that two different classes were different
/// classes, which can never fail. It is **two causes must never produce the
/// same sentence**, which is the property that was actually violated.
void main() {
  final en = lookupL(const Locale('en'));

  group('a Firebase code becomes the right kind of outcome', () {
    // The seam: a string from Firebase in, an outcome out. No Firebase, no
    // device, no widget tree — so every one of these can be named directly.
    const cases = <String, Type>{
      // Ours to fix, in the console, invisible in git.
      'operation-not-allowed': SangatRefused,
      'unauthorized-continue-uri': SangatRefused,
      'unauthorized-domain': SangatRefused,
      'invalid-continue-uri': SangatRefused,
      'missing-android-pkg-name': SangatRefused,
      'invalid-cert-hash': SangatRefused,
      'user-disabled': SangatRefused,
      'user-not-found': SangatRefused,

      // Theirs, and only these.
      'network-request-failed': SangatUnavailable,
      'timeout': SangatUnavailable,

      // Neither: wait.
      'too-many-requests': SangatBusy,

      // A fork, not a failure.
      'email-already-in-use': EmailAlreadyHasAccount,
      'credential-already-in-use': EmailAlreadyHasAccount,
      'account-exists-with-different-credential': EmailAlreadyHasAccount,
    };

    cases.forEach((code, expected) {
      test('$code -> $expected', () {
        expect(outcomeForAuthCode(code, email: 'a@b.c').runtimeType, expected);
      });
    });

    test('an unknown code keeps its code', () {
      // Whatever we have not thought of must still arrive at the screen
      // carrying its name, or the next unknown failure is as blind as this
      // one was.
      final outcome = outcomeForAuthCode('some-code-nobody-has-seen');
      expect(outcome, isA<JoinFailed>());
      expect((outcome as JoinFailed).message, 'some-code-nobody-has-seen');
      expect(wordsForOutcome(outcome, en), contains('some-code-nobody-has-seen'));
    });

    test('a configuration failure is never reported as no signal', () {
      // The exact bug. operation-not-allowed means email link sign-in is
      // switched off in the console; it has nothing to do with a network.
      final words = wordsForOutcome(outcomeForAuthCode('operation-not-allowed'), en);
      expect(words, isNot(en.sangatUnavailable));
      expect(words, en.sangatRefused);
    });

    test('a throttle is never reported as no signal', () {
      final words = wordsForOutcome(outcomeForAuthCode('too-many-requests'), en);
      expect(words, isNot(en.sangatUnavailable));
      expect(words, en.sangatBusy);
    });
  });

  group('two causes never share one sentence', () {
    // THE guard. Run it in all three languages, because a translation that
    // collapses two strings is the same bug arriving by another route, and
    // l10n_test cannot see it -- it checks that keys exist, not that their
    // values differ.
    for (final code in ['en', 'pa', 'hi']) {
      test('in $code', () {
        final l = lookupL(Locale(code));

        // Every outcome that carries a message of its own. LinkDidNotWork is
        // out: all four of its problems share one heading on purpose, and
        // the card below it is what tells them apart -- which the next group
        // checks. JoinedSangat is out because success says nothing.
        final outcomes = <JoinOutcome>[
          const SangatUnavailable(),
          const SangatBusy(),
          const SangatRefused('permission-denied'),
          const EmailAlreadyHasAccount('a@b.c'),
          const JoinFailed('some-code'),
        ];

        final said = outcomes.map((o) => wordsForOutcome(o, l)).toList();
        expect(
          said.toSet().length,
          said.length,
          reason: 'two outcomes say the same thing in $code, so at least one '
              'of them is telling somebody to do the wrong thing: $said',
        );
        expect(said.any((s) => s.isEmpty), isFalse,
            reason: 'a failure with nothing to say is a blank error box');
      });
    }

    test('the list above covers every outcome', () {
      // A sealed switch, so a new outcome will not compile until it is named
      // here -- which is what stops the guard above quietly going stale.
      String name(JoinOutcome o) => switch (o) {
            JoinedSangat() => 'joined',
            LinkDidNotWork() => 'link',
            SangatUnavailable() => 'unavailable',
            SangatBusy() => 'busy',
            SangatRefused() => 'refused',
            EmailAlreadyHasAccount() => 'exists',
            JoinFailed() => 'failed',
          };

      const every = <JoinOutcome>[
        JoinedSangat(SangatAccount(id: '', name: '', city: '')),
        LinkDidNotWork(LinkProblem.expired),
        SangatUnavailable(),
        SangatBusy(),
        SangatRefused('x'),
        EmailAlreadyHasAccount('a@b.c'),
        JoinFailed('x'),
      ];

      expect(every.map(name).toSet().length, every.length);
    });
  });

  group('the four link problems stay apart', () {
    // Two of them mean send another link; two mean that sending another will
    // not help. invalid-email and invalid-action-code shared a branch until
    // 2026-09-27, so somebody whose address did not match was told the link
    // was already used, and asked for another, and another.
    for (final code in ['en', 'pa', 'hi']) {
      test('in $code', () {
        final l = lookupL(Locale(code));
        final said = LinkProblem.values
            .map((p) => wordsForLinkProblem(p, l))
            .map((pair) => '${pair.$1}|${pair.$2}')
            .toList();
        expect(said.toSet().length, said.length,
            reason: 'two link problems read identically in $code: $said');
      });
    }

    test('a mismatched address is not a used link', () {
      expect(linkProblemForAuthCode('invalid-email'),
          LinkProblem.addressMismatch);
      expect(linkProblemForAuthCode('invalid-action-code'),
          LinkProblem.alreadyUsed);
      expect(linkProblemForAuthCode('expired-action-code'),
          LinkProblem.expired);
      expect(linkProblemForAuthCode('network-request-failed'), isNull,
          reason: 'a network failure is not a problem with the link');
    });
  });
}
