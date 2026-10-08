/// A non-2xx answer from the `api` Function, parsed from the common error
/// body (ARCHITECTURE §6.1, `01-accounts.md` §6.0):
///
/// `{ "error": { "code", "message", "fields"?, "retryAfterSeconds"?, "purpose"? } }`
class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.code,
    this.message = '',
    this.fields = const {},
    this.retryAfterSeconds,
    this.purpose,
    this.limit,
  });

  final int statusCode;

  /// `VALIDATION_ERROR`, `NO_PROFILE`, `EMAIL_EXISTS`, `RATE_LIMITED`, …
  final String code;
  final String message;

  /// Only for `VALIDATION_ERROR`: field name → the server's reason.
  final Map<String, String> fields;

  /// Only for `RATE_LIMITED`.
  final int? retryAfterSeconds;

  /// Only for token errors: `VERIFY_EMAIL`, `RESTORE` or `CHANGE_EMAIL`.
  final String? purpose;

  /// Only for `GROUP_LIMIT_REACHED`: the caller's limit (08-sangat CG5).
  final int? limit;

  /// Parses the error body, or describes the status alone when the body is
  /// not the common shape (a proxy page, an empty 502).
  factory ApiException.fromBody(int statusCode, Object? body) {
    final error = body is Map<String, Object?> ? body['error'] : null;
    if (error is! Map<String, Object?>) {
      return ApiException(statusCode: statusCode, code: 'HTTP_$statusCode');
    }
    final fields = error['fields'];
    return ApiException(
      statusCode: statusCode,
      code: (error['code'] as String?) ?? 'HTTP_$statusCode',
      message: (error['message'] as String?) ?? '',
      fields: fields is Map<String, Object?>
          ? {for (final e in fields.entries) e.key: '${e.value}'}
          : const {},
      retryAfterSeconds: (error['retryAfterSeconds'] as num?)?.toInt(),
      purpose: error['purpose'] as String?,
      limit: (error['limit'] as num?)?.toInt(),
    );
  }

  @override
  String toString() => 'ApiException($statusCode $code: $message)';
}

/// The request never got an answer: no network, a timeout, DNS, TLS, or the
/// anonymous sign-in itself failing for want of a network.
class NetworkException implements Exception {
  const NetworkException([this.cause]);

  final Object? cause;

  @override
  String toString() => 'NetworkException($cause)';
}
