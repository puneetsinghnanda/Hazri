// The email templates of 01-accounts.md §7.1, character for character.
// {name} = profile.name, {link} = the verify link, {app} = Hazri. The HTML
// body is the text body with paragraphs in <p> and the link as
// <a href="{link}">Open in {app}</a>; {name} is HTML-escaped there.
//
// The spec gives these in English only, so every locale gets the English
// text today; the locale is accepted and passed through so a translation is
// a change to this file alone (README decisions).
import { APP_DISPLAY_NAME } from '../config';

export interface RenderedMail {
  subject: string;
  text: string;
  html: string;
}

export function escapeHtml(s: string): string {
  return s
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

/** Paragraphs separated by blank lines; the paragraph that is exactly {link} becomes the anchor. */
function render(subject: string, paragraphs: string[], name: string, link: string): RenderedMail {
  const app = APP_DISPLAY_NAME;
  const fill = (p: string) => p.split('{app}').join(app).split('{link}').join(link);
  const text = paragraphs.map((p) => fill(p.split('{name}').join(name))).join('\n\n');
  const html = paragraphs
    .map((p) => {
      if (p === '{link}') return `<p><a href="${escapeHtml(link)}">Open in ${escapeHtml(app)}</a></p>`;
      return `<p>${escapeHtml(fill(p.split('{name}').join('\u0000'))).split('\u0000').join(escapeHtml(name))}</p>`;
    })
    .join('\n');
  return { subject: fill(subject), text, html };
}

/** 7.1-A Verify email (VERIFY_EMAIL, and CHANGE_EMAIL per §13.8). */
export function verifyEmailTemplate(name: string, link: string, _locale = 'en'): RenderedMail {
  return render(
    'Confirm your email for {app}',
    [
      'Hi {name},',
      'Tap the link below on your Android phone that has {app} installed to confirm your email:',
      '{link}',
      'This link expires in 24 hours. If you did not request this, you can ignore this email.',
    ],
    name,
    link,
  );
}

/** 7.1-B Restore profile (RESTORE_PROFILE). */
export function restoreProfileTemplate(name: string, link: string, _locale = 'en'): RenderedMail {
  return render(
    'Restore your {app} profile',
    [
      'Hi {name},',
      'Someone asked to restore your {app} profile on a new phone. If this was you, tap the link below on that phone:',
      '{link}',
      'This link expires in 1 hour. If you did not request this, ignore this email and your profile will stay as it is.',
    ],
    name,
    link,
  );
}

/** RP2: the report mailed to support. Not user-facing, so English only. */
export function reportTemplate(r: {
  groupId: string;
  groupName: string;
  reason: string;
  note: string | null;
  memberKey: string;
}): RenderedMail {
  const lines = [
    `Group ID: ${r.groupId}`,
    `Group name: ${r.groupName}`,
    `Reason: ${r.reason}`,
    `Note: ${r.note ?? '(none)'}`,
    `Reported by member key: ${r.memberKey}`,
  ];
  return {
    subject: `${APP_DISPLAY_NAME}: group reported (${r.reason})`,
    text: lines.join('\n'),
    html: lines.map((l) => `<p>${escapeHtml(l)}</p>`).join('\n'),
  };
}
