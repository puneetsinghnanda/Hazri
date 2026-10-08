// Sending mail (01-accounts.md §13.3 W6): Brevo's transactional email API,
// with the key in Secret Manager. Behind an interface so tests and a future
// provider need no change to the routes.
import { logger } from 'firebase-functions';
import { BREVO_API_URL, EMAIL_FROM, EMAIL_FROM_NAME } from '../config';

export interface MailMessage {
  to: string;
  subject: string;
  text: string;
  html: string;
  /** The recipient's language; the templates are English today (README decisions). */
  locale?: string;
}

export interface Mailer {
  /** False when no key is configured: callers answer 503 EMAIL_NOT_CONFIGURED. */
  configured(): boolean;
  /** Resolves with the provider's message id; rejects on any failure. */
  send(msg: MailMessage): Promise<{ messageId: string | null }>;
}

export class MailerNotConfiguredError extends Error {
  constructor() {
    super('BREVO_API_KEY is not configured');
  }
}

type FetchLike = (url: string, init: { method: string; headers: Record<string, string>; body: string }) => Promise<{
  ok: boolean;
  status: number;
  text(): Promise<string>;
}>;

/** True for a value that is still a `{{PLACEHOLDER}}` or empty. */
export function isPlaceholder(v: string | undefined): boolean {
  return v === undefined || v.trim() === '' || /^\{\{.*\}\}$/.test(v.trim());
}

export class BrevoMailer implements Mailer {
  constructor(
    private readonly apiKey: () => string | undefined,
    private readonly fetchImpl: FetchLike = (url, init) => fetch(url, init),
    private readonly from = { email: EMAIL_FROM, name: EMAIL_FROM_NAME },
  ) {}

  configured(): boolean {
    return !isPlaceholder(this.safeKey());
  }

  private safeKey(): string | undefined {
    try {
      return this.apiKey();
    } catch {
      return undefined;
    }
  }

  async send(msg: MailMessage): Promise<{ messageId: string | null }> {
    const key = this.safeKey();
    if (isPlaceholder(key)) {
      logger.error('mail: BREVO_API_KEY is not configured; nothing sent', { subject: msg.subject });
      throw new MailerNotConfiguredError();
    }
    const res = await this.fetchImpl(BREVO_API_URL, {
      method: 'POST',
      headers: { 'api-key': key as string, 'content-type': 'application/json', accept: 'application/json' },
      body: JSON.stringify({
        sender: { email: this.from.email, name: this.from.name },
        to: [{ email: msg.to }],
        subject: msg.subject,
        textContent: msg.text,
        htmlContent: msg.html,
      }),
    });
    const text = await res.text();
    if (!res.ok) {
      throw new Error(`brevo ${res.status}: ${text.slice(0, 300)}`);
    }
    let messageId: string | null = null;
    try {
      const parsed = JSON.parse(text) as { messageId?: unknown };
      messageId = typeof parsed.messageId === 'string' ? parsed.messageId : null;
    } catch {
      messageId = null;
    }
    return { messageId };
  }
}

/** A mailer that records what it was asked to send (tests, and the emulator). */
export class MemoryMailer implements Mailer {
  readonly sent: MailMessage[] = [];
  constructor(
    private isConfigured = true,
    private fail = false,
  ) {}
  configured(): boolean {
    return this.isConfigured;
  }
  setConfigured(v: boolean): void {
    this.isConfigured = v;
  }
  setFailing(v: boolean): void {
    this.fail = v;
  }
  async send(msg: MailMessage): Promise<{ messageId: string | null }> {
    if (!this.isConfigured) throw new MailerNotConfiguredError();
    if (this.fail) throw new Error('memory mailer: failing on purpose');
    this.sent.push(msg);
    return { messageId: `mem-${this.sent.length}` };
  }
}
