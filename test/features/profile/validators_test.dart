import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/features/profile/domain/validators.dart';

/// `01-accounts.md` §5, both paths of each rule.
void main() {
  group('name', () {
    test('empty and whitespace are "enter your name"', () {
      expect(validateName(''), FieldError.nameEmpty);
      expect(validateName('   '), FieldError.nameEmpty);
    });
    test('Gurmukhi, Devanagari and Latin names pass; whitespace collapses', () {
      expect(validateName('ਹਰਪ੍ਰੀਤ ਕੌਰ'), isNull);
      expect(validateName('हरप्रीत'), isNull);
      expect(validateName("D'Souza-Singh Jr."), isNull);
      expect(normalizeName('  Harpreet    Kaur '), 'Harpreet Kaur');
    });
    test('one letter, digits or 51 letters are invalid', () {
      expect(validateName('H'), FieldError.nameInvalid);
      expect(validateName('Harpreet 2'), FieldError.nameInvalid);
      expect(validateName('a' * 51), FieldError.nameInvalid);
      expect(validateName('a' * 50), isNull);
    });
  });

  group('email', () {
    test('valid addresses pass and are trimmed', () {
      expect(validateEmail(' a.b+c@example.co.in '), isNull);
      expect(normalizeEmail(' A@x.com '), 'A@x.com');
      expect(emailKey(' A@X.com '), 'a@x.com');
    });
    test('empty, no domain, or too long fail', () {
      expect(validateEmail(''), FieldError.emailEmpty);
      expect(validateEmail('a@b'), FieldError.emailInvalid);
      expect(validateEmail('not an email'), FieldError.emailInvalid);
      expect(validateEmail('${'a' * 250}@x.com'), FieldError.emailInvalid);
    });
  });

  group('phone (§13 D2, P3)', () {
    test('keeps digits and a leading +; anything else goes', () {
      expect(normalizePhone('+91 98765-43210'), '+919876543210');
      expect(normalizePhone('(0172) 555 1234'), '01725551234');
      expect(normalizePhone('  '), isNull);
      expect(normalizePhone('abc'), isNull);
    });
  });

  test('city must be on the list', () {
    expect(validateCity(null, {'new_delhi'}), FieldError.cityEmpty);
    expect(validateCity('atlantis', {'new_delhi'}), FieldError.cityEmpty);
    expect(validateCity('new_delhi', {'new_delhi'}), isNull);
  });

  test('server messages map back to field errors', () {
    expect(fieldErrorFromServer('Please enter a valid email address'), FieldError.emailInvalid);
    expect(fieldErrorFromServer('Something new'), isNull);
  });
}
