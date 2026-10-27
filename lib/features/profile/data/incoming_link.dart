import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../config/app_config.dart';

/// The hosts App Links are declared for (`AndroidManifest.xml`): one Hosting
/// site under two names.
const _hosts = {'${AppConfig.firebaseProjectId}.web.app', '${AppConfig.firebaseProjectId}.firebaseapp.com'};

/// Tokens already handled in this app process (§8.9 "dedupe").
final _handled = <String>{};

/// The in-app route for an incoming https link, or null for a normal app
/// location. `/verify?token=` → the Link Result screen, once per token; the
/// invite path `/j/<code>` → the Sangat's Join screen (08-sangat IV5); a
/// shared quiz `/q/<topic>` → that quiz (14-quiz.md QZ25); any other link on
/// our hosts opens Today.
///
/// Depending on the engine, the link arrives as the whole URL or as its path
/// alone; both are handled.
String? incomingLinkRoute(Uri uri) {
  final external = uri.hasScheme && uri.scheme.startsWith('http');
  final path = uri.path;
  final ours = path == '/verify' || path == '/verify/' || path.startsWith('/j/') || path.startsWith('/q/');
  if (!external && !ours) return null;
  if (external && (uri.scheme != 'https' || !_hosts.contains(uri.host))) return '/today';
  if (path == '/verify' || path == '/verify/') {
    final token = uri.queryParameters['token'] ?? '';
    if (token.isNotEmpty && !_handled.add(token)) return '/today';
    return '/link-result?token=${Uri.encodeQueryComponent(token)}';
  }
  // IV5: /j/{code} opens Join with the code filled in.
  if (path.startsWith('/j/')) {
    final code = path.substring(3).split('/').first;
    if (code.isNotEmpty) return '/sangat-join?code=${Uri.encodeQueryComponent(code)}';
  }
  // QZ25: /q/{topic} opens that quiz at its first question.
  if (path.startsWith('/q/')) {
    final topic = path.substring(3).split('/').first;
    if (RegExp(r'^[a-z0-9-]{1,64}$').hasMatch(topic)) return '/quiz/play/$topic';
  }
  return '/today';
}

/// 03-first-run F7: a link opened before setup is done, kept until it is.
const kHeldLink = 'held_link_v1';

void holdLink(SharedPreferences prefs, String route) =>
    unawaited(prefs.setString(kHeldLink, route));

/// The held route, cleared as it is taken.
Future<String?> takeHeldLink(SharedPreferences prefs) async {
  final route = prefs.getString(kHeldLink);
  if (route != null) await prefs.remove(kHeldLink);
  return route;
}
