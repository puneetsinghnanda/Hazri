import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/backend/api_exception.dart';
import '../../../core/db/content_db.dart';
import '../../../core/db/content_repository.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/widgets/surfaces.dart';
import '../../settings/ui/screen_scaffold.dart';
import '../data/profile_api.dart';
import '../data/profile_controller.dart';
import '../domain/profile.dart';
import 'change_email_dialog.dart';
import 'city_picker_sheet.dart';
import 'email_sent_screen.dart';
import 'messages.dart';

/// The Profile screen (`01-accounts.md` §8.7). Refreshes on open and every
/// time a screen pushed from here returns.
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
      title: l.profileTitle,
      children: [
        if (refreshing && state is! ProfileLoading) const LinearProgressIndicator(minHeight: 2),
        const SizedBox(height: 8),
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
                _Details(profile: profile),
                const SizedBox(height: 16),
                if (!profile.emailVerified) ...[
                  PrimaryButton(
                    label: l.profileConfirmEmail,
                    onPressed: _sending ? null : () => _confirm(profile),
                  ),
                  const SizedBox(height: 12),
                ],
                PrimaryButton(
                  label: l.profileEditButton,
                  secondary: true,
                  onPressed: () => _push(Routes.profileEdit),
                ),
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

class _Details extends ConsumerWidget {
  const _Details({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final cities = ref.watch(citiesProvider).value ?? const <CityRow>[];
    final city = cities.where((x) => x.id == profile.cityId).firstOrNull;

    Widget row(String label, String value, {Color? colour, IconData? icon}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 110,
                child: Text(label, style: HazriText.caption.copyWith(color: c.muted)),
              ),
              Expanded(
                child: Row(
                  children: [
                    if (icon != null) ...[Icon(icon, size: 18, color: colour), const SizedBox(width: 6)],
                    Flexible(
                      child: Text(value, style: HazriText.bodyStrong.copyWith(color: colour ?? c.ink)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

    return HazriCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          row(l.profileRowName, profile.name),
          row(l.profileRowEmail, profile.email),
          if (profile.pendingEmail != null)
            Padding(
              padding: const EdgeInsets.only(left: 110, bottom: 4),
              child: Text(l.profileEmailPending(profile.pendingEmail!),
                  style: HazriText.caption.copyWith(color: c.kesriInk)),
            ),
          if (!profile.emailVerified)
            Padding(
              padding: const EdgeInsets.only(left: 100),
              child: TextButton(
                onPressed: () => showChangeEmailDialog(context),
                child: Text(l.profileChangeEmail),
              ),
            ),
          row(l.profileRowPhone, profile.phone ?? l.profileNotProvided),
          row(l.profileRowCity, city == null ? profile.cityId : cityName(city, lang)),
          row(
            l.profileRowEmailStatus,
            profile.emailVerified ? l.profileVerified : l.profileNotVerified,
            colour: profile.emailVerified ? c.sage : c.kesri,
            icon: profile.emailVerified ? Icons.verified : null,
          ),
        ],
      ),
    );
  }
}
