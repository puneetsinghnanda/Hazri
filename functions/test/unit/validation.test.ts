import {
  emailHashOf,
  emailNormalizedOf,
  MESSAGES,
  normalizeName,
  normalizePhone,
  validateCityId,
  validateEmail,
  validateName,
  validateProfileInput,
} from '../../src/validation';

describe('01-accounts §5 name', () => {
  it('trims and collapses whitespace (C5)', () => {
    expect(normalizeName('  Harpreet    Kaur  ')).toBe('Harpreet Kaur');
    expect(normalizeName('Harpreet\t\nKaur')).toBe('Harpreet Kaur');
  });
  it('empty → Please enter your name', () => {
    expect(validateName(normalizeName('   '))).toBe(MESSAGES.nameEmpty);
    expect(validateName(normalizeName(undefined))).toBe(MESSAGES.nameEmpty);
  });
  it('length 1 or 51 is refused (C3)', () => {
    expect(validateName('A')).toBe(MESSAGES.nameInvalid);
    expect(validateName('A'.repeat(51))).toBe(MESSAGES.nameInvalid);
  });
  it('length exactly 2 or 50 is accepted (C4)', () => {
    expect(validateName('Ab')).toBeNull();
    expect(validateName('A'.repeat(50))).toBeNull();
  });
  it('accepts Gurmukhi and Devanagari (C6) and . \' -', () => {
    expect(validateName('ਹਰਪ੍ਰੀਤ')).toBeNull();
    expect(validateName('हरप्रीत कौर')).toBeNull();
    expect(validateName("O'Neil-Singh Jr.")).toBeNull();
  });
  it('refuses digits, symbols and a leading mark', () => {
    expect(validateName('Harpreet1')).toBe(MESSAGES.nameInvalid);
    expect(validateName('.Harpreet')).toBe(MESSAGES.nameInvalid);
    expect(validateName('Har@preet')).toBe(MESSAGES.nameInvalid);
  });
  it('counts code points, not UTF-16 units', () => {
    // 25 Gurmukhi letters with combining marks stay inside 50 code points.
    expect(validateName('ਸ'.repeat(50))).toBeNull();
    expect(validateName('ਸ'.repeat(51))).toBe(MESSAGES.nameInvalid);
  });
});

describe('01-accounts §5 email', () => {
  it('empty and invalid messages', () => {
    expect(validateEmail('')).toBe(MESSAGES.emailEmpty);
    expect(validateEmail('not-an-email')).toBe(MESSAGES.emailInvalid);
    expect(validateEmail('a@b.c')).toBe(MESSAGES.emailInvalid);
    expect(validateEmail('a@b.co')).toBeNull();
  });
  it('254 characters is the limit', () => {
    const local = 'a'.repeat(64);
    const ok = `${local}@${'b'.repeat(254 - 64 - 1 - 4)}.com`;
    expect(ok.length).toBe(254);
    expect(validateEmail(ok)).toBeNull();
    expect(validateEmail(`a${ok}`)).toBe(MESSAGES.emailInvalid);
  });
  it('normalised is trimmed and lowercased; the hash is hex sha256 (C8)', () => {
    expect(emailNormalizedOf('  Harpreet@Example.COM ')).toBe('harpreet@example.com');
    expect(emailHashOf('harpreet@example.com')).toMatch(/^[0-9a-f]{64}$/);
    expect(emailHashOf(emailNormalizedOf('A@B.co'))).toBe(emailHashOf(emailNormalizedOf(' a@b.CO ')));
  });
});

describe('01-accounts §5 phone (§13 D2, P3)', () => {
  it('keeps digits and a leading +; empty is null (C2, C7)', () => {
    expect(normalizePhone('+91 98765-43210')).toBe('+919876543210');
    expect(normalizePhone('(098) 765 43210')).toBe('09876543210');
    expect(normalizePhone('')).toBeNull();
    expect(normalizePhone(null)).toBeNull();
    expect(normalizePhone(undefined)).toBeNull();
    expect(normalizePhone('+')).toBeNull();
    expect(normalizePhone('98+76')).toBe('9876');
  });
});

describe('01-accounts §5 city (§13 D9)', () => {
  it('needs a known city id', () => {
    expect(validateCityId('amritsar')).toBeNull();
    expect(validateCityId('')).toBe(MESSAGES.cityEmpty);
    expect(validateCityId('atlantis')).toBe(MESSAGES.cityEmpty);
    expect(validateCityId(undefined)).toBe(MESSAGES.cityEmpty);
  });
});

describe('POST /profile body', () => {
  it('reports every failing field (C11)', () => {
    const r = validateProfileInput({ name: 'A', email: 'x', cityId: '' });
    expect(r).toEqual({ fields: { name: MESSAGES.nameInvalid, email: MESSAGES.emailInvalid, cityId: MESSAGES.cityEmpty } });
  });
  it('returns the normalised profile', () => {
    const r = validateProfileInput({ name: ' Harpreet  Kaur ', email: ' Harpreet@Example.com ', phone: '98765 43210', cityId: 'amritsar', extra: 1 });
    expect(r).toEqual({ value: { name: 'Harpreet Kaur', email: 'Harpreet@Example.com', phone: '9876543210', cityId: 'amritsar' } });
  });
});
