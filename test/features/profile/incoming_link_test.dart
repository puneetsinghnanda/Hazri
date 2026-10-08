import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/features/profile/data/incoming_link.dart';

/// `01-accounts.md` §8.9 DeepLinkService rules, at the router seam (D3).
void main() {
  test('a /verify link on our host goes to Link Result with its token', () {
    expect(incomingLinkRoute(Uri.parse('https://hazri-dfcc1.web.app/verify?token=abc123')),
        '/link-result?token=abc123');
    expect(incomingLinkRoute(Uri.parse('https://hazri-dfcc1.firebaseapp.com/verify/?token=t2')),
        '/link-result?token=t2');
  });

  test('the same token twice in one process is handled once', () {
    expect(incomingLinkRoute(Uri.parse('https://hazri-dfcc1.web.app/verify?token=once')),
        startsWith('/link-result'));
    expect(incomingLinkRoute(Uri.parse('https://hazri-dfcc1.web.app/verify?token=once')), '/today');
  });

  test('a path-only /verify is handled the same way', () {
    expect(incomingLinkRoute(Uri.parse('/verify?token=p1')), '/link-result?token=p1');
  });

  test('another host, http, or another path is not a verification', () {
    expect(incomingLinkRoute(Uri.parse('https://evil.example/verify?token=x')), '/today');
    expect(incomingLinkRoute(Uri.parse('http://hazri-dfcc1.web.app/verify?token=x')), '/today');
    expect(incomingLinkRoute(Uri.parse('https://hazri-dfcc1.web.app/other')), '/today');
  });

  test('ordinary app locations pass through', () {
    expect(incomingLinkRoute(Uri.parse('/today')), isNull);
    expect(incomingLinkRoute(Uri.parse('/diary/2026-10-01')), isNull);
  });
}
