/// `01-accounts.md` §5: normalise first, then validate the normalised value.
/// The server (`functions/src/validation.ts`) runs the same rules and is
/// authoritative; these only spare a round trip.
library;

/// Which message a field shows; the screen turns it into the reader's
/// language.
enum FieldError { nameEmpty, nameInvalid, emailEmpty, emailInvalid, cityEmpty }

final _nameRegex = RegExp(r"^[\p{L}\p{M}][\p{L}\p{M} .'\-]{1,49}$", unicode: true);
final _emailRegex = RegExp(r'^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$', unicode: true);

/// Trim; collapse runs of whitespace to one space.
String normalizeName(String raw) => raw.trim().replaceAll(RegExp(r'\s+'), ' ');

/// Trim (what is stored).
String normalizeEmail(String raw) => raw.trim();

/// Trim and lowercase (`emailNormalized`).
String emailKey(String raw) => raw.trim().toLowerCase();

/// Every character that is not a digit removed, a leading `+` kept if typed;
/// empty is null (§13 D2, P3).
String? normalizePhone(String raw) {
  final t = raw.trim();
  final digits = t.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return null;
  return t.startsWith('+') ? '+$digits' : digits;
}

FieldError? validateName(String raw) {
  final v = normalizeName(raw);
  if (v.isEmpty) return FieldError.nameEmpty;
  // Length counts code points (§5 rules).
  final n = v.runes.length;
  if (n < 2 || n > 50 || !_nameRegex.hasMatch(v)) return FieldError.nameInvalid;
  return null;
}

FieldError? validateEmail(String raw) {
  final v = normalizeEmail(raw);
  if (v.isEmpty) return FieldError.emailEmpty;
  if (v.runes.length > 254 || !_emailRegex.hasMatch(v)) return FieldError.emailInvalid;
  return null;
}

FieldError? validateCity(String? cityId, Set<String> known) =>
    cityId == null || !known.contains(cityId) ? FieldError.cityEmpty : null;

/// The server's exact messages (`functions/src/validation.ts` MESSAGES),
/// back to a field error, so a `VALIDATION_ERROR` shows in the reader's
/// language. Null for a message this build does not know.
FieldError? fieldErrorFromServer(String message) => switch (message) {
      'Please enter your name' => FieldError.nameEmpty,
      "Name must be 2–50 letters (spaces, . ' - allowed)" => FieldError.nameInvalid,
      'Please enter your email' => FieldError.emailEmpty,
      'Please enter a valid email address' => FieldError.emailInvalid,
      'Please choose your city' => FieldError.cityEmpty,
      _ => null,
    };
