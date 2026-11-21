import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/settings_controller.dart';

/// What the phone remembers when it can no longer see a profile it had, so
/// "No profile found" is never the whole answer (01-accounts §8.3 R6, R7;
/// owner's report, 2026-11-21).
///
/// - [lostEmail]: the email of a profile this phone showed that the server
///   no longer gives it (the install's identity changed, or the profile moved
///   to another phone). The Profile screen offers to bring it back.
/// - [pendingEmail]: a restore link sent and not yet opened. The Profile
///   screen says it is waiting, with Resend.
///
/// Both are cleared the moment a profile loads.
class ProfileRecovery {
  const ProfileRecovery({this.lostName, this.lostEmail, this.pendingEmail, this.pendingAt});

  final String? lostName;
  final String? lostEmail;
  final String? pendingEmail;
  final DateTime? pendingAt;

  /// A restore link lives an hour (RESTORE_TOKEN_TTL_SECONDS).
  static const linkLife = Duration(hours: 1);

  bool waiting(DateTime now) => pendingEmail != null && pendingAt != null && now.difference(pendingAt!) < linkLife;

  /// The email to bring a profile back with: the one a link went to, else
  /// the lost profile's.
  String? get email => pendingEmail ?? lostEmail;
}

class ProfileRecoveryNotifier extends Notifier<ProfileRecovery> {
  static const kLost = 'profile_lost_v1';
  static const kPending = 'restore_pending_v1';

  @override
  ProfileRecovery build() {
    final prefs = ref.read(sharedPreferencesProvider);
    Map<String, Object?>? read(String k) {
      try {
        final raw = prefs.getString(k);
        return raw == null ? null : jsonDecode(raw) as Map<String, Object?>;
      } on Object {
        return null;
      }
    }

    final lost = read(kLost);
    final pending = read(kPending);
    final at = pending?['at'];
    return ProfileRecovery(
      lostName: lost?['name'] as String?,
      lostEmail: lost?['email'] as String?,
      pendingEmail: pending?['email'] as String?,
      pendingAt: at is int ? DateTime.fromMillisecondsSinceEpoch(at) : null,
    );
  }

  /// A profile with an email that this phone can no longer see.
  Future<void> rememberLost({required String name, required String? email}) async {
    if (email == null || email.isEmpty) return;
    await ref.read(sharedPreferencesProvider).setString(kLost, jsonEncode({'name': name, 'email': email}));
    ref.invalidateSelf();
  }

  /// A restore link went to [email] just now.
  Future<void> linkSent(String email) async {
    await ref
        .read(sharedPreferencesProvider)
        .setString(kPending, jsonEncode({'email': email, 'at': DateTime.now().millisecondsSinceEpoch}));
    ref.invalidateSelf();
  }

  /// A profile is on the phone again: nothing to recover.
  Future<void> clear() async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (!prefs.containsKey(kLost) && !prefs.containsKey(kPending)) return;
    await prefs.remove(kLost);
    await prefs.remove(kPending);
    ref.invalidateSelf();
  }
}

final profileRecoveryProvider =
    NotifierProvider<ProfileRecoveryNotifier, ProfileRecovery>(ProfileRecoveryNotifier.new);
