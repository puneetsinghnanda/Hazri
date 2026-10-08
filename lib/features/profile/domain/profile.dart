import 'package:flutter/foundation.dart';

/// The Profile DTO of `01-accounts.md` §6.0 (ARCHITECTURE §6.1), with
/// `cityId` (§13 D9) and `pendingEmail` (§13.8).
@immutable
class Profile {
  const Profile({
    required this.profileId,
    required this.name,
    required this.email,
    required this.cityId,
    required this.emailVerified,
    this.phone,
    this.createdAt,
    this.pendingEmail,
  });

  final String profileId;
  final String name;
  final String email;
  final String? phone;
  final String cityId;
  final bool emailVerified;
  final String? createdAt;

  /// A verified email's replacement, waiting for its link (§13.8).
  final String? pendingEmail;

  factory Profile.fromJson(Map<String, Object?> j) => Profile(
        profileId: j['profileId']! as String,
        name: j['name']! as String,
        email: j['email']! as String,
        phone: j['phone'] as String?,
        cityId: j['cityId']! as String,
        emailVerified: j['emailVerified'] == true,
        createdAt: j['createdAt'] as String?,
        pendingEmail: j['pendingEmail'] as String?,
      );

  Map<String, Object?> toJson() => {
        'profileId': profileId,
        'name': name,
        'email': email,
        'phone': phone,
        'cityId': cityId,
        'emailVerified': emailVerified,
        'createdAt': createdAt,
        'pendingEmail': pendingEmail,
      };

  @override
  bool operator ==(Object other) =>
      other is Profile && _json(other) == _json(this);

  @override
  int get hashCode => _json(this).hashCode;

  static String _json(Profile p) => p.toJson().toString();
}

/// Which email the Email Sent screen is about (§8.9).
enum EmailPurpose { verifyEmail, restoreProfile }
