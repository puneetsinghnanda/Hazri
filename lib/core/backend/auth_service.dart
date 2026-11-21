import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_exception.dart';

/// The install's identity: Firebase Anonymous Auth, signed in silently.
///
/// There is no sign-in screen and no password, ever (CLAUDE.md rule 4). The
/// anonymous uid identifies this install; a profile, if the reader makes one,
/// is owned by exactly one uid at a time (`01-accounts.md` §1).
abstract interface class AuthService {
  /// Signs in anonymously if nobody is signed in. Throws [NetworkException]
  /// when that needs a network the phone does not have.
  Future<void> ensureSignedIn();

  /// The ID token for the `Authorization` header.
  Future<String> idToken({bool forceRefresh = false});

  /// The current uid, or null before the first sign-in.
  String? get uid;
}

/// Runs one sign-in at a time: every caller that arrives while one is in
/// flight waits for that same one (01-accounts §8.3 R5, 2026-11-21).
///
/// Without it, the profile, the Sangat, the globe and the library could each
/// find nobody signed in at the same moment and each call
/// `signInAnonymously`, which makes a separate anonymous account per call.
/// Whichever finished last became the install, and a profile made under one
/// of the others looked gone: "No profile found".
class SignInOnce {
  Future<void>? _inFlight;

  Future<void> run(Future<void> Function() signIn) {
    final running = _inFlight;
    if (running != null) return running;
    final f = signIn();
    _inFlight = f;
    // Cleared when it ends, so a failed attempt (offline) can be tried again.
    f.then((_) => _inFlight = null, onError: (Object _) => _inFlight = null);
    return f;
  }
}

/// Firebase's adapter (`01-accounts.md` §8.2).
class FirebaseAuthService implements AuthService {
  FirebaseAuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;
  final _once = SignInOnce();

  @override
  String? get uid => _auth.currentUser?.uid;

  @override
  Future<void> ensureSignedIn() {
    if (_auth.currentUser != null) return Future.value();
    return _once.run(() async {
      // Somebody may have signed in while this waited its turn.
      if (_auth.currentUser != null) return;
      try {
        await _auth.signInAnonymously();
      } on FirebaseAuthException catch (e) {
        throw NetworkException(e.code);
      }
    });
  }

  @override
  Future<String> idToken({bool forceRefresh = false}) async {
    await ensureSignedIn();
    try {
      final token = await _auth.currentUser!.getIdToken(forceRefresh);
      if (token == null) throw const NetworkException('no-id-token');
      return token;
    } on FirebaseAuthException catch (e) {
      throw NetworkException(e.code);
    }
  }
}

/// No server on this run (tests, a device where Firebase failed to start):
/// every call fails as though offline, which every caller already handles.
class OfflineAuthService implements AuthService {
  const OfflineAuthService();

  @override
  String? get uid => null;

  @override
  Future<void> ensureSignedIn() async => throw const NetworkException('offline');

  @override
  Future<String> idToken({bool forceRefresh = false}) async =>
      throw const NetworkException('offline');
}

/// Overridden in `main()` with [FirebaseAuthService] when the backend is up.
final authServiceProvider = Provider<AuthService>((ref) => const OfflineAuthService());
