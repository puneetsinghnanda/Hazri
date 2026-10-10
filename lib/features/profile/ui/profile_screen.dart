import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/backend/api_exception.dart';
import '../../../core/db/content_db.dart';
import '../../../core/db/content_repository.dart';
import '../../../core/db/user_repository.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/app_mark.dart';
import '../../../core/widgets/surfaces.dart';
import '../../backup/ui/backup_section.dart';
import '../../badges/data/badge_controller.dart';
import '../../badges/ui/badge_widgets.dart';
import '../../diary/ui/diary_screen.dart' show hazriStreakProvider;
import '../../settings/ui/screen_scaffold.dart';
import '../data/profile_api.dart';
import '../data/profile_controller.dart';
import '../domain/profile.dart';
import 'change_email_dialog.dart';
import 'city_picker_sheet.dart';
import 'email_sent_screen.dart';
import 'messages.dart';
import 'profile_icons.dart';

/// The Profile screen (`01-accounts.md` §8.7; design 100, "identity card and
/// badge shelf", owner 2026-10-10). Refreshes on open and every time a
/// screen pushed from here returns.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() => ref.read(profileControllerProvider.notifier).refresh();

  Future<void> _push(String route, {Object? extra}) async {
    await context.push(route, extra: extra);
    if (mounted) await _refresh();
  }

  Future<void> _confirm(Profile p) async {
    final l = L.of(context);
    final controller = ref.read(profileControllerProvider.notifier);
    setState(() => _sending = true);
    try {
      final cooldown = await ref.read(profileApiProvider).sendVerification();
      if (mounted) await _push(Routes.emailSent, extra: EmailSentArgs(EmailPurpose.verifyEmail, p.email, cooldown));
    } on ApiException catch (e) {
      if (!mounted) return;
      switch (e.code) {
        case 'EMAIL_ALREADY_VERIFIED':
          await controller.refresh();
        case 'NO_PROFILE':
          await controller.markNone();
        default:
          ProfileMessages.snack(context, ProfileMessages.of(l, e));
      }
    } on NetworkException {
      if (mounted) ProfileMessages.snack(context, l.msgNetwork);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    final state = ref.watch(profileControllerProvider);
    final refreshing = ref.read(profileControllerProvider.notifier).refreshing;

    return HazriScreen(
      title: l.profileYourTitle,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      children: [
        if (refreshing && state is! ProfileLoading) const LinearProgressIndicator(minHeight: 2),
        const SizedBox(height: 4),
        switch (state) {
          ProfileLoading() => const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(child: CircularProgressIndicator()),
            ),
          ProfileNone() => _Empty(
              text: l.profileNone,
              buttons: [PrimaryButton(label: l.profileSetupTitle, onPressed: () => _push(Routes.profileSetup))],
            ),
          ProfileUnavailable() => _Empty(
              text: l.profileUnavailable,
              buttons: [
                PrimaryButton(label: l.profileRetry, secondary: true, onPressed: _refresh),
                const SizedBox(height: 12),
                PrimaryButton(label: l.profileSetupTitle, onPressed: () => _push(Routes.profileSetup)),
              ],
            ),
          ProfileLoaded(:final profile, :final isStale) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isStale && !refreshing) ...[
                  HazriCard(
                    colour: c.kesriSoft,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(l.profileStale, style: HazriText.bodySmall.copyWith(color: c.kesriInk)),
                        ),
                        TextButton(onPressed: _refresh, child: Text(l.profileRetry)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                _IdentityCard(
                  profile: profile,
                  onConfirm: _sending ? null : () => _confirm(profile),
                ),
                const SizedBox(height: 12),
                // 12-badges UI5, design 100.
                const ProfileBadgesSection(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        label: l.profileEditButton,
                        icon: ProfileIcons.edit,
                        onPressed: () => _push(Routes.profileEdit),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(child: BackupNowButton()),
                  ],
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: BackupStatusLine(suffix: profile.phone ?? l.profilePhoneNotProvided),
                ),
                const RestoreDataButton(quiet: true),
                const SizedBox(height: 4),
                const _PrivacyLine(),
              ],
            ),
        },
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text, required this.buttons});

  final String text;
  final List<Widget> buttons;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Text(text, textAlign: TextAlign.center, style: HazriText.body.copyWith(color: context.colors.ink2)),
          const SizedBox(height: 24),
          ...buttons,
        ],
      );
}

/// The navy identity card: the mark and "Hazri", the name, the city, the
/// email with its state, then three numbers under a rule (design 100).
class _IdentityCard extends ConsumerWidget {
  const _IdentityCard({required this.profile, required this.onConfirm});

  final Profile profile;

  /// Confirm my email; null while a request is out.
  final VoidCallback? onConfirm;

  static const _sun = Color(0xFFF2A24E);
  static const _verified = Color(0xFF9FE3BF);
  static const _pending = Color(0xFFFFC27E);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final cities = ref.watch(citiesProvider).value ?? const <CityRow>[];
    final city = cities.where((x) => x.id == profile.cityId).firstOrNull;
    final streak = ref.watch(hazriStreakProvider).value ?? HazriStreak.zero;
    final badges = (ref.watch(earnedBadgesProvider).value ?? const []).length;
    final dark = Theme.of(context).brightness == Brightness.dark;
    const white = Colors.white;
    final soft = white.withValues(alpha: 0.85);
    final line = HazriText.bodySmall.copyWith(fontSize: 14, color: soft, height: 1.45);

    Widget iconLine(String icon, Widget text) => Row(
          children: [
            AppIcon(icon, size: 15, color: soft),
            const SizedBox(width: 5),
            Flexible(child: text),
          ],
        );

    Widget stat(int n, String label) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$n', style: HazriText.display22.copyWith(color: white, height: 1.05)),
              Text(
                label,
                style: HazriText.caption.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment(-0.5, -0.87),
          end: Alignment(0.5, 0.87),
          colors: [Color(0xFF2E3577), Color(0xFF262C63), Color(0xFF1A1E48)],
          stops: [0, 0.55, 1],
        ),
        boxShadow: dark ? null : const [BoxShadow(color: Color(0x47262C63), blurRadius: 30, offset: Offset(0, 14))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            const Positioned(
              right: -40,
              top: -6,
              child: CustomPaint(size: Size(230, 140), painter: _ArcPainter()),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const AppMark(size: 26, arcColor: white, sunColor: _sun),
                      const SizedBox(width: 8),
                      Text(l.appBarTitle, style: HazriText.display22.copyWith(fontSize: 17, color: white)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    profile.name,
                    style: HazriText.display22.copyWith(fontSize: 30, height: 1.05, color: white),
                  ),
                  const SizedBox(height: 4),
                  iconLine(HazriIconData.pin, Text(city == null ? profile.cityId : cityName(city, lang), style: line)),
                  iconLine(
                    HazriIconData.mail,
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: profile.email),
                          const TextSpan(text: '  '),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: _EmailMark(verified: profile.emailVerified),
                          ),
                        ],
                      ),
                      style: line,
                    ),
                  ),
                  if (profile.pendingEmail != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 20, top: 2),
                      child: Text(
                        l.profileEmailPending(profile.pendingEmail!),
                        style: HazriText.caption.copyWith(fontSize: 12.5, color: white.withValues(alpha: 0.7)),
                      ),
                    ),
                  // §8.7: an unverified email can be confirmed or corrected
                  // from here; a verified one is changed in Edit profile.
                  if (!profile.emailVerified) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        PrimaryButton(
                          label: l.profileConfirmEmail,
                          expanded: false,
                          minHeight: 44,
                          background: white,
                          foreground: const Color(0xFF262C63),
                          onPressed: onConfirm,
                        ),
                        TextButton(
                          onPressed: () => showChangeEmailDialog(context),
                          style: TextButton.styleFrom(foregroundColor: white, minimumSize: const Size(0, 44)),
                          child: Text(
                            l.profileChangeEmail,
                            style: HazriText.bodySmall.copyWith(fontWeight: FontWeight.w700, color: white),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  Container(height: 1, color: white.withValues(alpha: 0.16)),
                  const SizedBox(height: 12),
                  Row(
                    key: const Key('profile-stats'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      stat(streak.days.length, l.profileStatHazriDays(streak.days.length)),
                      const SizedBox(width: 10),
                      stat(streak.current, l.profileStatInARow),
                      const SizedBox(width: 10),
                      stat(badges, l.profileStatBadges(badges)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Verified" in green with a tick, or "Not verified" in saffron.
class _EmailMark extends StatelessWidget {
  const _EmailMark({required this.verified});

  final bool verified;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final colour = verified ? _IdentityCard._verified : _IdentityCard._pending;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (verified) ...[
          AppIcon(HazriIconData.check, size: 13, color: colour),
          const SizedBox(width: 3),
        ],
        Text(
          verified ? l.profileVerified : l.profileNotVerified,
          style: HazriText.caption.copyWith(fontSize: 12.5, fontWeight: FontWeight.w700, color: colour),
        ),
      ],
    );
  }
}

/// The card's sky: a faint arc and the sun half-risen, top right.
class _ArcPainter extends CustomPainter {
  const _ArcPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Authored on the design's 230 x 140 box.
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(115, 135), radius: 105),
      3.14159,
      3.14159,
      false,
      Paint()
        ..color = const Color(0x14FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18,
    );
    canvas.drawPath(
      Path()
        ..moveTo(65, 135)
        ..arcToPoint(const Offset(165, 135), radius: const Radius.circular(50))
        ..close(),
      Paint()..color = const Color(0x29F2A24E),
    );
  }

  @override
  bool shouldRepaint(_ArcPainter oldDelegate) => false;
}

/// The privacy line under the actions, with its shield.
class _PrivacyLine extends StatelessWidget {
  const _PrivacyLine();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: AppIcon(ProfileIcons.shield, size: 16, color: c.sage),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              L.of(context).profilePrivacyLine,
              style: HazriText.caption.copyWith(fontSize: 12.5, height: 1.4, color: c.ink2),
            ),
          ),
        ],
      ),
    );
  }
}
