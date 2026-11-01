/* The /verify fallback page (ARCHITECTURE.md §8.3, 01-accounts §7.4).
 *
 * A verification or restore link is meant to open the app directly (an App
 * Link). This page is where it lands when Android hands it to a browser
 * instead: the app is not installed, the link was opened on a computer, or
 * the mail service wrapped it in its own click-tracking address, after which
 * the redirect to us happens inside the browser and no App Link can fire.
 *
 * With a token, Open in Hazri is an intent:// address naming the app's
 * package, which Chrome hands straight to the app with the same link. The
 * host is the one the App Link filter declares, whichever host served this
 * page. It never calls the API.
 *
 * The two pure functions are also loaded by
 * functions/test/unit/verify-page.test.ts, which holds them to the link the
 * server mails (functions/src/tokens.ts linkFor).
 */
(function () {
  var HOST = 'hazri-dfcc1.web.app';
  var PACKAGE = 'app.hazri';
  // 32 random bytes, base64url, as functions/src/tokens.ts makes them.
  var TOKEN = /^[A-Za-z0-9_-]{43}$/;

  function tokenOf(href) {
    var url;
    try { url = new URL(href); } catch (e) { return null; }
    // A mail client can move the query into the fragment; take it from either.
    var token = url.searchParams.get('token') ||
      new URLSearchParams(url.hash.replace(/^#/, '')).get('token');
    return token && TOKEN.test(token) ? token : null;
  }

  function intentFor(token) {
    return 'intent://' + HOST + '/verify?token=' + token +
      '#Intent;scheme=https;package=' + PACKAGE + ';end';
  }

  if (typeof module === 'object' && module.exports) {
    module.exports = { tokenOf: tokenOf, intentFor: intentFor };
    return;
  }

  var token = tokenOf(location.href);
  document.getElementById('has-code').hidden = !token;
  document.getElementById('no-code').hidden = !!token;
  if (token) document.getElementById('open').href = intentFor(token);
})();
