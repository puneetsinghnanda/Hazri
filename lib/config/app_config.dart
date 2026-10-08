import '../core/backend/backend.dart' show kSiteBase;

/// Every environment-specific value of the app, in one file
/// (`01-accounts.md` §2). The server's counterpart is
/// `functions/src/config.ts`; no other file may hard-code these.
abstract final class AppConfig {
  /// `hazri-dfcc1`, the Firebase project on Blaze.
  static const firebaseProjectId = 'hazri-dfcc1';

  /// The Android applicationId, which `assetlinks.json` names.
  static const androidPackageName = 'app.hazri';

  /// Firebase Hosting, which also fronts the `api` Function through the
  /// `/api/**` rewrite (ARCHITECTURE §1.2).
  static const hostingOrigin = kSiteBase;

  /// Every client call goes here (ARCHITECTURE §6).
  static const apiBaseUrl = '$hostingOrigin/api/v1';

  /// Where a verification, restore or change-email link lands.
  static const verifyLinkBase = '$hostingOrigin/verify';

  static const functionsRegion = 'asia-south1';

  /// The app's request timeout (`01-accounts.md` §2).
  static const httpTimeout = Duration(seconds: 15);

  /// Profile link lifetimes and the mail cooldown, mirrored from the server
  /// so the app can say "try again in a minute" without asking.
  static const verifyEmailTokenTtl = Duration(hours: 24);
  static const restoreTokenTtl = Duration(hours: 1);
  static const emailCooldown = Duration(seconds: 60);

  // 10-backup §4.5.
  static const backupJitterMinutes = 60;
  static const backupMaxRowsPerRequest = 2000;
  static const backupStaleDays = 14;
  static const restorePageWeeks = 26;
}
