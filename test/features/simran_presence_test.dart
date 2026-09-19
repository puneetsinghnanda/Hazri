import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/features/sangat/data/firebase_presence_repository.dart';
import 'package:hazri/features/sangat/data/presence_repository.dart';
import 'package:hazri/features/sangat/domain/simran_presence.dart';

/// The globe's arithmetic, and the promise underneath it: cities, never
/// people.
void main() {
  group('what the screen says', () {
    test('nobody else is "you are the first", not "0 others"', () {
      const alone = SangatPresence(total: 1, yours: 1);
      expect(alone.others, 0);
      expect(alone.isQuiet, isTrue);
    });

    test('you are never counted as your own company', () {
      const forty8 = SangatPresence(total: 48, yours: 1);
      expect(forty8.others, 47);
      expect(forty8.isQuiet, isFalse);
    });

    test('a total behind the phone does not go negative', () {
      // The total is read and the mark is local, so they can disagree for a
      // moment. "-1 others" must never reach the screen.
      const skewed = SangatPresence(total: 0, yours: 1);
      expect(skewed.others, 0);
      expect(skewed.isQuiet, isTrue);
    });
  });

  group('a city on the globe', () {
    test('needs a position, and is dropped rather than drawn at 0,0', () {
      expect(PresenceCity.fromFirestore('x', const {'city': 'Nowhere'}), isNull);
      expect(
        PresenceCity.fromFirestore('x', const {'city': 'Amritsar', 'lat': 31.6, 'lon': 74.9}),
        isNotNull,
      );
    });

    test('carries no person, by construction', () {
      final city = PresenceCity.fromFirestore('amritsar', const {
        'city': 'Amritsar',
        'lat': 31.63,
        'lon': 74.87,
        'count': 3,
        // Anything else the server grew is ignored rather than carried into
        // the app.
        'uid': 'somebody',
        'name': 'Harjit Singh',
      })!;
      expect(city.count, 3);
      expect(city.name, 'Amritsar');
    });
  });

  group('the day key', () {
    test('is the phone\'s own local date, padded', () {
      expect(FirebasePresenceRepository.dayKey(DateTime(2026, 1, 9)), '2026-01-09');
      expect(FirebasePresenceRepository.dayKey(DateTime(2026, 11, 20)), '2026-11-20');
    });

    test('rolls at local midnight, not at some other day boundary', () {
      expect(FirebasePresenceRepository.dayKey(DateTime(2026, 11, 20, 23, 59)), '2026-11-20');
      expect(FirebasePresenceRepository.dayKey(DateTime(2026, 11, 21, 0, 1)), '2026-11-21');
    });
  });

  group('with no server', () {
    test('the globe is quiet and nothing is sent', () async {
      const repo = NoPresenceRepository();
      expect((await repo.today()).isQuiet, isTrue);
      await expectLater(
        repo.markSitting(cityId: 'amritsar', cityName: 'Amritsar', lat: 31.6, lon: 74.9),
        completes,
      );
    });
  });
}
