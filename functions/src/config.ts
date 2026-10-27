// Every environment-specific value and business constant of the server, in
// one file (01-accounts.md §2: "All environment-specific values live in
// exactly two files"). Placeholders stay placeholders until the owner
// supplies a value (01-accounts.md §0.4).

export const FIREBASE_PROJECT_ID = 'hazri-dfcc1';
export const ANDROID_PACKAGE_NAME = 'app.hazri';
export const APP_DISPLAY_NAME = 'Hazri';
export const FUNCTIONS_REGION = 'asia-south1';

// Derived constants (01-accounts.md §2).
export const HOSTING_ORIGIN = `https://${FIREBASE_PROJECT_ID}.web.app`;
export const API_BASE_URL = `${HOSTING_ORIGIN}/api/v1`;
export const VERIFY_LINK_BASE = `${HOSTING_ORIGIN}/verify`;
export const INVITE_LINK_BASE = `${HOSTING_ORIGIN}/j`;

// Email (01-accounts.md §13.3 W6: Brevo through its API, key in Secret Manager).
// hazri.me was authenticated in Brevo on 2026-10-09 (DKIM and the Brevo code
// at Namecheap), so this sender needs no mailbox. Replies go to SUPPORT_EMAIL,
// which forwards to the owner.
export const EMAIL_FROM = 'noreply@hazri.me';
export const EMAIL_FROM_NAME = 'Hazri';
export const BREVO_API_URL = 'https://api.brevo.com/v3/smtp/email';
export const BREVO_SECRET_NAME = 'BREVO_API_KEY';
export const SUPPORT_EMAIL = 'support@hazri.me';

// Admin website (11-admin.md AC3).
export const ADMIN_EMAIL = 'puneetsingh1802@gmail.com';
export const ADMIN_ORIGINS = [
  'https://hazri-admin-d4b72.web.app',
  'https://hazri-admin-d4b72.firebaseapp.com',
  'http://localhost:5173',
];

// 01-accounts.md §2, fixed business constants.
export const VERIFY_EMAIL_TOKEN_TTL_SECONDS = 86400;
export const RESTORE_TOKEN_TTL_SECONDS = 3600;
export const EMAIL_COOLDOWN_SECONDS = 60;
export const EMAIL_MAX_PER_WINDOW = 5;
export const EMAIL_WINDOW_SECONDS = 86400;

// 07-simran.md §3.
export const GLOBE_SNAPSHOT_SECONDS = 120;
export const GLOBE_CACHE_SECONDS = 60;

// 08-sangat.md §3.
export const GROUP_NAME_MAX = 64;
export const CUSTOM_GROUP_MAX_MEMBERS = 1000;
export const CUSTOM_GROUPS_ACTIVE_DEFAULT = 5;
export const GOAL_DAYS_MIN = 1;
export const GOAL_DAYS_MAX = 365;
export const GOAL_TARGET_MIN = 1;
export const GOAL_TARGET_MAX = 1_000_000;
export const SIMRAN_MINUTES_DEFAULT = 5;
export const SIMRAN_MINUTES_MIN = 5;
export const SIMRAN_MINUTES_MAX = 120;
export const INVITE_CODE_TTL_DAYS = 30;
export const INVITE_CODE_ALPHABET = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
export const INVITE_CODE_LENGTH = 8;
export const MEMBER_LIST_SIZE = 50;
export const DIARY_DAILY_CAP = 3;
export const REPORT_NOTE_MAX = 200;
export const CONTRIBUTIONS_MAX_PER_REQUEST = 200;
export const BUILT_IN_SHARDS = 20;
/** GG6: a group's globe is built again when older than this. */
export const GROUP_GLOBE_SECONDS = 120;
/** GG4: the paath a group's globe replays as light: the last 60 minutes, at most 12. */
export const GROUP_ARRIVALS_MINUTES = 60;
export const GROUP_ARRIVALS_MAX = 12;

// 10-backup.md §4.5.
export const BACKUP_MAX_ROWS_PER_REQUEST = 2000;
export const BACKUP_RATE_LIMIT = 20; // requests per profile per hour
export const BACKUP_RATE_WINDOW_SECONDS = 3600;
export const RESTORE_PAGE_WEEKS = 26;
export const BACKUP_DOC_MAX_BYTES = 900 * 1024;

// 11-admin.md 4.4.
export const GROUP_LIMIT_MIN = 5;
export const GROUP_LIMIT_MAX = 100;

// 12-badges.md §5.1.
export const BADGE_GOALS_REACHED_CAP = 3;
export const BADGE_JOINS_CAP = 5;

// The Vichar library read (01-accounts.md §13.4).
export const VICHAR_CACHE_SECONDS = 600;
export const VICHAR_MAX_ENTRIES = 200;

// Every Function (ARCHITECTURE §5.3 FN1, FN2, FN5).
export const FUNCTION_DEFAULTS = {
  region: FUNCTIONS_REGION,
  maxInstances: 10,
  minInstances: 0,
} as const;

// 14-quiz.md.
export const QUIZ_QUESTIONS = 5;
export const QUIZ_POINTS_PER_RIGHT = 10;
export const QUIZ_SESSIONS_PER_DAY = 30;
export const QUIZ_MIN_SECONDS = 10;
export const QUIZ_MAX_SECONDS = 30 * 60;
export const QUIZ_BOARD_SECONDS = 120;
export const QUIZ_BOARD_SIZE = 20;
export const QUIZ_DAYS_KEPT = 62;
