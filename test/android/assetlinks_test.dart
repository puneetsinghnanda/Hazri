import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `public/.well-known/assetlinks.json` — the file that makes a link tappable.
///
/// Android fetches it over HTTPS from the link's host and checks that it names
/// this package and the certificate the installed APK was actually signed
/// with. **Every way of getting it wrong fails silently**: the link simply
/// opens a browser, exactly as it did before, and nothing anywhere says why.
/// There is no error, no log on the phone, no warning at build time.
///
/// So the shape is checked here. What cannot be checked here is whether the
/// fingerprint matches the key CI signs with — that lives in a GitHub secret
/// — or whether the file is actually deployed, which is a hand-run of
/// `firebase deploy --only hosting`. Both are in docs/signing.md.
void main() {
  final file = File('public/.well-known/assetlinks.json');

  test('it exists and is valid JSON', () {
    expect(file.existsSync(), isTrue,
        reason: 'no assetlinks.json means no tappable links');
    expect(() => jsonDecode(file.readAsStringSync()), returnsNormally);
  });

  test('it declares this app, for all URLs', () {
    final statements = jsonDecode(file.readAsStringSync()) as List<dynamic>;
    expect(statements, isNotEmpty);

    final target = (statements.first as Map)['target'] as Map;
    expect((statements.first as Map)['relation'],
        contains('delegate_permission/common.handle_all_urls'));
    expect(target['namespace'], 'android_app');
    expect(target['package_name'], 'app.hazri',
        reason: 'must match applicationId in android/app/build.gradle.kts');
  });

  test('every fingerprint is a whole SHA-256', () {
    // The commonest way to break this is a truncated paste. A short
    // fingerprint is still valid JSON and still looks plausible.
    final statements = jsonDecode(file.readAsStringSync()) as List<dynamic>;
    final prints = ((statements.first as Map)['target']
        as Map)['sha256_cert_fingerprints'] as List<dynamic>;

    expect(prints, isNotEmpty);
    for (final value in prints) {
      final bytes = (value as String).split(':');
      expect(bytes, hasLength(32),
          reason: 'a SHA-256 is 32 bytes; "$value" has ${bytes.length}');
      for (final byte in bytes) {
        expect(byte, matches(RegExp(r'^[0-9A-F]{2}$')),
            reason: 'uppercase hex byte pairs, colon separated: got "$byte"');
      }
    }
  });

  test('the package name matches the one Gradle builds', () {
    // Two files, one truth. A rename in one and not the other breaks
    // verification without breaking anything a build would notice.
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    final statements = jsonDecode(file.readAsStringSync()) as List<dynamic>;
    final package =
        ((statements.first as Map)['target'] as Map)['package_name'] as String;

    expect(gradle, contains('applicationId = "$package"'));
  });
}
