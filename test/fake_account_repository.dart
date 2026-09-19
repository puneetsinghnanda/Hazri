import 'dart:async';

import 'package:hazri/features/sangat/data/account_repository.dart';
import 'package:hazri/features/sangat/domain/sangat_account.dart';

/// An account layer with no Firebase behind it.
///
/// It is deliberately more than a stub: it records what it was asked to do
/// and can be told to fail in each of the ways the real one can, because the
/// interesting question for these screens is not "does it work" but "what
/// does it say when it does not".
class FakeAccountRepository implements AccountRepository {
  FakeAccountRepository({SangatAccount? account}) : _account = account {
    _controller.add(_account);
  }

  final _controller = StreamController<SangatAccount?>.broadcast();
  SangatAccount? _account;

  /// The next answer from [join], [updateProfile] and [sendVerificationLink].
  /// Null means success.
  JoinOutcome? nextOutcome;

  final sentTo = <String>[];
  final savedProfiles = <SangatAccount>[];
  int signOutCalls = 0;

  @override
  SangatAccount? get current => _account;

  @override
  Stream<SangatAccount?> watch() async* {
    yield _account;
    yield* _controller.stream;
  }

  void emit(SangatAccount? account) {
    _account = account;
    _controller.add(account);
  }

  @override
  Future<JoinOutcome> join({
    required String name,
    required String email,
    required String city,
    String? phone,
  }) async {
    final failure = nextOutcome;
    if (failure != null) return failure;
    final account =
        SangatAccount(id: 'uid-test', name: name, city: city, email: email, phone: phone);
    emit(account);
    return JoinedSangat(account);
  }

  @override
  Future<JoinOutcome> updateProfile(SangatAccount account) async {
    final failure = nextOutcome;
    if (failure != null) return failure;
    savedProfiles.add(account);
    emit(account);
    return JoinedSangat(account);
  }

  @override
  Future<JoinOutcome> sendVerificationLink(String email) async {
    final failure = nextOutcome;
    if (failure != null) return failure;
    sentTo.add(email);
    return JoinedSangat(_account ??
        SangatAccount(id: 'uid-test', name: '', city: '', email: email));
  }

  final linksTried = <String>[];

  @override
  Future<JoinOutcome> continueWithLink({
    required String email,
    required String link,
  }) async {
    linksTried.add(link);
    final failure = nextOutcome;
    if (failure != null) return failure;
    final account = (_account ??
            SangatAccount(id: 'uid-test', name: '', city: '', email: email))
        .copyWith(email: email, emailVerified: true);
    emit(account);
    return JoinedSangat(account);
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    emit(null);
  }

  void dispose() => _controller.close();
}
