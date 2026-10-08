import 'package:flutter/foundation.dart';

/// The Sangat's server shapes (ARCHITECTURE §6.3, `functions/src/sangat/
/// model.ts`), read-only on the phone (08-sangat CT8).
@immutable
class SangatGoal {
  const SangatGoal({
    required this.goalId,
    required this.type,
    this.baniId,
    this.simranMinutes,
    required this.target,
    required this.startDay,
    required this.endDay,
    required this.status,
    required this.total,
    required this.pct,
    required this.todayTotal,
    required this.daysLeft,
  });

  final String goalId;

  /// `BANI` or `SIMRAN`.
  final String type;
  final String? baniId;
  final int? simranMinutes;
  final int target;
  final String startDay;
  final String endDay;

  /// `ACTIVE`, `COMPLETED` or `EXPIRED`.
  final String status;
  final int total;
  final int pct;
  final int todayTotal;
  final int daysLeft;

  bool get isSimran => type == 'SIMRAN';

  factory SangatGoal.fromJson(Map<String, Object?> j) => SangatGoal(
        goalId: j['goalId']! as String,
        type: j['type']! as String,
        baniId: j['baniId'] as String?,
        simranMinutes: (j['simranMinutes'] as num?)?.toInt(),
        target: (j['target']! as num).toInt(),
        startDay: j['startDay']! as String,
        endDay: j['endDay']! as String,
        status: j['status']! as String,
        total: (j['total'] as num?)?.toInt() ?? 0,
        pct: (j['pct'] as num?)?.toInt() ?? 0,
        todayTotal: (j['todayTotal'] as num?)?.toInt() ?? 0,
        daysLeft: (j['daysLeft'] as num?)?.toInt() ?? 0,
      );
}

@immutable
class SangatMember {
  const SangatMember({
    required this.memberKey,
    this.name,
    required this.role,
    required this.status,
    required this.contribution,
    required this.isYou,
  });

  final String memberKey;

  /// Null for a member with no profile: "Sangat member" (MB1).
  final String? name;
  final String role;
  final String status;
  final int contribution;
  final bool isYou;

  bool get isCreator => role == 'CREATOR';
  bool get hasLeft => status != 'ACTIVE';

  factory SangatMember.fromJson(Map<String, Object?> j) => SangatMember(
        memberKey: j['memberKey']! as String,
        name: j['name'] as String?,
        role: (j['role'] as String?) ?? 'MEMBER',
        status: (j['status'] as String?) ?? 'ACTIVE',
        contribution: (j['contribution'] as num?)?.toInt() ?? 0,
        isYou: j['isYou'] == true,
      );
}

@immutable
class SangatInvite {
  const SangatInvite({required this.code, required this.link, this.expiresAt});

  /// `XXXX-XXXX`.
  final String code;
  final String link;
  final String? expiresAt;

  factory SangatInvite.fromJson(Map<String, Object?> j) => SangatInvite(
        code: j['code']! as String,
        link: j['link']! as String,
        expiresAt: j['expiresAt'] as String?,
      );
}

/// A group in a list (7.1, 7.2), or in full with members (7.3).
@immutable
class SangatGroup {
  const SangatGroup({
    required this.groupId,
    required this.kind,
    this.name,
    this.names,
    required this.status,
    this.endedOn,
    required this.memberCount,
    required this.isMember,
    this.role,
    this.goal,
    this.members = const [],
    this.moreMembers = 0,
    this.invite,
  });

  final String groupId;

  /// `BUILT_IN` or `CUSTOM`.
  final String kind;
  final String? name;

  /// Built-in groups: the name in each language (BI1).
  final Map<String, String>? names;

  /// `ACTIVE` or `INACTIVE`.
  final String status;
  final String? endedOn;
  final int memberCount;
  final bool isMember;
  final String? role;
  final SangatGoal? goal;
  final List<SangatMember> members;
  final int moreMembers;
  final SangatInvite? invite;

  bool get isBuiltIn => kind == 'BUILT_IN';
  bool get isActive => status == 'ACTIVE';
  bool get isCreator => role == 'CREATOR';

  String displayName(String lang) => names?[lang] ?? names?['en'] ?? name ?? '';

  factory SangatGroup.fromJson(Map<String, Object?> j) {
    final names = j['names'];
    final goal = j['goal'];
    final invite = j['invite'];
    return SangatGroup(
      groupId: j['groupId']! as String,
      kind: j['kind']! as String,
      name: j['name'] as String?,
      names: names is Map<String, Object?> ? {for (final e in names.entries) e.key: '${e.value}'} : null,
      status: (j['status'] as String?) ?? 'ACTIVE',
      endedOn: j['endedOn'] as String?,
      memberCount: (j['memberCount'] as num?)?.toInt() ?? 0,
      isMember: j['isMember'] == true,
      role: j['role'] as String?,
      goal: goal is Map<String, Object?> ? SangatGoal.fromJson(goal) : null,
      members: [
        for (final m in (j['members'] as List<Object?>? ?? const []).cast<Map<String, Object?>>())
          SangatMember.fromJson(m),
      ],
      moreMembers: (j['moreMembers'] as num?)?.toInt() ?? 0,
      invite: invite is Map<String, Object?> ? SangatInvite.fromJson(invite) : null,
    );
  }
}

/// IV7: a code typed or pasted, with or without the hyphen, in any case;
/// null when it cannot be one. Normalised to `XXXXXXXX`.
String? normalizeInviteCode(String raw) {
  final s = raw.toUpperCase().replaceAll(RegExp(r'[\s-]'), '');
  return RegExp(r'^[ABCDEFGHJKMNPQRSTUVWXYZ23456789]{8}$').hasMatch(s) ? s : null;
}

/// `XXXX-XXXX` for display.
String formatInviteCode(String code) => code.length == 8 ? '${code.substring(0, 4)}-${code.substring(4)}' : code;
