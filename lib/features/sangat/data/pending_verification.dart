import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/settings/settings_controller.dart';

/// The address a verification link was last sent to.
///
/// Firebase needs the email address back when the link is followed —
/// `signInWithEmailLink` takes both, so that a link intercepted in transit is
/// useless without knowing who it was for. On the phone that asked for the
/// link, the account already holds the address. **On a phone restoring, it
/// does not**: there is no account yet, which is the entire point of
/// restoring, so unless the address was written down before the link went out
/// there is nothing to pair it with and the person has to type it again from
/// memory at the worst possible moment.
///
/// So it is written before the send and read when the link comes back. It is
/// the reader's own address on their own phone, never sent anywhere, and it
/// is cleared the moment it has been used.
class PendingVerification {
  const PendingVerification(this._prefs);

  static const _key = 'pending_verification_email';

  final SharedPreferences _prefs;

  /// Remembered just before a link is sent.
  Future<void> remember(String email) =>
      _prefs.setString(_key, email.trim());

  /// The address a link was last sent to on this phone, or null.
  String? get address {
    final saved = _prefs.getString(_key);
    return (saved == null || saved.isEmpty) ? null : saved;
  }

  /// Forgotten once the link has been used, or the flow abandoned. Leaving it
  /// behind would mean the next link tried against a stale address.
  Future<void> forget() => _prefs.remove(_key);
}

final pendingVerificationProvider = Provider<PendingVerification>(
  (ref) => PendingVerification(ref.read(sharedPreferencesProvider)),
);
