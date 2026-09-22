import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../domain/simran_presence.dart';
import 'presence_repository.dart';

/// Presence on Firestore, counted by city.
///
/// The cost model is the whole design. One document per city per day means
/// the globe reads once per *active city* — a few hundred at worst — rather
/// than once per person, which at a hundred thousand users would be a hundred
/// thousand reads every time somebody opened Simran. The headline number is a
/// single `sum()` on top of that.
class FirebasePresenceRepository implements PresenceRepository {
  FirebasePresenceRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    DateTime Function()? now,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance,
        _now = now ?? DateTime.now;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final DateTime Function() _now;

  /// The most cities a globe will draw. Past this the dots overlap anyway,
  /// and the total still comes from the aggregation, which sees all of them.
  static const _maxCities = 300;

  /// The day key, in the phone's own local date.
  ///
  /// Deliberately local rather than UTC: "here today" means the day the
  /// person is living in, and everybody in one city shares it. The cost is
  /// that the world's day boundary is ragged, which nobody can see.
  static String dayKey(DateTime local) =>
      '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';

  CollectionReference<Map<String, Object?>> get _today =>
      _db.collection('presence').doc(dayKey(_now())).collection('cities');

  @override
  Future<SangatPresence> today() async {
    if (_auth.currentUser == null) return SangatPresence.empty;
    var total = 0;
    var cities = <PresenceCity>[];
    var failed = false;
    try {
      final counted = await _today.aggregate(sum('count')).get();
      total = (counted.getSum('count') ?? 0).toInt();
    } on FirebaseException catch (e) {
      failed = true;
      debugPrint('Hazri: presence total failed (${e.code})');
    }
    try {
      final snap = await _today
          .orderBy('count', descending: true)
          .limit(_maxCities)
          .get();
      cities = snap.docs
          .map((d) => PresenceCity.fromFirestore(d.id, d.data()))
          .whereType<PresenceCity>()
          .toList();
    } on FirebaseException catch (e) {
      failed = true;
      debugPrint('Hazri: presence cities failed (${e.code})');
    }
    return SangatPresence(
      cities: cities,
      total: total,
      unreachable: failed,
      yours: _markedToday ? 1 : 0,
      yourCityId: _markedToday ? _markedCity : null,
    );
  }

  /// The day this phone last added itself, or null.
  ///
  /// Held in memory rather than on the server: it exists only so the screen
  /// can say "47 others" instead of counting somebody as their own company,
  /// and a wrong answer after a restart is off by one on a number nobody is
  /// auditing. Storing the day rather than a flag is what makes it roll over
  /// at midnight without anything having to notice.
  String? _markedDay;
  String? _markedCity;

  bool get _markedToday => _markedDay == dayKey(_now());

  @override
  Future<void> markSitting({
    required String cityId,
    required String cityName,
    required double lat,
    required double lon,
  }) async {
    if (_auth.currentUser == null) return;
    final day = dayKey(_now());
    try {
      final doc = _today.doc(cityId);
      // The rules accept exactly +1 and nothing else, so this is an update
      // first and a create only if the city is not there yet.
      await doc.update({'count': FieldValue.increment(1)});
      _markedDay = day;
      _markedCity = cityId;
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
        try {
          await _today.doc(cityId).set({
            'city': cityName,
            'lat': lat,
            'lon': lon,
            'count': 1,
          });
          _markedDay = day;
          _markedCity = cityId;
        } on FirebaseException catch (e2) {
          debugPrint('Hazri: first sitting in $cityId failed (${e2.code})');
        }
      } else {
        debugPrint('Hazri: marking sitting failed (${e.code})');
      }
    }
  }
}
