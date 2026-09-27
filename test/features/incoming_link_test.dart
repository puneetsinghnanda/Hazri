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

  group('the real one, copied out of a phone', () {
    // Taken verbatim from a screenshot on 2026-09-27, after the app answered
    // "GoException: no routes for location" on a link that was perfectly
    // good. It is the shape nothing here anticipated: **a link wrapping a
    // link**. oobCode is not a parameter of this URL at all, it is a
    // parameter of a URL percent-encoded inside its `link` parameter, so
    // reading the outer query found nothing and the router had no route for
    // /__/auth/links.
    //
    // Kept whole and ugly on purpose. Tidying it into something shorter
    // would be testing a link Firebase does not send.
    const real =
        'https://hazri-dfcc1.firebaseapp.com/__/auth/links'
        '?link=https://hazri-dfcc1.firebaseapp.com/__/auth/action'
        '%3FapiKey%3DAIzaSyCMxMrahs9HUN7-lFBx5T9r51AzPsDUhHg'
        '%26mode%3DsignIn'
        '%26oobCode%3DS1oVLt4aQCirFGJZdakVCUFpVMAmDz5DD3q9yWimeoQAAAGg40WL_A'
        '%26continueUrl%3Dhttps://hazri-dfcc1.web.app/verify'
        '%26lang%3Den';

    test('is recognised as a sign-in link', () {
      expect(read(real), isA<SignInLink>());
    });

    test('and is handed on whole, wrapper and all', () {
      // The SDK minted this shape and knows how to unwrap it. Rebuilding it
      // from the inner URL would be guessing at a format that has already
      // changed once this year.
      expect((read(real) as SignInLink).url, real);
    });

    test('the mode is read from inside the wrapper too', () {
      expect((read(real) as SignInLink).mode, 'signIn');
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
