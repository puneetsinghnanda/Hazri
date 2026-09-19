import 'package:flutter/foundation.dart';

/// Somebody's place in the sangat.
///
/// There is no password anywhere in this class and there never will be. The
/// account is a Firebase anonymous sign-in that belongs to one phone, and
/// [email] is the only way it can ever be reached again — which is why
/// [emailVerified] matters and why nothing else here is load-bearing.
///
/// This exists only for people who chose to join. Somebody who never taps
/// "Set up" has no account, sends nothing, and reads exactly as they did in
/// Phase 1 (CLAUDE.md rule 4).
@immutable
class SangatAccount {
  const SangatAccount({
    required this.id,
    required this.name,
    required this.city,
    this.email,
    this.phone,
    this.emailVerified = false,
    this.showName = true,
  });

  /// The Firebase uid. Owns every group membership and every count, so
  /// losing it without a verified email loses the sangat with it.
  final String id;

  final String name;

  /// Shown as one dot on the globe, and nothing finer: the city is the
  /// location, not the person's coordinates.
  final String city;

  /// Held for the account alone. Never shown to the sangat, never on the
  /// globe, never in a group (PRD §13, screen 35).
  final String? email;

  /// Optional, and genuinely optional: it is a profile detail somebody may
  /// fill in, not a way to sign in. There is no phone verification.
  final String? phone;

  /// Whether [email] has been confirmed. False is the normal state for a new
  /// account — the app works either way, and only the coming-back depends on
  /// it.
  final bool emailVerified;

  /// Whether [name] is shown inside groups this person joined. Off shows them
  /// as "a member". The name is never shown outside a joined group whatever
  /// this says (screen 35).
  final bool showName;

  /// A deliberately loose check that a string is an address at all.
  ///
  /// A stricter pattern rejects addresses that are perfectly valid, and the
  /// real test is whether the mail arrives — which the person finds out in a
  /// minute either way. Both the join form and the verify screen use this, so
  /// an address accepted on one is never refused by the other.
  static bool looksLikeEmail(String value) {
    final v = value.trim();
    final at = v.indexOf('@');
    return at > 0 && v.indexOf('.', at) > at + 1 && !v.contains(' ');
  }

  /// Whether this account can survive a change of phone.
  bool get isRecoverable => emailVerified && (email?.isNotEmpty ?? false);

  SangatAccount copyWith({
    String? name,
    String? city,
    String? email,
    String? phone,
    bool? emailVerified,
    bool? showName,
  }) =>
      SangatAccount(
        id: id,
        name: name ?? this.name,
        city: city ?? this.city,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        emailVerified: emailVerified ?? this.emailVerified,
        showName: showName ?? this.showName,
      );

  /// What goes to Firestore. Deliberately hand-written rather than generated:
  /// `firestore.rules` pins the allowed keys, so a field added here without a
  /// matching rule is rejected at the door, and that is easier to see in a
  /// literal than in generated code.
  Map<String, Object?> toFirestore() => {
        'name': name,
        'city': city,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        'showName': showName,
      };

  static SangatAccount fromFirestore(
    String id,
    Map<String, Object?> data, {
    required bool emailVerified,
  }) =>
      SangatAccount(
        id: id,
        name: (data['name'] as String?) ?? '',
        city: (data['city'] as String?) ?? '',
        email: data['email'] as String?,
        phone: data['phone'] as String?,
        emailVerified: emailVerified,
        showName: (data['showName'] as bool?) ?? true,
      );

  @override
  bool operator ==(Object other) =>
      other is SangatAccount &&
      other.id == id &&
      other.name == name &&
      other.city == city &&
      other.email == email &&
      other.phone == phone &&
      other.emailVerified == emailVerified &&
      other.showName == showName;

  @override
  int get hashCode =>
      Object.hash(id, name, city, email, phone, emailVerified, showName);
}
