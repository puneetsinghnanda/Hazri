// What the api Function needs from the outside world, injected so tests can
// replace the token check, the mailer, FCM and the clock.
import type { Firestore } from 'firebase-admin/firestore';
import type { Mailer } from './email/mailer';
import type { Clock } from './time';
import type { Messenger } from './notifications/messenger';

export interface VerifiedToken {
  uid: string;
  email?: string;
  email_verified?: boolean;
  firebase?: { sign_in_provider?: string };
}

export interface TokenVerifier {
  verifyIdToken(idToken: string): Promise<VerifiedToken>;
}

export interface Deps {
  db: Firestore;
  verifier: TokenVerifier;
  mailer: Mailer;
  clock: Clock;
  messenger: Messenger;
}
