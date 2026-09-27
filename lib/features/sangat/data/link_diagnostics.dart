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

  /// Records a route worth remembering.
  ///
  /// The first version recorded only the first route of each app start,
  /// which turned out to report the wrong thing entirely: the activity is
  /// `singleTask`, so a tapped link arrives at an app that is **already
  /// running**, and the first route of that run is whatever the launcher
  /// icon opened. A reader checking after a failed tap saw `Opened with: /`,
  /// which is true and useless.
  ///
  /// So a route that came from outside the app always wins, however late it
  /// arrives -- those are the ones with a scheme, because Android hands over
  /// a whole URL -- and the first route of the run is kept only until one
  /// does.
  void record(String route) {
    final external = route.startsWith('http') || route.contains('://');
    if (!external && _recordedThisRun) return;
    _recordedThisRun = true;
    _prefs.setString(_key, route);
  }

  /// What the last app start began with, or null before there has been one.
  String? get lastOpenedWith => _prefs.getString(_key);

  static const _authKey = 'last_auth_state';

  /// What the Firebase auth user actually looks like: ids and booleans, never
  /// the address. Written whenever the account stream sees a user.
  ///
  /// Here because "it says verified on one screen and not on the next" took
  /// three rounds to pin down, and every round was me reasoning about which
  /// of two booleans Firebase sets rather than reading one off the phone.
  void recordAuth(String summary) => _prefs.setString(_authKey, summary);

  String? get lastAuthState => _prefs.getString(_authKey);
}

final linkDiagnosticsProvider = Provider<LinkDiagnostics>(
  (ref) => LinkDiagnostics(ref.read(sharedPreferencesProvider)),
);
