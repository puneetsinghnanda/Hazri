import 'package:flutter/foundation.dart';

/// One city with somebody sitting in it today.
///
/// There is no person in this class and there never will be: the globe shows
/// cities, and a city is the finest thing the app knows about anybody's
/// position because a city is what they chose themselves (PRD §13).
@immutable
class PresenceCity {
  const PresenceCity({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
    required this.count,
  });

  final String id;
  final String name;
  final double lat;
  final double lon;

  /// How many sat here today. One is the commonest answer and is not a
  /// smaller dot for it.
  final int count;

  static PresenceCity? fromFirestore(String id, Map<String, Object?> data) {
    final lat = (data['lat'] as num?)?.toDouble();
    final lon = (data['lon'] as num?)?.toDouble();
    if (lat == null || lon == null) return null;
    return PresenceCity(
      id: id,
      name: (data['city'] as String?) ?? '',
      lat: lat,
      lon: lon,
      count: ((data['count'] as num?) ?? 0).toInt(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PresenceCity &&
      other.id == id &&
      other.name == name &&
      other.lat == lat &&
      other.lon == lon &&
      other.count == count;

  @override
  int get hashCode => Object.hash(id, name, lat, lon, count);
}

/// Who is sitting today, worldwide.
@immutable
class SangatPresence {
  const SangatPresence({
    this.cities = const [],
    this.total = 0,
    this.yours = 0,
    this.yourCityId,
  });

  final List<PresenceCity> cities;

  /// Everybody, including this person.
  final int total;

  /// What this phone added today. Subtracted from [total] to say "47 others",
  /// so nobody is ever counted as their own company.
  final int yours;

  /// The city this person chose, so the globe can light theirs differently
  /// (design 29's legend). Null before they have sat anywhere.
  final String? yourCityId;

  /// What the screen says: everybody but you.
  int get others => (total - yours).clamp(0, total);

  /// Nothing to show yet — a new app, or a quiet hour. The screen says
  /// something true rather than a hopeful zero.
  bool get isQuiet => others <= 0;

  static const empty = SangatPresence();
}
