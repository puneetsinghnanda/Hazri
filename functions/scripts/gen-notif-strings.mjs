#!/usr/bin/env node
// Builds functions/src/notifications/{en,pa,hi}.json, the server's copy of the
// Sangat push strings (02-notifications.md FM1), from the app's ARB files.
//
// The ARB files are the single source (FM1). This script only READS them.
// It copies every key that starts with `notifSangat` plus
// `notifActionOpenSangat`, without the `@` metadata.
//
// Until the app's ARB files carry those keys (they are added with the Sangat
// step of the app), this script finds none and leaves the committed JSON as
// it is: that JSON was typed from 02-notifications.md §5.5, the approved text
// in all three languages. Once the ARB keys exist, run this and commit.
//
// A message with a title and a body is expected as two keys, `<key>Title` and
// `<key>Body`, e.g. `notifSangatDigestTitle` / `notifSangatDigestBody`; the
// server looks keys up by exactly those names (src/notifications/render.ts).
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const repo = join(here, '..', '..');
const out = join(here, '..', 'src', 'notifications');

const wanted = (key) =>
  !key.startsWith('@') && (key.startsWith('notifSangat') || key === 'notifActionOpenSangat');

let changed = 0;
for (const locale of ['en', 'pa', 'hi']) {
  const arbPath = join(repo, 'lib', 'core', 'l10n', `app_${locale}.arb`);
  if (!existsSync(arbPath)) {
    console.warn(`gen-notif-strings: ${arbPath} not found; ${locale}.json left as committed`);
    continue;
  }
  const arb = JSON.parse(readFileSync(arbPath, 'utf8'));
  const picked = Object.fromEntries(Object.entries(arb).filter(([k]) => wanted(k)));
  if (Object.keys(picked).length === 0) {
    console.warn(
      `gen-notif-strings: no notifSangat* keys in app_${locale}.arb yet; ` +
        `${locale}.json left as committed (text from 02-notifications.md §5.5)`,
    );
    continue;
  }
  const target = join(out, `${locale}.json`);
  const current = existsSync(target) ? JSON.parse(readFileSync(target, 'utf8')) : {};
  // Keys the ARB file does not have yet stay as committed, so a partial ARB
  // never drops a message the server sends.
  const merged = { ...current, ...picked };
  writeFileSync(target, JSON.stringify(merged, null, 2) + '\n');
  changed++;
  console.log(`gen-notif-strings: wrote ${target} (${Object.keys(picked).length} keys from ARB)`);
}
if (changed === 0) console.log('gen-notif-strings: nothing to do');
