import 'dart:async';

import 'package:hazri/features/sangat/data/group_repository.dart';
import 'package:hazri/features/sangat/domain/sangat_group.dart';

/// Groups with no Firestore behind them.
///
/// Like the account fake, it can be told to fail in each of the ways the real
/// one can, because what these screens say when a write is refused is the
/// part worth testing.
class FakeGroupRepository implements GroupRepository {
  FakeGroupRepository({
    List<SangatGroup> mine = const [],
    this.listedGroups = const [],
    List<GroupMember> members = const [],
  })  : _mine = [...mine],
        _members = [...members];

  final List<SangatGroup> _mine;
  final List<GroupMember> _members;
  final List<SangatGroup> listedGroups;

  final _mineController = StreamController<List<SangatGroup>>.broadcast();

  /// The next answer from every write. Null means success.
  GroupOutcome? nextOutcome;

  final joined = <String>[];
  final logged = <(String, int)>[];
  final goalsSet = <(String, GroupGoal)>[];
  final left = <String>[];
  SangatGroup? created;

  @override
  Stream<List<SangatGroup>> watchMine() async* {
    yield List.unmodifiable(_mine);
    yield* _mineController.stream;
  }

  @override
  Future<List<SangatGroup>> listed({int limit = 12}) async => listedGroups;

  @override
  Stream<SangatGroup?> watchGroup(String groupId) => Stream.value(
        _mine.where((g) => g.id == groupId).firstOrNull,
      );

  @override
  Stream<List<GroupMember>> watchMembers(String groupId) =>
      Stream.value(List.unmodifiable(_members));

  @override
  Future<GroupOutcome> create({required String name, required GroupKind kind}) async {
    final failure = nextOutcome;
    if (failure != null) return failure;
    final group = SangatGroup(
      id: 'made-1',
      name: name,
      kind: kind,
      createdBy: 'uid-test',
      memberCount: 1,
      youAreAdmin: true,
    );
    created = group;
    _mine.add(group);
    _mineController.add(List.unmodifiable(_mine));
    return GroupOk(group);
  }

  @override
  Future<GroupOutcome> join(String groupId) async {
    final failure = nextOutcome;
    if (failure != null) return failure;
    joined.add(groupId);
    return const GroupOk();
  }

  @override
  Future<GroupOutcome> logPaath(String groupId, int amount) async {
    final failure = nextOutcome;
    if (failure != null) return failure;
    logged.add((groupId, amount));
    return const GroupOk();
  }

  @override
  Future<GroupOutcome> setGoal(String groupId, GroupGoal goal) async {
    final failure = nextOutcome;
    if (failure != null) return failure;
    goalsSet.add((groupId, goal));
    return const GroupOk();
  }

  @override
  Future<GroupOutcome> leave(String groupId) async {
    final failure = nextOutcome;
    if (failure != null) return failure;
    left.add(groupId);
    return const GroupOk();
  }

  void dispose() => _mineController.close();
}
