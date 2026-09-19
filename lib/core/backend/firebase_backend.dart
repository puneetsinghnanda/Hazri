import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'backend.dart';

/// The Firebase adapter.
///
/// Start-up is deliberately forgiving. A phone with no Play Services, a
/// corrupted config, a device clock so wrong that certificates fail — none of
/// those should stop somebody reading Japji Sahib, so every failure here ends
/// in [isUp] staying false rather than in an exception reaching `main()`.
class FirebaseBackend implements Backend {
  FirebaseBackend();

  bool _up = false;

  @override
  bool get isUp => _up;

  @override
  Future<void> start() async {
    try {
      await Firebase.initializeApp();
      // Reporting stays off until the person turns it on. `analytics_enabled`
      // already defaults to false (PRD §13), and this makes the SDK agree
      // with the setting before it has had a chance to send anything.
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(false);
      _up = true;
    } on Exception catch (e) {
      // Includes the case where google-services.json is missing or does not
      // match the package: the app runs, the sangat does not.
      debugPrint('Hazri: backend unavailable, sangat disabled ($e)');
      _up = false;
    }
  }

  @override
  Future<void> setAnalyticsEnabled(bool enabled) async {
    if (!_up) return;
    try {
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(enabled);
    } on Exception catch (e) {
      debugPrint('Hazri: could not change analytics collection ($e)');
    }
  }
}
