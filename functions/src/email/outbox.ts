// A sent link is recorded as `mail/{autoId}` inside the same transaction that
// creates its token, then sent through the Mailer once the transaction has
// committed (a transaction may run more than once; an email must not).
//
// The record keeps the recipient, subject, template and delivery state, so a
// failed send is visible as `delivery.state == "ERROR"` (01-accounts V14). It
// deliberately does not keep the text or HTML body, because they carry the
// raw token and §4.4 says the raw token is never stored (README decisions).
import type { DocumentReference, Firestore, Transaction } from 'firebase-admin/firestore';
import { FieldValue } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import type { Mailer } from './mailer';
import type { RenderedMail } from './templates';

export interface QueuedMail {
  ref: DocumentReference;
  to: string;
  mail: RenderedMail;
  locale: string;
}

export function queueMail(
  db: Firestore,
  tx: Transaction,
  to: string,
  mail: RenderedMail,
  meta: { template: string; profileId?: string; locale: string },
): QueuedMail {
  const ref = db.collection('mail').doc();
  tx.create(ref, {
    to,
    message: { subject: mail.subject },
    template: meta.template,
    profileId: meta.profileId ?? null,
    locale: meta.locale,
    delivery: { state: 'PENDING', attempts: 0 },
    createdAt: FieldValue.serverTimestamp(),
  });
  return { ref, to, mail, locale: meta.locale };
}

/** Sends a queued mail; never throws. Returns whether it was accepted by the provider. */
export async function deliver(mailer: Mailer, q: QueuedMail): Promise<boolean> {
  try {
    const { messageId } = await mailer.send({ to: q.to, ...q.mail, locale: q.locale });
    await q.ref.update({
      'delivery.state': 'SUCCESS',
      'delivery.attempts': FieldValue.increment(1),
      'delivery.messageId': messageId,
      'delivery.endTime': FieldValue.serverTimestamp(),
    });
    return true;
  } catch (err) {
    logger.error('mail: send failed', { mailId: q.ref.id, error: String(err) });
    await q.ref
      .update({
        'delivery.state': 'ERROR',
        'delivery.attempts': FieldValue.increment(1),
        'delivery.error': String(err).slice(0, 500),
        'delivery.endTime': FieldValue.serverTimestamp(),
      })
      .catch((e: unknown) => logger.error('mail: could not record the failure', { error: String(e) }));
    return false;
  }
}
