import 'dart:math' as math;

/// Sunrise and sunset for a place and date, using the NOAA solar equations.
///
/// Implemented in Dart rather than fetched, so Auto reminder times work with
/// no network (PRD §4.2). Results are UTC instants; callers convert to the
/// device's local time.
abstract final class SolarService {
  /// The standard refraction-corrected solar zenith for sunrise and sunset.
  static const double _zenith = 90.833;

  static double _rad(double deg) => deg * math.pi / 180;

  static double _deg(double rad) => rad * 180 / math.pi;

  /// Julian day for midday UT on [date], which keeps the century term centred
  /// on the day being asked about.
  static double _julianDay(DateTime date) {
    var y = date.year;
    var m = date.month;
    final d = date.day;
    if (m <= 2) {
      y -= 1;
      m += 12;
    }
    final a = (y / 100).floor();
    final b = 2 - a + (a / 4).floor();
    return (365.25 * (y + 4716)).floor() +
        (30.6001 * (m + 1)).floor() +
        d +
        b -
        1524.5 +
        0.5;
  }

  /// Sunrise and sunset in UTC, or null where the sun does not rise or set
  /// that day (inside the polar circles).
  static ({DateTime? sunrise, DateTime? sunset, DateTime solarNoon}) events({
    required DateTime date,
    required double latitude,
    required double longitude,
  }) {
    final jd = _julianDay(date);
    final t = (jd - 2451545.0) / 36525.0;

    final l0 = (280.46646 + t * (36000.76983 + t * 0.0003032)) % 360;
    final m = 357.52911 + t * (35999.05029 - 0.0001537 * t);
    final e = 0.016708634 - t * (0.000042037 + 0.0000001267 * t);

    final c = math.sin(_rad(m)) * (1.914602 - t * (0.004817 + 0.000014 * t)) +
        math.sin(_rad(2 * m)) * (0.019993 - 0.000101 * t) +
        math.sin(_rad(3 * m)) * 0.000289;

    final trueLong = l0 + c;
    final omega = 125.04 - 1934.136 * t;
    final lambda = trueLong - 0.00569 - 0.00478 * math.sin(_rad(omega));

    final seconds = 21.448 - t * (46.8150 + t * (0.00059 - t * 0.001813));
    final e0 = 23 + (26 + seconds / 60) / 60;
    final oblCorr = e0 + 0.00256 * math.cos(_rad(omega));

    final decl = math.asin(math.sin(_rad(oblCorr)) * math.sin(_rad(lambda)));

    final y = math.tan(_rad(oblCorr / 2)) * math.tan(_rad(oblCorr / 2));
    final eqTime = 4 *
        _deg(y * math.sin(2 * _rad(l0)) -
            2 * e * math.sin(_rad(m)) +
            4 * e * y * math.sin(_rad(m)) * math.cos(2 * _rad(l0)) -
            0.5 * y * y * math.sin(4 * _rad(l0)) -
            1.25 * e * e * math.sin(2 * _rad(m)));

    // Minutes from UTC midnight.
    final noonMinutes = 720 - 4 * longitude - eqTime;

    final cosH = math.cos(_rad(_zenith)) /
            (math.cos(_rad(latitude)) * math.cos(decl)) -
        math.tan(_rad(latitude)) * math.tan(decl);

    DateTime atMinutes(double minutes) => DateTime.utc(date.year, date.month, date.day)
        .add(Duration(milliseconds: (minutes * 60000).round()));

    if (cosH < -1 || cosH > 1) {
      return (sunrise: null, sunset: null, solarNoon: atMinutes(noonMinutes));
    }

    final ha = _deg(math.acos(cosH));
    return (
      sunrise: atMinutes(noonMinutes - 4 * ha),
      sunset: atMinutes(noonMinutes + 4 * ha),
      solarNoon: atMinutes(noonMinutes),
    );
  }

  static DateTime? sunrise(DateTime date, double lat, double lon) =>
      events(date: date, latitude: lat, longitude: lon).sunrise;

  static DateTime? sunset(DateTime date, double lat, double lon) =>
      events(date: date, latitude: lat, longitude: lon).sunset;
}

/// Rounds a time to the nearest [step] minutes, as the Auto reminder rules
/// require (PRD 1.10).
DateTime roundToNearestMinutes(DateTime t, int step) {
  final minutes = t.hour * 60 + t.minute + (t.second >= 30 ? 1 : 0);
  final rounded = ((minutes / step).round() * step);
  final base = DateTime(t.year, t.month, t.day);
  return base.add(Duration(minutes: rounded));
}
