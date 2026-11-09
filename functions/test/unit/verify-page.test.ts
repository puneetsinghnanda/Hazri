// The browser fallback page (ARCHITECTURE.md §8.3, 01-accounts §7.4) against
// the link the server actually mails. The two are written in different
// languages in different directories, and they disagreed for a month: the
// server sent `/verify?token=` while the page looked for Firebase's old
// `oobCode=`, so every real link that reached a browser was told it "carries
// no code". This test holds them together at that seam.
import * as path from 'node:path';
import { ANDROID_PACKAGE_NAME, FIREBASE_PROJECT_ID } from '../../src/config';
import { linkFor, newToken } from '../../src/tokens';

interface VerifyPage {
  tokenOf(href: string): string | null;
  intentFor(token: string): string;
}

// Plain JavaScript served as-is by Hosting, so it is loaded rather than imported.
// eslint-disable-next-line @typescript-eslint/no-require-imports
const page: VerifyPage = require(path.join(__dirname, '../../../public/verify/verify.js'));

describe('ARCHITECTURE §8.3 the /verify fallback page', () => {
  it('finds the token in the link the server mails', () => {
    const { raw, link } = newToken();
    expect(page.tokenOf(link)).toBe(raw);
  });

  it('finds it with other parameters around it, as a mail client may add', () => {
    const raw = newToken().raw;
    expect(page.tokenOf(`${linkFor(raw)}&lang=pa`)).toBe(raw);
    expect(page.tokenOf(`https://${FIREBASE_PROJECT_ID}.web.app/verify?lang=hi&token=${raw}`)).toBe(raw);
  });

  it('finds nothing in an address with no token, or a malformed one', () => {
    expect(page.tokenOf(`https://${FIREBASE_PROJECT_ID}.web.app/verify`)).toBeNull();
    expect(page.tokenOf(`https://${FIREBASE_PROJECT_ID}.web.app/verify?token=`)).toBeNull();
    expect(page.tokenOf(`https://${FIREBASE_PROJECT_ID}.web.app/verify?token=short`)).toBeNull();
    // The Firebase link this page was first written for is not ours any more.
    expect(page.tokenOf(`https://${FIREBASE_PROJECT_ID}.web.app/verify?oobCode=abc&mode=signIn`)).toBeNull();
  });

  it('Open in app is an intent for the app, on the host its App Link filter declares', () => {
    const raw = newToken().raw;
    expect(page.intentFor(raw)).toBe(
      `intent://${FIREBASE_PROJECT_ID}.web.app/verify?token=${raw}` +
        `#Intent;scheme=https;package=${ANDROID_PACKAGE_NAME};end`,
    );
  });
});
