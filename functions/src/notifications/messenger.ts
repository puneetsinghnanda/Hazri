// FCM behind an interface (02-notifications.md §8.3). The real one wraps
// getMessaging().sendEach; tests use MemoryMessenger.
import type { Messaging } from 'firebase-admin/messaging';

export interface PushMessage {
  token: string;
  title: string;
  body: string;
  /** FM2 data: kind, groupId, route. */
  data: { kind: string; groupId: string; route: string };
}

export interface PushResult {
  ok: boolean;
  /** FCM error code, e.g. messaging/registration-token-not-registered. */
  errorCode?: string;
}

export interface Messenger {
  /** Sends at most 500 at a time (FM2); returns one result per message, in order. */
  sendEach(messages: PushMessage[]): Promise<PushResult[]>;
}

export const FCM_BATCH = 500;

export class FcmMessenger implements Messenger {
  constructor(private readonly messaging: () => Messaging) {}

  async sendEach(messages: PushMessage[]): Promise<PushResult[]> {
    const results: PushResult[] = [];
    for (let i = 0; i < messages.length; i += FCM_BATCH) {
      const chunk = messages.slice(i, i + FCM_BATCH);
      const res = await this.messaging().sendEach(
        chunk.map((m) => ({
          token: m.token,
          notification: { title: m.title, body: m.body },
          android: { priority: 'normal' as const, notification: { channelId: 'sangat' } },
          data: m.data,
        })),
      );
      for (const r of res.responses) {
        results.push(r.success ? { ok: true } : { ok: false, errorCode: r.error?.code });
      }
    }
    return results;
  }
}

export class MemoryMessenger implements Messenger {
  readonly sent: PushMessage[] = [];
  /** Tokens FCM should report as unregistered (FM4 tests). */
  readonly dead = new Set<string>();
  async sendEach(messages: PushMessage[]): Promise<PushResult[]> {
    return messages.map((m) => {
      if (this.dead.has(m.token)) return { ok: false, errorCode: 'messaging/registration-token-not-registered' };
      this.sent.push(m);
      return { ok: true };
    });
  }
}

/** FM4: a token FCM reports as unregistered or invalid is deleted at once. */
export function isDeadTokenError(code: string | undefined): boolean {
  return (
    code === 'messaging/registration-token-not-registered' ||
    code === 'messaging/invalid-registration-token' ||
    code === 'messaging/invalid-argument'
  );
}
