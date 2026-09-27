import '../../../core/l10n/gen/app_localizations.dart';
import '../data/account_repository.dart';

/// What the reader is told about a [JoinOutcome] that is not success.
///
/// One function, used by every screen that reports one, because there were
/// three copies of this switch and they had already drifted: two of them
/// rendered [JoinFailed] as "could not reach the sangat", so a project
/// setting nobody had switched on in the console came out as a sentence
/// about the reader's wifi.
///
/// **Two outcomes must never produce the same words.** That is not a style
/// preference: a message shared by two causes tells somebody to do the wrong
/// thing about at least one of them, and it is what made the first real
/// verification attempt undiagnosable. `join_outcome_words_test.dart` holds
/// the rule, and it has been watched failing.
String wordsForOutcome(JoinOutcome outcome, L l) => switch (outcome) {
      // Success says nothing; the screen moves on instead.
      JoinedSangat() => '',
      LinkDidNotWork() => l.linkProblemTitle,
      EmailAlreadyHasAccount() => l.sangatEmailInUse,
      SangatUnavailable() => l.sangatUnavailable,
      SangatBusy() => l.sangatBusy,
      SangatRefused() => l.sangatRefused,
      // The code travels to the screen. Without it every unmapped failure
      // reads as a flat tyre, and the one thing that would identify it has
      // been thrown away by the time anybody is asked what they saw.
      JoinFailed(message: final code) => l.sangatFailed(code),
    };
