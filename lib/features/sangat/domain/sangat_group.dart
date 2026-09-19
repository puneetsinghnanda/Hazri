import 'package:flutter/foundation.dart';

/// What a group counts, and what it is for.
///
/// The kind is not decoration: a simran circle counts minutes and everything
/// else counts paath, and that one difference runs through the goal, the
/// member rows and every number on screen.
enum GroupKind {
  family,
  sangat,
  circle;

  bool get countsMinutes => this == GroupKind.circle;

  static GroupKind parse(String? v) => GroupKind.values.firstWhere(
        (k) => k.name == v,
        orElse: () => GroupKind.family,
      );
}

/// What a group is reciting together, and by when.
///
/// [target] is in the group's unit — paath for a family or a sangat, minutes
/// for a circle. [endsAt] is optional because "no end date" is a legitimate
/// answer on design 40 and the commonest one for a family.
@immutable
class GroupGoal {
  const GroupGoal({
    required this.slug,
    required this.target,
    this.endsAt,
    this.occasion,
  });

  /// The bani, or `simran` for a circle's minutes.
  final String slug;
  final int target;
  final DateTime? endsAt;

  /// The Gurpurab the date was picked from, if it was. Kept so the group
  /// sees "Prakash Purab, Guru Nanak Dev Ji" rather than a bare date.
  final String? occasion;

  Map<String, Object?> toFirestore() => {
        'slug': slug,
        'target': target,
        if (endsAt != null) 'endsAt': endsAt!.toUtc().toIso8601String(),
        if (occasion != null) 'occasion': occasion,
      };

  static GroupGoal? fromFirestore(Map<String, Object?>? data) {
    if (data == null) return null;
    final slug = data['slug'] as String?;
    final target = (data['target'] as num?)?.toInt();
    if (slug == null || target == null) return null;
    return GroupGoal(
      slug: slug,
      target: target,
      endsAt: DateTime.tryParse((data['endsAt'] as String?) ?? ''),
      occasion: data['occasion'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is GroupGoal &&
      other.slug == slug &&
      other.target == target &&
      other.endsAt == endsAt &&
      other.occasion == occasion;

  @override
  int get hashCode => Object.hash(slug, target, endsAt, occasion);
}

/// One group in the sangat.
///
/// [memberCount] and [total] are counted rather than stored: Firestore's
/// aggregation queries answer both without a server, and a stored counter on
/// a document every member can write is a number every member can lie about.
/// Phase 2 has no Cloud Functions to keep an honest one.
@immutable
class SangatGroup {
  const SangatGroup({
    required this.id,
    required this.name,
    required this.kind,
    required this.createdBy,
    this.listed = false,
    this.goal,
    this.memberCount = 0,
    this.total = 0,
    this.yours = 0,
    this.youAreAdmin = false,
  });

  final String id;
  final String name;
  final GroupKind kind;
  final String createdBy;

  /// Whether the group appears under "Groups you can join". A phone can never
  /// set this — `firestore.rules` refuses the field on create and on update,
  /// because a listed group's name is read by people who never met whoever
  /// chose it.
  final bool listed;

  final GroupGoal? goal;

  /// Counted with an aggregation query, not read from the document.
  final int memberCount;

  /// What the group has done together, in the group's unit.
  final int total;

  /// What this person has contributed to that total.
  final int yours;

  final bool youAreAdmin;

  bool get countsMinutes => kind.countsMinutes;

  /// 0..1, or null when there is no goal to be a fraction of.
  double? get progress {
    final g = goal;
    if (g == null || g.target <= 0) return null;
    return (total / g.target).clamp(0.0, 1.0);
  }

  /// Whole per cent, for the ring on design 38.
  int? get percent {
    final p = progress;
    return p == null ? null : (p * 100).round();
  }

  SangatGroup copyWith({
    String? name,
    GroupGoal? goal,
    int? memberCount,
    int? total,
    int? yours,
    bool? youAreAdmin,
  }) =>
      SangatGroup(
        id: id,
        name: name ?? this.name,
        kind: kind,
        createdBy: createdBy,
        listed: listed,
        goal: goal ?? this.goal,
        memberCount: memberCount ?? this.memberCount,
        total: total ?? this.total,
        yours: yours ?? this.yours,
        youAreAdmin: youAreAdmin ?? this.youAreAdmin,
      );

  /// What a phone may write. `listed` is absent by design, and so is anything
  /// counted: the rules refuse both.
  Map<String, Object?> toFirestore() => {
        'name': name,
        'kind': kind.name,
        'createdBy': createdBy,
        'listed': false,
        if (goal != null) 'goal': goal!.toFirestore(),
      };

  static SangatGroup fromFirestore(String id, Map<String, Object?> data) =>
      SangatGroup(
        id: id,
        name: (data['name'] as String?) ?? '',
        kind: GroupKind.parse(data['kind'] as String?),
        createdBy: (data['createdBy'] as String?) ?? '',
        listed: (data['listed'] as bool?) ?? false,
        goal: GroupGoal.fromFirestore(data['goal'] as Map<String, Object?>?),
      );

  @override
  bool operator ==(Object other) =>
      other is SangatGroup &&
      other.id == id &&
      other.name == name &&
      other.kind == kind &&
      other.listed == listed &&
      other.goal == goal &&
      other.memberCount == memberCount &&
      other.total == total &&
      other.yours == yours &&
      other.youAreAdmin == youAreAdmin;

  @override
  int get hashCode => Object.hash(
      id, name, kind, listed, goal, memberCount, total, yours, youAreAdmin);
}

/// One person inside a group.
///
/// The name lives here rather than being read off the member's profile: the
/// rules let a group's members read this subcollection and nothing else, so
/// joining a group never opens anybody's account row to the people in it.
@immutable
class GroupMember {
  const GroupMember({
    required this.uid,
    required this.name,
    this.count = 0,
    this.isAdmin = false,
    this.joinedAt,
  });

  final String uid;

  /// Empty when the person turned their name off (screen 35). The UI says
  /// "a member" rather than inventing one.
  final String name;

  final int count;
  final bool isAdmin;
  final DateTime? joinedAt;

  Map<String, Object?> toFirestore() => {
        'name': name,
        'role': isAdmin ? 'admin' : 'member',
        'count': count,
      };

  static GroupMember fromFirestore(String uid, Map<String, Object?> data) =>
      GroupMember(
        uid: uid,
        name: (data['name'] as String?) ?? '',
        count: ((data['count'] as num?) ?? 0).toInt(),
        isAdmin: data['role'] == 'admin',
        joinedAt: DateTime.tryParse((data['joinedAt'] as String?) ?? ''),
      );

  @override
  bool operator ==(Object other) =>
      other is GroupMember &&
      other.uid == uid &&
      other.name == name &&
      other.count == count &&
      other.isAdmin == isAdmin;

  @override
  int get hashCode => Object.hash(uid, name, count, isAdmin);
}
