import 'package:flutter/foundation.dart';

/// What kind of sitting a live group is (15-live-sangat LS1).
enum LiveKind { meditation, jaap }

/// The scene a live group draws (LS1, LS12).
enum LiveScene { globe, ikonkar, jot }

/// One of the three live groups, as the app ships it (LS1). The recording is
/// bundled under `assets/live/` and built by `tools/live/build_loops.py`,
/// with its seam crossfaded into the file so it loops without a gap.
@immutable
class LiveGroupDef {
  const LiveGroupDef({
    required this.id,
    required this.kind,
    required this.scene,
    required this.length,
    required this.latin,
    required this.gurmukhi,
    required this.devanagari,
  });

  final String id;
  final LiveKind kind;
  final LiveScene scene;

  /// The loop's length, read from the built file (ffprobe).
  final Duration length;

  /// The name is a proper noun by script, as a badge's is.
  final String latin;
  final String gurmukhi;
  final String devanagari;

  String get assetPath => 'assets/live/$id.m4a';

  /// The media session's id, so it never collides with a bani's slug.
  String get slug => 'live-$id';

  String nameFor(String languageCode) => switch (languageCode) {
        'pa' => gurmukhi,
        'hi' => devanagari,
        _ => latin,
      };
}

const liveGroups = <LiveGroupDef>[
  LiveGroupDef(
    id: 'naam-simran',
    kind: LiveKind.meditation,
    scene: LiveScene.globe,
    length: Duration(milliseconds: 56000),
    latin: 'Naam Simran',
    gurmukhi: 'ਨਾਮ ਸਿਮਰਨ',
    devanagari: 'नाम सिमरन',
  ),
  LiveGroupDef(
    id: 'mool-mantar',
    kind: LiveKind.meditation,
    scene: LiveScene.ikonkar,
    length: Duration(milliseconds: 128650),
    latin: 'Mool Mantar',
    gurmukhi: 'ਮੂਲ ਮੰਤਰ',
    devanagari: 'मूल मंत्र',
  ),
  LiveGroupDef(
    id: 'chaupai-sahib',
    kind: LiveKind.jaap,
    scene: LiveScene.jot,
    length: Duration(milliseconds: 208037),
    latin: 'Chaupai Sahib',
    gurmukhi: 'ਚੌਪਈ ਸਾਹਿਬ',
    devanagari: 'चौपई साहिब',
  ),
];

LiveGroupDef? liveGroupById(String id) {
  for (final g in liveGroups) {
    if (g.id == id) return g;
  }
  return null;
}

/// Where in the loop every phone is at [now] (LS6): the time since 00:00 IST
/// modulo the loop's length, so two phones with the right time play the same
/// second.
Duration liveOffset(DateTime now, Duration length) {
  const ist = Duration(hours: 5, minutes: 30);
  const day = Duration.millisecondsPerDay;
  final sinceMidnight = (now.toUtc().add(ist).millisecondsSinceEpoch % day + day) % day;
  return Duration(milliseconds: sinceMidnight % length.inMilliseconds);
}

/// Somebody who joined, as the feed shows them (LS8).
@immutable
class LiveJoin {
  const LiveJoin({required this.name, this.cityId, this.at});

  final String name;
  final String? cityId;
  final DateTime? at;

  factory LiveJoin.fromJson(Map<String, Object?> j) => LiveJoin(
        name: '${j['name'] ?? ''}',
        cityId: j['cityId'] as String?,
        at: DateTime.tryParse('${j['at']}'),
      );
}

/// A member row of the group sheet (LS9).
@immutable
class LiveMember {
  const LiveMember({required this.name, this.cityId, this.minutesMonth = 0});

  final String name;
  final String? cityId;
  final int minutesMonth;

  factory LiveMember.fromJson(Map<String, Object?> j) => LiveMember(
        name: '${j['name'] ?? ''}',
        cityId: j['cityId'] as String?,
        minutesMonth: (j['minutesMonth'] as num?)?.toInt() ?? 0,
      );
}

/// One live group as GET /live answers it (ARCHITECTURE §6.8).
@immutable
class LiveGroupStatus {
  const LiveGroupStatus({
    required this.id,
    this.listening = 0,
    this.cities = 0,
    this.cityIds = const [],
    this.members = 0,
    this.minutesToday = 0,
    this.minutesMonth = 0,
    this.joins = const [],
    this.memberRows = const [],
    this.joined = false,
    this.youCounted = false,
  });

  final String id;
  final int listening;
  final int cities;

  /// The cities with a listener now, for the globe (LS1).
  final List<String> cityIds;
  final int members;
  final int minutesToday;
  final int minutesMonth;
  final List<LiveJoin> joins;
  final List<LiveMember> memberRows;
  final bool joined;

  /// The server's count already includes the caller (LS7b).
  final bool youCounted;

  LiveGroupStatus copyWith({bool? joined, int? members}) => LiveGroupStatus(
        id: id,
        listening: listening,
        cities: cities,
        cityIds: cityIds,
        members: members ?? this.members,
        minutesToday: minutesToday,
        minutesMonth: minutesMonth,
        joins: joins,
        memberRows: memberRows,
        joined: joined ?? this.joined,
        youCounted: youCounted,
      );

  factory LiveGroupStatus.fromJson(Map<String, Object?> j) {
    int n(String k) => (j[k] as num?)?.toInt() ?? 0;
    List<Map<String, Object?>> list(String k) => (j[k] as List<Object?>? ?? const []).cast<Map<String, Object?>>();
    return LiveGroupStatus(
      id: '${j['id']}',
      listening: n('listening'),
      cities: n('cities'),
      cityIds: [for (final c in (j['cityIds'] as List<Object?>? ?? const [])) '$c'],
      members: n('members'),
      minutesToday: n('minutesToday'),
      minutesMonth: n('minutesMonth'),
      joins: [for (final e in list('joins')) LiveJoin.fromJson(e)],
      memberRows: [for (final e in list('memberRows')) LiveMember.fromJson(e)],
      joined: j['joined'] == true,
      youCounted: j['youCounted'] == true,
    );
  }
}

/// How long a listener stays in a live group's count after they listened
/// (owner, 2026-11-19): a day, on the phone as on the server.
const liveCountedFor = Duration(hours: 24);

/// A live group's count and cities as shown on this phone (LS7b): the
/// server's, plus you when you listened in the last day and the server's
/// count does not hold you yet. Without a profile the server never counts
/// you, so you are added for as long as the day lasts; with one, only until
/// the server's next count has your listening mark in it.
({int listening, int cities, List<String> cityIds}) liveShown(
  LiveGroupStatus g, {
  required DateTime? heardAt,
  required DateTime now,
  String? yourCityId,
}) {
  final addMe = heardAt != null && now.difference(heardAt) < liveCountedFor && !g.youCounted;
  if (!addMe) return (listening: g.listening, cities: g.cities, cityIds: g.cityIds);
  final newCity = yourCityId != null && !g.cityIds.contains(yourCityId);
  return (
    listening: g.listening + 1,
    cities: g.cities + (newCity ? 1 : 0),
    cityIds: newCity ? [...g.cityIds, yourCityId] : g.cityIds,
  );
}
