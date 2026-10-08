import { BrevoMailer, isPlaceholder, MailerNotConfiguredError } from '../../src/email/mailer';
import { escapeHtml, restoreProfileTemplate, verifyEmailTemplate } from '../../src/email/templates';
import { fill, groupNameFor, renderSangat, unitFor } from '../../src/notifications/render';
import { chooseDigest, heldForThisMorning, isDaytime, milestonesCrossed } from '../../src/notifications/rules';
import type { GoalDoc } from '../../src/sangat/model';
import en from '../../src/notifications/en.json';
import pa from '../../src/notifications/pa.json';
import hi from '../../src/notifications/hi.json';

describe('email templates (01-accounts §7.1)', () => {
  const link = 'https://hazri-dfcc1.web.app/verify?token=abc';
  it('7.1-A, character for character', () => {
    const m = verifyEmailTemplate('Harpreet Kaur', link);
    expect(m.subject).toBe('Confirm your email for Hazri');
    expect(m.text).toBe(
      'Hi Harpreet Kaur,\n\nTap the link below on your Android phone that has Hazri installed to confirm your email:\n\n' +
        `${link}\n\nThis link expires in 24 hours. If you did not request this, you can ignore this email.`,
    );
    expect(m.html).toContain(`<p><a href="${link}">Open in Hazri</a></p>`);
  });
  it('7.1-B, character for character', () => {
    const m = restoreProfileTemplate('Harpreet', link);
    expect(m.subject).toBe('Restore your Hazri profile');
    expect(m.text).toBe(
      'Hi Harpreet,\n\nSomeone asked to restore your Hazri profile on a new phone. If this was you, tap the link below on that phone:\n\n' +
        `${link}\n\nThis link expires in 1 hour. If you did not request this, ignore this email and your profile will stay as it is.`,
    );
  });
  it('escapes the name in HTML only', () => {
    const m = verifyEmailTemplate('<b>Ha</b>', link);
    expect(m.text).toContain('Hi <b>Ha</b>,');
    expect(m.html).toContain('<p>Hi &lt;b&gt;Ha&lt;/b&gt;,</p>');
    expect(escapeHtml(`a&"'`)).toBe('a&amp;&quot;&#39;');
  });
});

describe('Brevo mailer (W6)', () => {
  it('is not configured while the key is missing or a placeholder', async () => {
    expect(new BrevoMailer(() => undefined).configured()).toBe(false);
    expect(new BrevoMailer(() => '{{BREVO_API_KEY}}').configured()).toBe(false);
    expect(new BrevoMailer(() => { throw new Error('no secret'); }).configured()).toBe(false);
    await expect(new BrevoMailer(() => '').send({ to: 'a@b.co', subject: 's', text: 't', html: 'h' })).rejects.toBeInstanceOf(
      MailerNotConfiguredError,
    );
    expect(isPlaceholder('{{EMAIL_FROM}}')).toBe(true);
  });
  it('posts the transactional email shape with the api-key header', async () => {
    const calls: Array<{ url: string; init: { method: string; headers: Record<string, string>; body: string } }> = [];
    const mailer = new BrevoMailer(
      () => 'key-123',
      async (url, init) => {
        calls.push({ url, init });
        return { ok: true, status: 201, text: async () => '{"messageId":"<m1>"}' };
      },
      { email: 'no-reply@hazri.me', name: 'Hazri' },
    );
    expect(mailer.configured()).toBe(true);
    await expect(mailer.send({ to: 'a@b.co', subject: 'S', text: 'T', html: '<p>H</p>' })).resolves.toEqual({ messageId: '<m1>' });
    expect(calls[0].url).toBe('https://api.brevo.com/v3/smtp/email');
    expect(calls[0].init.headers['api-key']).toBe('key-123');
    expect(JSON.parse(calls[0].init.body)).toEqual({
      sender: { email: 'no-reply@hazri.me', name: 'Hazri' },
      to: [{ email: 'a@b.co' }],
      subject: 'S',
      textContent: 'T',
      htmlContent: '<p>H</p>',
    });
  });
  it('rejects on a provider error', async () => {
    const mailer = new BrevoMailer(() => 'k', async () => ({ ok: false, status: 401, text: async () => 'unauthorized' }));
    await expect(mailer.send({ to: 'a@b.co', subject: 'S', text: 'T', html: 'H' })).rejects.toThrow(/brevo 401/);
  });
});

describe('Sangat push strings (02-notifications §5.5, FM1)', () => {
  it('all three languages carry the same keys', () => {
    expect(Object.keys(pa).sort()).toEqual(Object.keys(en).sort());
    expect(Object.keys(hi).sort()).toEqual(Object.keys(en).sort());
  });
  it('renders the digest in the recipient language', () => {
    const v = { group: 'Gill Parivar', count: 128, pct: 42, target: 5000, bani: 'Japji Sahib' };
    expect(renderSangat('Digest', 'en', v)).toEqual({
      title: 'Gill Parivar: 128 paath today',
      body: "Together you're at 42% of 5000 Japji Sahib. Every paath adds to it.",
    });
    expect(renderSangat('Digest', 'pa', v).title).toBe('Gill Parivar: ਅੱਜ 128 ਪਾਠ');
    expect(fill('{a} {b}', { a: 1 })).toBe('1 {b}');
  });
  it('a Simran goal says sittings (SG9); bani names come from content.db', () => {
    expect(unitFor({ type: 'SIMRAN' }, 'en')).toBe('sittings of Naam Simran');
    expect(unitFor({ type: 'BANI', baniId: 'JAPJ' }, 'en')).toBe('Japji Sahib');
    expect(unitFor({ type: 'BANI', baniId: 'JAPJ' }, 'pa')).toBe('ਜਪੁ ਜੀ ਸਾਹਿਬ');
    expect(groupNameFor({ names: { en: 'Simran Sangat', pa: 'ਸਿਮਰਨ ਸੰਗਤ', hi: 'सिमरन संगत' } }, 'hi')).toBe('सिमरन संगत');
  });
});

describe('Sangat push rules (SG2–SG8)', () => {
  const goal: GoalDoc = {
    type: 'BANI',
    baniId: 'JAPJ',
    simranMinutes: null,
    target: 1000,
    startDay: '2026-10-01',
    endDay: '2026-10-20',
    status: 'ACTIVE',
    total: 400,
    dayTotals: { '2026-10-08': 12 },
    completedAt: null,
    sequence: 1,
    createdAt: null as never,
  };
  const custom = { kind: 'CUSTOM' as const, status: 'ACTIVE' as const, endedOn: null, endReason: null };
  it('A on a day with paath; nothing on a zero day (T-21)', () => {
    expect(chooseDigest(custom, goal, '2026-10-08')).toEqual({ kind: 'Digest', count: 12 });
    expect(chooseDigest(custom, goal, '2026-10-09')).toBeNull();
  });
  it('C on the last two days (SG4)', () => {
    expect(chooseDigest(custom, goal, '2026-10-19')).toEqual({ kind: 'Final', daysLeft: 2, remaining: 600 });
    expect(chooseDigest(custom, goal, '2026-10-20')).toEqual({ kind: 'Final', daysLeft: 1, remaining: 600 });
  });
  it('F on the day a custom group ended by date (SG8, T-24b)', () => {
    const ended = { kind: 'CUSTOM' as const, status: 'INACTIVE' as const, endedOn: '2026-10-21', endReason: 'END_DATE' as const };
    expect(chooseDigest(ended, { ...goal, status: 'EXPIRED' }, '2026-10-21')).toEqual({ kind: 'Ended' });
    expect(chooseDigest(ended, { ...goal, status: 'EXPIRED' }, '2026-10-22')).toBeNull();
    const met = { ...ended, endReason: 'TARGET_MET' as const };
    expect(chooseDigest(met, { ...goal, status: 'COMPLETED' }, '2026-10-21')).toBeNull();
  });
  it('milestones crossed', () => {
    expect(milestonesCrossed(240, 250, 1000)).toEqual([25]);
    expect(milestonesCrossed(250, 260, 1000)).toEqual([]);
    expect(milestonesCrossed(100, 800, 1000)).toEqual([25, 50, 75]);
    expect(milestonesCrossed(999, 1000, 1000)).toEqual([100]);
  });
  it('daytime is 07:00–20:59 local; a night notice waits for 07:00 (SG3, T-20)', () => {
    expect(isDaytime(new Date('2026-10-08T01:30:00Z'), 330)).toBe(true); // 07:00 IST
    expect(isDaytime(new Date('2026-10-08T15:30:00Z'), 330)).toBe(false); // 21:00 IST
    const created = new Date('2026-10-07T18:00:00Z'); // 23:30 IST
    expect(heldForThisMorning(created, new Date('2026-10-08T02:00:00Z'), 330)).toBe(true); // 07:30 IST
    expect(heldForThisMorning(new Date('2026-10-07T10:00:00Z'), new Date('2026-10-08T02:00:00Z'), 330)).toBe(false); // 15:30 IST, sent then
  });
});
