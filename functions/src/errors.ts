// The error body of 01-accounts.md §6.0 (ARCHITECTURE §6.1):
// { "error": { code, message, fields?, retryAfterSeconds?, purpose? } }
// Keys that do not apply are omitted.

export interface ErrorExtras {
  fields?: Record<string, string>;
  retryAfterSeconds?: number;
  purpose?: string;
  /** GROUP_LIMIT_REACHED only: the caller's limit, for `sangatLimitReached`. */
  limit?: number;
}

export class ApiError extends Error {
  constructor(
    readonly status: number,
    readonly code: string,
    message: string,
    readonly extras: ErrorExtras = {},
  ) {
    super(message);
  }

  body(): { error: Record<string, unknown> } {
    const error: Record<string, unknown> = { code: this.code, message: this.message };
    if (this.extras.fields !== undefined) error.fields = this.extras.fields;
    if (this.extras.retryAfterSeconds !== undefined) error.retryAfterSeconds = this.extras.retryAfterSeconds;
    if (this.extras.purpose !== undefined) error.purpose = this.extras.purpose;
    if (this.extras.limit !== undefined) error.limit = this.extras.limit;
    return { error };
  }
}

// Shared constructors, with the exact messages of the specs where one is given.
export const Errors = {
  unauthenticated: () => new ApiError(401, 'UNAUTHENTICATED', 'Sign-in required'),
  internal: () => new ApiError(500, 'INTERNAL', 'Something went wrong'),
  invalidRequest: (message = 'Invalid request') => new ApiError(400, 'INVALID_REQUEST', message),
  validation: (fields: Record<string, string>) =>
    new ApiError(400, 'VALIDATION_ERROR', 'Some fields are not valid', { fields }),
  noProfile: () => new ApiError(404, 'NO_PROFILE', 'No profile found'),
  notFound: (message = 'Not found') => new ApiError(404, 'NOT_FOUND', message),
  rateLimited: (retryAfterSeconds: number, message = 'Please wait before requesting another email') =>
    new ApiError(429, 'RATE_LIMITED', message, { retryAfterSeconds }),
  emailNotConfigured: () =>
    new ApiError(503, 'EMAIL_NOT_CONFIGURED', 'Email sending is not configured yet'),
};
