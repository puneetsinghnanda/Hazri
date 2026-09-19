import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/sangat_group.dart';
import 'account_repository.dart';

/// Reading and changing the groups somebody is in.
///
/// Separate from [AccountRepository] because the two fail differently: an
/// account is one document this phone owns, a group is shared and can be left,
/// renamed or deleted by somebody else while this screen is open.
abstract interface class GroupRepository {
  /// The groups this person belongs to. Empty for everybody who has joined
  /// the sangat but not a group, which is a normal place to stay.
  Stream<List<SangatGroup>> watchMine();

  /// The groups anybody may join — the reviewed, listed ones. Read without
  /// belonging to them, which is the one thing a non-member may read.
  Future<List<SangatGroup>> listed({int limit = 12});

  /// One group with its counts, or null if it is gone or not ours to see.
  Stream<SangatGroup?> watchGroup(String groupId);

  /// Who is in it, best contributor first.
  Stream<List<GroupMember>> watchMembers(String groupId);

  /// Makes a group and puts the maker in it as its admin. Always private:
  /// `listed` is refused by the rules and set out of band after review.
  Future<GroupOutcome> create({required String name, required GroupKind kind});

  Future<GroupOutcome> join(String groupId);

  /// Adds to this person's own count. [amount] is paath, or minutes for a
  /// circle. Never writes anybody else's row — the rules would refuse it.
  Future<GroupOutcome> logPaath(String groupId, int amount);

  /// Admin only. The goal is what the group is reciting together.
  Future<GroupOutcome> setGoal(String groupId, GroupGoal goal);

  Future<GroupOutcome> leave(String groupId);
}

/// What happened. Same shape as [JoinOutcome] and for the same reason: every
/// one of these is an ordinary Tuesday, not an exception.
sealed class GroupOutcome {
  const GroupOutcome();
}

class GroupOk extends GroupOutcome {
  const GroupOk([this.group]);
  final SangatGroup? group;
}

/// Could not be reached — offline, or no backend in this build.
class GroupUnavailable extends GroupOutcome {
  const GroupUnavailable();
}

/// Reached, and refused. Nearly always our rules rather than the person.
class GroupRefused extends GroupOutcome {
  const GroupRefused(this.code);
  final String code;
}

/// The link or code does not lead anywhere.
class GroupNotFound extends GroupOutcome {
  const GroupNotFound();
}

class GroupFailed extends GroupOutcome {
  const GroupFailed(this.message);
  final String message;
}

/// The groups of somebody with no server: nobody, and nothing works.
class NoGroupRepository implements GroupRepository {
  const NoGroupRepository();

  @override
  Stream<List<SangatGroup>> watchMine() => const Stream.empty();

  @override
  Future<List<SangatGroup>> listed({int limit = 12}) async => const [];

  @override
  Stream<SangatGroup?> watchGroup(String groupId) => const Stream.empty();

  @override
  Stream<List<GroupMember>> watchMembers(String groupId) => const Stream.empty();

  @override
  Future<GroupOutcome> create({required String name, required GroupKind kind}) async =>
      const GroupUnavailable();

  @override
  Future<GroupOutcome> join(String groupId) async => const GroupUnavailable();

  @override
  Future<GroupOutcome> logPaath(String groupId, int amount) async =>
      const GroupUnavailable();

  @override
  Future<GroupOutcome> setGoal(String groupId, GroupGoal goal) async =>
      const GroupUnavailable();

  @override
  Future<GroupOutcome> leave(String groupId) async => const GroupUnavailable();
}

/// Overridden in `main.dart` when the backend came up.
final groupRepositoryProvider =
    Provider<GroupRepository>((ref) => const NoGroupRepository());

/// The groups this person is in. Watches the account too, so signing out
/// empties it rather than leaving somebody else's groups on screen.
final myGroupsProvider = StreamProvider<List<SangatGroup>>((ref) {
  final account = ref.watch(sangatAccountProvider).value;
  if (account == null) return Stream.value(const <SangatGroup>[]);
  return ref.watch(groupRepositoryProvider).watchMine();
});

/// The reviewed groups anybody may join.
final listedGroupsProvider = FutureProvider<List<SangatGroup>>((ref) {
  final account = ref.watch(sangatAccountProvider).value;
  if (account == null) return Future.value(const <SangatGroup>[]);
  return ref.watch(groupRepositoryProvider).listed();
});

final groupProvider = StreamProvider.family<SangatGroup?, String>(
  (ref, id) => ref.watch(groupRepositoryProvider).watchGroup(id),
);

final groupMembersProvider = StreamProvider.family<List<GroupMember>, String>(
  (ref, id) => ref.watch(groupRepositoryProvider).watchMembers(id),
);
