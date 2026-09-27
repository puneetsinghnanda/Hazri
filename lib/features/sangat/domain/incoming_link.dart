/// What an incoming link turns out to be.
///
/// The app is opened with a URL in three circumstances and has to tell them
/// apart before it can do anything: a sign-in link out of a verification
/// email, an invite to a sangat, and everything else.
///
/// **Deliberately pure, and deliberately loose.** It reads a [Uri] and
/// nothing else — no Firebase, no platform, no widget tree — because the
/// alternative is a rule that can only be tested by tapping a link on a
/// phone, which is how the last several of these went wrong. Being loose
/// matters too: the authoritative check on a sign-in link is the SDK's
/// `isSignInWithEmailLink`, so this only has to be right enough to route to
/// a screen that will then ask properly. A false positive shows a screen
/// that says the link did not work; a false negative drops the link on the
/// floor, which is worse.
sealed class IncomingLink {
  const IncomingLink();

  /// Reads a URL the app was opened with.
  ///
  /// Firebase's sign-in links carry `oobCode`, and the app has been opened on
  /// several different paths over the life of this project — the auth
  /// handler's, and the continue URL's — so the **path is not used to decide**.
  /// The presence of the code is. The host is not checked either: Android has
  /// already checked it against `assetlinks.json` before the app was opened
  /// at all, and a link pasted by hand has no host to check.
  factory IncomingLink.from(Uri uri) {
    // Some mail clients and some redirects move the query onto the fragment.
    final params = <String, String>{
      ...uri.queryParameters,
      if (uri.fragment.contains('=')) ...Uri.splitQueryString(uri.fragment),
    };

    final code = params['oobCode'];
    if (code != null && code.isNotEmpty) {
      return SignInLink(uri.toString(), mode: params['mode']);
    }

    // An invite: /j/<groupId>, and the app is as forgiving about the shape as
    // `groupIdFromInvite` is, because both sides seeing the same link
    // differently is its own bug.
    final parts = uri.pathSegments.where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2 && parts[parts.length - 2] == 'j') {
      return InviteLink(parts.last);
    }

    return const NotOurLink();
  }
}

/// A link out of a verification or restore email.
class SignInLink extends IncomingLink {
  const SignInLink(this.url, {this.mode});

  /// The whole URL, untouched. Firebase wants every character of it, so it is
  /// never rebuilt from parts on the way through.
  final String url;

  /// Firebase's own `mode`, when it is there. Recorded rather than required:
  /// a link carrying a code and no mode is still worth trying.
  final String? mode;
}

/// An invite to a sangat.
class InviteLink extends IncomingLink {
  const InviteLink(this.groupId);
  final String groupId;
}

/// Anything else — the website's own pages, or a link that lost its query on
/// the way. The app opens normally and says nothing.
class NotOurLink extends IncomingLink {
  const NotOurLink();
}
