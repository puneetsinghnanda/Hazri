import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The server half of Hazri, behind an interface.
///
/// Phase 1 had no server at all. Phase 2 adds one, and the app has to keep
/// being honest about the fact that it is optional: every bani, its
/// recitation, the calendar and the diary are on the phone, so a person whose
/// backend never starts should notice nothing except that the sangat is
/// quiet. That is not a graceful-degradation nicety bolted on afterwards —
/// it is why this is an interface with an offline implementation, and why
/// nothing in the app is allowed to assume [isUp].
///
/// It also has to survive the billing kill switch (see
/// `design/review/phase2-setup.html`): cutting the project's billing stops
/// the server dead, and the app must carry on regardless.
///
/// Behind an interface for the same reason as `SystemSettings` and
/// `HukamnamaSource`: the iOS app in Phase 3 needs a new adapter, not a
/// rewrite (PRD §6.4).
abstract interface class Backend {
  /// Whether the server is reachable and initialised on this run.
  ///
  /// False in tests, on a device where start-up failed, and for anybody who
  /// has not joined the sangat. Never assume otherwise.
  bool get isUp;

  /// Brings the backend up. Never throws: a failure here means [isUp] stays
  /// false and the app runs as Phase 1 did.
  Future<void> start();

  /// Turns usage reporting on or off, honouring `analytics_enabled`
  /// (PRD §13). Off is the default and stays the default.
  Future<void> setAnalyticsEnabled(bool enabled);
}

/// What the app gets when there is no server: in tests, in a widget harness,
/// and on a device where Firebase failed to start.
///
/// Every method is a no-op that succeeds, so calling code never needs a null
/// check or a try/catch around the backend.
class OfflineBackend implements Backend {
  const OfflineBackend();

  @override
  bool get isUp => false;

  @override
  Future<void> start() async {}

  @override
  Future<void> setAnalyticsEnabled(bool enabled) async {}
}

/// The backend for this run.
///
/// Defaults to [OfflineBackend] so that a test, a widget harness or a
/// screenshot run gets a working app with no server rather than an error.
/// `main()` overrides it with the real one.
final backendProvider = Provider<Backend>((ref) => const OfflineBackend());

/// The one host the app's links point at.
///
/// Firebase Hosting, served from `public/` in this repository and deployed
/// with `firebase deploy --only hosting`. It is the project's own free
/// `<project>.web.app` domain, which costs nothing and is a domain we
/// control -- the two things a link host has to be.
///
/// It has to be Firebase Hosting rather than anywhere else. Since Dynamic
/// Links shut down on 2025-08-25, Firebase Auth mints its email links on a
/// Firebase Hosting domain and nothing else, so hosting these pages beside
/// them keeps one host, one deploy and one `assetlinks.json` to serve when
/// Phase 3's keystore makes the links tappable.
///
/// A real domain in Phase 3 is added *alongside* this, not instead of it:
/// App Links accept several hosts, and a link already sitting in somebody's
/// inbox must not stop working.
const String kSiteBase = 'https://hazri-dfcc1.web.app';

/// Where the email verification link lands.
const String kVerificationUrl = '$kSiteBase/verify';

/// The website's account deletion page, which Google Play asks an app with
/// accounts to link from inside it (`01-accounts.md` §12, 2026-10-30).
///
/// On hazri.me, **not** [kSiteBase]: the manifest claims every path on
/// [kSiteBase] as an App Link with no path filter, so opening this there would
/// hand the link straight back to Hazri instead of a browser.
/// `test/core/delete_account_link_test.dart` holds that.
const String kDeleteAccountUrl = 'https://hazri.me/delete-account';
