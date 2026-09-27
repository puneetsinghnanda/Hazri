import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `firebase.json` — what actually reaches the web.
///
/// Firebase Hosting's default ignore list contains `**/.*`, which reads as
/// "no dotfiles" and is sensible right up until the one directory that has
/// to be served is called `.well-known`. It was in the file, `assetlinks.json`
/// was excluded from the deploy, and the only symptom was Google's
/// digitalassetlinks endpoint answering `{"maxAge": "3600s"}` with no
/// statements — no error, no warning, and a deploy that reported success.
///
/// Nothing else can see this. The file is in git, the test above it passes,
/// the deploy succeeds, and the link opens a browser.
void main() {
  final config =
      jsonDecode(File('firebase.json').readAsStringSync()) as Map<String, dynamic>;
  final hosting = config['hosting'] as Map<String, dynamic>;

  test('the deploy does not exclude .well-known', () {
    final ignore = (hosting['ignore'] as List<dynamic>).cast<String>();

    for (final pattern in ignore) {
      // Any glob whose last segment starts with a dot and then wildcards
      // swallows .well-known along with the dotfiles it was aimed at.
      expect(pattern.split('/').last.startsWith('.*'), isFalse,
          reason: 'ignore pattern "$pattern" excludes .well-known, and with '
              'it assetlinks.json and every tappable link');
    }
  });

  test('what is published is the directory assetlinks.json lives in', () {
    expect(hosting['public'], 'public');
    expect(File('public/.well-known/assetlinks.json').existsSync(), isTrue);
  });

  test('nothing rewrites the paths a link arrives on', () {
    // A catch-all rewrite would hand /.well-known/assetlinks.json to an HTML
    // page, which serves with a 200 and fails verification anyway.
    final rewrites =
        (hosting['rewrites'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();
    for (final rule in rewrites) {
      expect(rule['source'], isNot('**'),
          reason: 'a catch-all rewrite would shadow /.well-known/');
      expect(rule['source'], isNot(startsWith('/.well-known')));
    }
  });
}
