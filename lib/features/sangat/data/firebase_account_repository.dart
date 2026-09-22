import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../domain/sangat_account.dart';
import 'account_repository.dart';

/// The Firebase account adapter.
///
/// Nothing here runs on start-up. The first call is [join], made when
/// somebody taps Set up, and it is the first network request this app makes
/// on that phone.
class FirebaseAccountRepository implements AccountRepository {
  FirebaseAccountRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    required this.verificationUrl,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  /// Where the verification link lands. Phase 2 uses the project's free
  /// `<project>.web.app` host, which is a domain we control and therefore
  /// enough for Android App Links; the real domain is added in Phase 3
  /// without anything here changing.
  final String verificationUrl;

  SangatAccount? _current;

  @override
  SangatAccount? get current => _current;

  @override
  Stream<SangatAccount?> watch() =>
      _auth.authStateChanges().asyncExpand((user) {
        if (user == null) {
          _current = null;
          return Stream<SangatAccount?>.value(null);
        }
        return _db.collection('users').doc(user.uid).snapshots().map((snap) {
          final data = snap.data();
          if (data == null) return null;
          // `emailVerified` lives on the auth user, not in Firestore, so a
          // phone cannot mark itself verified by writing a document. The rules
          // refuse the field too; this is the belt to that pair of braces.
          _current = SangatAccount.fromFirestore(
            user.uid,
            data,
            emailVerified: user.emailVerified,
          );
          return _current;
        });
      });

  @override
  Future<JoinOutcome> join({
    required String name,
    required String email,
    required String city,
    String? phone,
  }) async {
    try {
      // Anonymous first: the account exists before the profile does, so a
      // failure halfway leaves a signed-in user with no row rather than a row
      // nobody owns.
      final credential = await _auth.signInAnonymously();
      final uid = credential.user?.uid;
      if (uid == null) return const JoinFailed('no uid after anonymous sign-in');

      final account = SangatAccount(
        id: uid,
        name: name.trim(),
        city: city.trim(),
        email: email.trim().isEmpty ? null : email.trim(),
        phone: (phone?.trim().isEmpty ?? true) ? null : phone!.trim(),
      );
      await _db.collection('users').doc(uid).set({
        ...account.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _current = account;
      return JoinedSangat(account);
    } on FirebaseAuthException catch (e) {
      return _authOutcome(e, email);
    } on FirebaseException catch (e) {
      return _firestoreOutcome(e, 'join');
    }
  }

  @override
  Future<JoinOutcome> updateProfile(SangatAccount account) async {
    try {
      await _db.collection('users').doc(account.id).update({
        ...account.toFirestore(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _current = account;
      return JoinedSangat(account);
    } on FirebaseException catch (e) {
      return _firestoreOutcome(e, 'profile update');
    }
  }

  @override
  Future<JoinOutcome> sendVerificationLink(String email) async {
    final user = _auth.currentUser;
    if (user == null) return const JoinFailed('not signed in');
    try {
      await _auth.sendSignInLinkToEmail(
        email: email.trim(),
        actionCodeSettings: ActionCodeSettings(
          url: verificationUrl,
          handleCodeInApp: true,
          androidPackageName: 'app.hazri',
          androidInstallApp: false,
          androidMinimumVersion: '24',
        ),
      );
      return JoinedSangat(_current ??
          SangatAccount(id: user.uid, name: '', city: '', email: email));
    } on FirebaseAuthException catch (e) {
      return _authOutcome(e, email);
    }
  }

  @override
  Future<JoinOutcome> continueWithLink({
    required String email,
    required String link,
  }) async {
    final address = email.trim();
    if (!_auth.isSignInWithEmailLink(link.trim())) {
      return const LinkDidNotWork(LinkProblem.wrongAddress);
    }
    final credential = EmailAuthProvider.credentialWithLink(
      email: address,
      emailLink: link.trim(),
    );
    final user = _auth.currentUser;
    try {
      if (user != null && user.isAnonymous) {
        // Verifying: the anonymous account keeps its uid, so every group,
        // count and diary entry on this phone stays attached to it.
        final linked = await user.linkWithCredential(credential);
        return JoinedSangat(await _accountFor(linked.user!, address));
      }
      // Restoring on a fresh phone: this signs into the account the address
      // already has. Nothing is signed out anywhere else -- the same account
      // can be on two phones at once, which is what design 53 promises.
      final signedIn = await _auth.signInWithCredential(credential);
      return JoinedSangat(await _accountFor(signedIn.user!, address));
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-action-code':
        case 'invalid-email':
          return const LinkDidNotWork(LinkProblem.alreadyUsed);
        case 'expired-action-code':
          return const LinkDidNotWork(LinkProblem.expired);
        case 'credential-already-in-use':
        case 'email-already-in-use':
          // The address belongs to an account that is not this anonymous
          // one. Signing in with it is the restore, and it is what the
          // person asked for by pasting the link.
          try {
            final signedIn = await _auth.signInWithCredential(credential);
            return JoinedSangat(await _accountFor(signedIn.user!, address));
          } on FirebaseAuthException catch (e2) {
            return _authOutcome(e2, address);
          }
        default:
          return _authOutcome(e, address);
      }
    } on FirebaseException catch (e) {
      return _firestoreOutcome(e, 'continue with link');
    }
  }

  /// The profile behind a user, creating a bare one if this phone has never
  /// written it. A restored account nearly always has one already.
  Future<SangatAccount> _accountFor(User user, String email) async {
    try {
      final snap = await _db.collection('users').doc(user.uid).get();
      final data = snap.data();
      if (data != null) {
        _current = SangatAccount.fromFirestore(
          user.uid,
          data,
          emailVerified: user.emailVerified,
        );
        return _current!;
      }
    } on FirebaseException catch (e) {
      debugPrint('Hazri: reading restored profile failed (${e.code})');
    }
    _current = SangatAccount(
      id: user.uid,
      name: '',
      city: '',
      email: email,
      emailVerified: user.emailVerified,
    );
    return _current!;
  }

  @override
  Future<JoinOutcome> deleteEverything() async {
    final user = _auth.currentUser;
    if (user == null) return const JoinedSangat(SangatAccount(id: '', name: '', city: ''));
    try {
      // Memberships first. They live under groups this person does not own,
      // so leaving one behind would leave a name in somebody else's group
      // with no account behind it. The account's own list is what says which
      // ones those are -- a collection-group query over every membership in
      // the project needs an index and a rule that do not exist, and returns
      // nothing at all until they do.
      final me = await _db.collection('users').doc(user.uid).get();
      final groupIds = [
        for (final v in (me.data()?['groups'] as List<Object?>? ?? const []))
          if (v is String) v,
      ];
      for (final groupId in groupIds) {
        await _db
            .collection('groups')
            .doc(groupId)
            .collection('members')
            .doc(user.uid)
            .delete();
      }
      // The synced diary, if sync was ever on. Firestore does not delete a
      // subcollection with its parent, so without this every day design 49
      // uploaded stayed on the server after "delete everything".
      final diary =
          await _db.collection('users').doc(user.uid).collection('diary').get();
      for (final day in diary.docs) {
        await day.reference.delete();
      }
      await _db.collection('users').doc(user.uid).delete();
    } on FirebaseException catch (e) {
      return _firestoreOutcome(e, 'delete account');
    }
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      // The row is already gone, so the account is unreachable either way.
      // Saying it failed here would be worse than true.
      debugPrint('Hazri: deleting the auth user failed (${e.code})');
      await _auth.signOut();
    }
    _current = null;
    return const JoinedSangat(SangatAccount(id: '', name: '', city: ''));
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _current = null;
    } on FirebaseException catch (e) {
      debugPrint('Hazri: sign out failed (${e.code})');
    }
  }

  /// Separates "we could not reach it" from "it said no".
  ///
  /// They look identical from inside a catch and mean opposite things: one is
  /// a train tunnel and the other is a bug in our rules. Reporting the second
  /// as the first sends somebody to check their wifi while the fault sits in
  /// a file nobody deployed.
  JoinOutcome _firestoreOutcome(FirebaseException e, String what) {
    switch (e.code) {
      case 'permission-denied':
      case 'unauthenticated':
        // The rules refused it. In Phase 2 this nearly always means
        // firestore.rules has not been published to the project, which leaves
        // the production-mode default of deny-everything in force.
        debugPrint('Hazri: $what REFUSED by rules (${e.code}). '
            'Is firestore.rules published to this project?');
        return SangatRefused(e.code);
      case 'unavailable':
      case 'deadline-exceeded':
      case 'network-request-failed':
        debugPrint('Hazri: $what could not reach Firestore (${e.code})');
        return const SangatUnavailable();
      default:
        debugPrint('Hazri: $what failed (${e.code})');
        return JoinFailed(e.code);
    }
  }

  /// Turns an auth error into something a screen can say out loud.
  JoinOutcome _authOutcome(FirebaseAuthException e, String email) {
    switch (e.code) {
      // The address already belongs to somebody — screen 53's fork, not a
      // failure.
      case 'email-already-in-use':
      case 'credential-already-in-use':
      case 'account-exists-with-different-credential':
        return EmailAlreadyHasAccount(email.trim());
      case 'network-request-failed':
      case 'too-many-requests':
        return const SangatUnavailable();
      default:
        debugPrint('Hazri: auth error (${e.code})');
        return JoinFailed(e.code);
    }
  }
}
