import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/features/sangat/domain/incoming_link.dart';

/// Reading a link the app was opened with.
///
/// These are written from the shapes a real link actually takes rather than
/// from the shape the code expects, because the path a Firebase sign-in link
/// arrives on has changed under this project once already — Dynamic Links
/// shut down in August 2025 and the links moved onto a Hosting domain — and
/// anything keyed to a path would have broken silently when it did.
void main() {
  IncomingLink read(String url) => IncomingLink.from(Uri.parse(url));

  group('a sign-in link is recognised by its code, not its path', () {
    const paths = <String, String>{
      'the auth handler': 'https://hazri-dfcc1.firebaseapp.com/__/auth/action',
      'the hosting link path': 'https://hazri-dfcc1.web.app/__/auth/links',
      'the continue URL': 'https://hazri-dfcc1.web.app/verify',
      'a bare root': 'https://hazri-dfcc1.web.app/',
    };

    paths.forEach((name, base) {
      test('on $name', () {
        final url = '$base?apiKey=AIza123&mode=signIn&oobCode=ABC123&lang=en';
        final link = read(url);
        expect(link, isA<SignInLink>());
        expect((link as SignInLink).url, url,
            reason: 'Firebase wants every character, so it is never rebuilt');
        expect(link.mode, 'signIn');
      });
    });

    test('a code with no mode is still worth trying', () {
      // Better to open a screen that says the link did not work than to drop
      // a link that would have worked.
      expect(read('https://hazri-dfcc1.web.app/verify?oobCode=ABC123'),
          isA<SignInLink>());
    });

    test('a code on the fragment is found too', () {
      // Some clients and some redirects move the query across.
      expect(read('https://hazri-dfcc1.web.app/verify#mode=signIn&oobCode=ABC'),
          isA<SignInLink>());
    });

    test('an empty code is not a code', () {
      expect(read('https://hazri-dfcc1.web.app/verify?oobCode='),
          isA<NotOurLink>());
    });
  });

  group('an invite', () {
    test('is the last segment after /j', () {
      final link = read('https://hazri-dfcc1.web.app/j/abc123');
      expect(link, isA<InviteLink>());
      expect((link as InviteLink).groupId, 'abc123');
    });

    test('survives what a messaging app adds', () {
      final link = read('https://hazri-dfcc1.web.app/j/abc123?from=whatsapp');
      expect((link as InviteLink).groupId, 'abc123');
    });

    test('is not confused with a page called j', () {
      expect(read('https://hazri-dfcc1.web.app/j'), isA<NotOurLink>());
    });
  });

  group('everything else opens the app and says nothing', () {
    for (final url in [
      'https://hazri-dfcc1.web.app/',
      'https://hazri-dfcc1.web.app/verify',
      'https://hazri-dfcc1.web.app/privacy',
      'hazri://reader/japji-sahib?autoplay=1',
    ]) {
      test(url, () => expect(read(url), isA<NotOurLink>()));
    }
  });
}
