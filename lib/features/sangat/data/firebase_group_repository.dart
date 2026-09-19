import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../domain/sangat_group.dart';
import 'group_repository.dart';

/// Groups on Firestore.
///
/// **Every number on these screens is counted, not stored.** `count()` and
/// `sum()` aggregation queries give the member count and the group total
/// without a Cloud Function, which Spark does not have, and without a
/// counter field on the group document — which every member can write, and
/// therefore every member could lie about. An aggregation costs one read per
/// thousand documents, so a 200-member group is a single read.
class FirebaseGroupRepository implements GroupRepository {
  FirebaseGroupRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, Object?>> get _groups => _db.collection('groups');

  CollectionReference<Map<String, Object?>> _members(String groupId) =>
      _groups.doc(groupId).collection('members');

  @override
  Stream<List<SangatGroup>> watchMine() {
    final uid = _uid;
    if (uid == null) return Stream.value(const []);
    // A collection-group query over the membership rows is what makes "my
    // groups" one query rather than one per group. It needs the composite
    // index Firestore offers on first run.
    return _db
        .collectionGroup('members')
        .where(FieldPath.documentId, isEqualTo: uid)
        .snapshots()
        .asyncMap((snap) async {
      final groups = <SangatGroup>[];
      for (final doc in snap.docs) {
        final groupId = doc.reference.parent.parent?.id;
        if (groupId == null) continue;
        final group = await _load(groupId, mine: doc.data());
        if (group != null) groups.add(group);
      }
      return groups;
    }).handleError((Object e) {
      debugPrint('Hazri: my groups failed ($e)');
    });
  }

  @override
  Future<List<SangatGroup>> listed({int limit = 12}) async {
    try {
      final snap =
          await _groups.where('listed', isEqualTo: true).limit(limit).get();
      final out = <SangatGroup>[];
      for (final doc in snap.docs) {
        final group = await _withCounts(SangatGroup.fromFirestore(doc.id, doc.data()));
        out.add(group);
      }
      return out;
    } on FirebaseException catch (e) {
      debugPrint('Hazri: listed groups failed (${e.code})');
      return const [];
    }
  }

  @override
  Stream<SangatGroup?> watchGroup(String groupId) => _groups
          .doc(groupId)
          .snapshots()
          .asyncMap((snap) async {
        final data = snap.data();
        if (data == null) return null;
        return _withCounts(SangatGroup.fromFirestore(groupId, data));
      }).handleError((Object e) {
        debugPrint('Hazri: group $groupId failed ($e)');
      });

  @override
  Stream<List<GroupMember>> watchMembers(String groupId) => _members(groupId)
      .orderBy('count', descending: true)
      .limit(100)
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => GroupMember.fromFirestore(d.id, d.data())).toList())
      .handleError((Object e) {
        debugPrint('Hazri: members of $groupId failed ($e)');
      });

  @override
  Future<GroupOutcome> create({
    required String name,
    required GroupKind kind,
  }) async {
    final uid = _uid;
    if (uid == null) return const GroupRefused('unauthenticated');
    try {
      final group = SangatGroup(
        id: '',
        name: name.trim(),
        kind: kind,
        createdBy: uid,
      );
      final doc = _groups.doc();
      await doc.set({
        ...group.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      // The maker is the admin. The rules allow the claim only because they
      // check `createdBy` on the group itself, so a second person joining
      // cannot make the same one.
      await _members(doc.id).doc(uid).set({
        'name': await _myName(),
        'role': 'admin',
        'count': 0,
        'joinedAt': FieldValue.serverTimestamp(),
      });
      return GroupOk(group.copyWith(memberCount: 1, youAreAdmin: true));
    } on FirebaseException catch (e) {
      return _outcome(e, 'create group');
    }
  }

  @override
  Future<GroupOutcome> join(String groupId) async {
    final uid = _uid;
    if (uid == null) return const GroupRefused('unauthenticated');
    try {
      final group = await _groups.doc(groupId).get();
      if (!group.exists) return const GroupNotFound();
      await _members(groupId).doc(uid).set({
        'name': await _myName(),
        'role': 'member',
        'count': 0,
        'joinedAt': FieldValue.serverTimestamp(),
      });
      return const GroupOk();
    } on FirebaseException catch (e) {
      return _outcome(e, 'join group');
    }
  }

  @override
  Future<GroupOutcome> logPaath(String groupId, int amount) async {
    final uid = _uid;
    if (uid == null) return const GroupRefused('unauthenticated');
    if (amount <= 0) return const GroupFailed('nothing to add');
    try {
      await _members(groupId).doc(uid).update({
        'count': FieldValue.increment(amount),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return const GroupOk();
    } on FirebaseException catch (e) {
      return _outcome(e, 'log paath');
    }
  }

  @override
  Future<GroupOutcome> setGoal(String groupId, GroupGoal goal) async {
    try {
      await _groups.doc(groupId).update({'goal': goal.toFirestore()});
      return const GroupOk();
    } on FirebaseException catch (e) {
      return _outcome(e, 'set goal');
    }
  }

  @override
  Future<GroupOutcome> leave(String groupId) async {
    final uid = _uid;
    if (uid == null) return const GroupRefused('unauthenticated');
    try {
      await _members(groupId).doc(uid).delete();
      return const GroupOk();
    } on FirebaseException catch (e) {
      return _outcome(e, 'leave group');
    }
  }

  /// Loads a group and hangs this person's own membership off it.
  Future<SangatGroup?> _load(String groupId, {Map<String, Object?>? mine}) async {
    try {
      final snap = await _groups.doc(groupId).get();
      final data = snap.data();
      if (data == null) return null;
      var group = SangatGroup.fromFirestore(groupId, data);
      if (mine != null) {
        group = group.copyWith(
          yours: ((mine['count'] as num?) ?? 0).toInt(),
          youAreAdmin: mine['role'] == 'admin',
        );
      }
      return await _withCounts(group);
    } on FirebaseException catch (e) {
      debugPrint('Hazri: loading group $groupId failed (${e.code})');
      return null;
    }
  }

  /// The two aggregation queries. Both are allowed to fail quietly: a group
  /// with no numbers on it still shows its name and its members, which is
  /// better than an error where a card should be.
  Future<SangatGroup> _withCounts(SangatGroup group) async {
    var out = group;
    try {
      final members = await _members(group.id).count().get();
      out = out.copyWith(memberCount: members.count ?? 0);
    } on FirebaseException catch (e) {
      debugPrint('Hazri: member count failed (${e.code})');
    }
    try {
      final total = await _members(group.id).aggregate(sum('count')).get();
      out = out.copyWith(total: (total.getSum('count') ?? 0).toInt());
    } on FirebaseException catch (e) {
      debugPrint('Hazri: group total failed (${e.code})');
    }
    return out;
  }

  /// The name this person shows inside groups, or empty if they turned it
  /// off. Read from their own profile, which only they can read.
  Future<String> _myName() async {
    final uid = _uid;
    if (uid == null) return '';
    try {
      final me = await _db.collection('users').doc(uid).get();
      final data = me.data();
      if (data == null) return '';
      if ((data['showName'] as bool?) == false) return '';
      return (data['name'] as String?) ?? '';
    } on FirebaseException {
      return '';
    }
  }

  GroupOutcome _outcome(FirebaseException e, String what) {
    switch (e.code) {
      case 'permission-denied':
      case 'unauthenticated':
        debugPrint('Hazri: $what REFUSED by rules (${e.code}). '
            'Is the current firestore.rules published to this project?');
        return GroupRefused(e.code);
      case 'not-found':
        return const GroupNotFound();
      case 'unavailable':
      case 'deadline-exceeded':
      case 'network-request-failed':
        return const GroupUnavailable();
      default:
        debugPrint('Hazri: $what failed (${e.code})');
        return GroupFailed(e.code);
    }
  }
}
