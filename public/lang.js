/* Picks one of the three languages and hides the other two.
 *
 * The reader's choice wins, then `?lang=` (Firebase puts the locale it sent
 * the mail in on the link), then the browser. With no JavaScript at all
 * nothing is hidden and all three are readable, which is the right failure.
 */
(function () {
  var LANGS = ['pa', 'hi', 'en'];
  var KEY = 'hazri.lang';

  function stored() {
    try { return localStorage.getItem(KEY); } catch (e) { return null; }
  }

  function remember(code) {
    try { localStorage.setItem(KEY, code); } catch (e) { /* private window */ }
  }

  function preferred() {
    var fromUser = stored();
    if (LANGS.indexOf(fromUser) >= 0) return fromUser;

    var fromLink = new URLSearchParams(location.search).get('lang');
    if (fromLink) {
      var head = fromLink.toLowerCase().split('-')[0];
      if (LANGS.indexOf(head) >= 0) return head;
    }

    var list = navigator.languages || [navigator.language || 'en'];
    for (var i = 0; i < list.length; i++) {
      var code = String(list[i]).toLowerCase().split('-')[0];
      if (LANGS.indexOf(code) >= 0) return code;
    }
    return 'en';
  }

  function apply(code) {
    document.querySelectorAll('[data-lang]').forEach(function (el) {
      el.hidden = el.getAttribute('data-lang') !== code;
    });
    document.querySelectorAll('.langs button').forEach(function (b) {
      b.setAttribute('aria-pressed', String(b.dataset.set === code));
    });
    document.documentElement.setAttribute('lang', code);
  }

  window.hazriLang = { apply: apply };

  document.addEventListener('DOMContentLoaded', function () {
    apply(preferred());
    document.querySelectorAll('.langs button').forEach(function (b) {
      b.addEventListener('click', function () {
        remember(b.dataset.set);
        apply(b.dataset.set);
      });
    });
  });
})();
