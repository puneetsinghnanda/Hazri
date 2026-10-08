import 'package:flutter/material.dart';

import '../../../core/backend/api_exception.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../domain/validators.dart';

/// The shared messages of `01-accounts.md` §8.10, in the reader's language.
abstract final class ProfileMessages {
  static String network(L l) => l.msgNetwork;
  static String generic(L l) => l.msgGeneric;

  /// ≤ 120 s: "Please wait {n} seconds…"; longer: "…in {h} hours", h =
  /// ceil(n / 3600).
  static String rateLimit(L l, int seconds) =>
      seconds <= 120 ? l.msgRateLimitSeconds(seconds) : l.msgRateLimitHours((seconds / 3600).ceil());

  /// The message for any failure a profile call can raise.
  static String of(L l, Object error) => switch (error) {
        NetworkException() => l.msgNetwork,
        ApiException(code: 'RATE_LIMITED', :final retryAfterSeconds) =>
          rateLimit(l, retryAfterSeconds ?? 60),
        // Brevo not configured yet (W6): the server answers 503 and says so.
        ApiException(code: 'EMAIL_NOT_CONFIGURED') => l.msgEmailNotConfigured,
        _ => l.msgGeneric,
      };

  static String field(L l, FieldError e) => switch (e) {
        FieldError.nameEmpty => l.profileErrNameEmpty,
        FieldError.nameInvalid => l.profileErrNameInvalid,
        FieldError.emailEmpty => l.profileErrEmailEmpty,
        FieldError.emailInvalid => l.profileErrEmailInvalid,
        FieldError.cityEmpty => l.profileErrCityEmpty,
      };

  /// A server field message in the reader's language; as sent if unknown.
  static String serverField(L l, String message) {
    final e = fieldErrorFromServer(message);
    return e == null ? message : field(l, e);
  }

  static void snack(BuildContext context, String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}
