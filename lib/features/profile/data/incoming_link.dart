import '../../../config/app_config.dart';

/// The hosts App Links are declared for (`AndroidManifest.xml`): one Hosting
/// site under two names.
const _hosts = {'${AppConfig.firebaseProjectId}.web.app', '${AppConfig.firebaseProjectId}.firebaseapp.com'};

/// Tokens already handled in this app process (§8.9 "dedupe").
final _handled = <String>{};

/// The in-app route for an incoming https link, or null for a normal app
/// location. `/verify?token=` → the Link Result screen, once per token; the
/// invite path `/j/<groupId>` is handled by the Sangat ([sangatInviteRoute]);
/// any other link on our hosts opens Today.
///
/// Depending on the engine, the link arrives as the whole URL or as its path
/// alone; both are handled.
String? incomingLinkRoute(Uri uri) {
  final external = uri.hasScheme && uri.scheme.startsWith('http');
  final path = uri.path;
  final ours = path == '/verify' || path == '/verify/' || path.startsWith('/j/');
  if (!external && !ours) return null;
  if (external && (uri.scheme != 'https' || !_hosts.contains(uri.host))) return '/today';
  if (path == '/verify' || path == '/verify/') {
    final token = uri.queryParameters['token'] ?? '';
    if (token.isNotEmpty && !_handled.add(token)) return '/today';
    return '/link-result?token=${Uri.encodeQueryComponent(token)}';
  }
  final invite = sangatInviteRoute?.call(uri);
  if (invite != null) return invite;
  return '/today';
}

/// Set by the Sangat (step 6) to claim `/j/<groupId>` links.
String? Function(Uri uri)? sangatInviteRoute;
