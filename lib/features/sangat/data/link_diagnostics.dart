import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/settings/settings_controller.dart';

/// What route the app was opened on, written down so somebody can read it.
///
/// A tapped link crosses four systems before any Dart runs: Android matches
/// the intent-filter, verifies `assetlinks.json`, launches the activity, and
/// Flutter hands the URL to the router. When the result is "it opened and did
/// nothing", every one of those is still a candidate and **none of them says
/// anything** — there is no error, no log a reader can reach, and no
/// difference on screen between a link that never arrived and a link that
/// arrived and was mishandled.
///
/// So the first route of each app start is recorded. `/today` means Flutter
/// was never given the link and the fault is on the Android side of the
/// boundary; `/__/auth/action?...` means it arrived and the fault is ours.
/// One line, and it halves the search.
///
/// It holds a route, not content: no address, no code, nothing that leaves
/// the phone.
class LinkDiagnostics {
  LinkDiagnostics(this._prefs);

  static const _key = 'last_opened_with';

  final SharedPreferences _prefs;
  bool _recordedThisRun = false;

  /// The first route of this app start, and only the first — later
  /// navigation is the reader moving around, which is not the question.
  void recordFirst(String route) {
    if (_recordedThisRun) return;
    _recordedThisRun = true;
    _prefs.setString(_key, route);
  }

  /// What the last app start began with, or null before there has been one.
  String? get lastOpenedWith => _prefs.getString(_key);
}

final linkDiagnosticsProvider = Provider<LinkDiagnostics>(
  (ref) => LinkDiagnostics(ref.read(sharedPreferencesProvider)),
);
