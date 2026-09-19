import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/surfaces.dart';
import '../../settings/ui/screen_scaffold.dart';
import '../data/account_repository.dart';
import '../domain/sangat_account.dart';

/// Design 33 — the account, and the only place verification is ever asked
/// for.
///
/// That is a decision, not an oversight: the reader said plainly that they
/// did not want a "verify your email" step during setup, and did not want it
/// on the landing page either. Somebody can use every part of Hazri without
/// ever coming here.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final account = ref.watch(sangatAccountProvider).value;

    return HazriScreen(
      title: l.accountTitle,
      children: account == null ? _notJoined(context, l) : _joined(context, ref, l, account),
    );
  }

  /// Nobody has joined on this phone, which is the ordinary case. The screen
  /// says so and offers the way in rather than showing empty rows.
  List<Widget> _notJoined(BuildContext context, L l) {
    final c = context.colors;
    return [
      const SizedBox(height: 24),
      Center(
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(color: c.card2, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: AppIcon(HazriIconData.sangat, size: 32, color: c.ink2),
        ),
      ),
      const SizedBox(height: 16),
      Text(
        l.accountJoinedFirst,
        textAlign: TextAlign.center,
        style: HazriText.body.copyWith(color: c.ink2),
      ),
      const SizedBox(height: 20),
      PrimaryButton(label: l.sangatBannerCta, onPressed: () => context.push(Routes.sangatJoin)),
    ];
  }

  List<Widget> _joined(BuildContext context, WidgetRef ref, L l, SangatAccount a) {
    final c = context.colors;
    final verified = a.emailVerified;
    return [
      const SizedBox(height: 6),
      HazriCard(
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: c.kesriSoft, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(
                _initials(a.name),
                style: HazriText.bodyStrong.copyWith(color: c.kesriInk, fontSize: 18),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.name, style: HazriText.display22.copyWith(color: c.ink, fontSize: 20)),
                  if (a.city.isNotEmpty)
                    Text(a.city, style: HazriText.caption.copyWith(color: c.muted)),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 13),
      HazriCard(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            _AccountRow(
              icon: HazriIconData.mail,
              title: l.accountEmail,
              value: a.email ?? l.accountNotAdded,
              // The one word on this screen that is worth colour. Verified is
              // stated plainly rather than celebrated; not verified is kesri
              // because it is the one thing here still to do.
              trailing: a.email == null
                  ? null
                  : Text(
                      verified ? l.accountVerified : l.accountNotVerified,
                      style: HazriText.captionStrong.copyWith(
                        color: verified ? c.sage : c.kesriInk,
                      ),
                    ),
            ),
            Divider(height: 1, color: c.rule),
            _AccountRow(
              icon: HazriIconData.mobile,
              title: l.accountPhone,
              value: a.phone ?? l.accountNotAdded,
            ),
            Divider(height: 1, color: c.rule),
            _AccountRow(
              icon: HazriIconData.globe,
              title: l.accountCity,
              value: a.city.isEmpty ? l.accountNotAdded : a.city,
            ),
          ],
        ),
      ),
      const SizedBox(height: 13),
      if (!verified)
        HazriCard(
          colour: c.kesriSoft,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppIcon(HazriIconData.mail, size: 20, color: c.kesriInk),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.accountVerifyTitle,
                          style: HazriText.captionStrong.copyWith(
                            color: c.kesriInk,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l.accountVerifyBody,
                          style: HazriText.caption.copyWith(color: c.kesriInk),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 11),
              PrimaryButton(
                label: l.accountVerifyCta,
                minHeight: 44,
                onPressed: () => context.push(Routes.verifyEmail),
              ),
            ],
          ),
        )
      else
        HazriCard(
          colour: c.sageSoft,
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppIcon(HazriIconData.check, size: 20, color: c.sage),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.accountSafeTitle,
                      style: HazriText.captionStrong.copyWith(color: c.sage, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(l.accountSafeBody, style: HazriText.caption.copyWith(color: c.ink2)),
                  ],
                ),
              ),
            ],
          ),
        ),
      const SizedBox(height: 13),
      HazriCard(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            _AccountRow(
              icon: HazriIconData.check,
              title: l.syncTitle,
              value: l.syncSubtitle,
              chevron: true,
              onTap: () => context.push(Routes.sync),
            ),
            Divider(height: 1, color: c.rule),
            _AccountRow(
              icon: HazriIconData.lock,
              title: l.privacyDataTitle,
              value: l.privacyDownloadSub,
              chevron: true,
              onTap: () => context.push(Routes.privacy),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      PrimaryButton(
        label: l.accountSignOut,
        secondary: true,
        onPressed: () => _confirmSignOut(context, ref, l, verified),
      ),
    ];
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref, L l, bool verified) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l.accountSignOut),
        // An unverified account cannot be reached again, so signing out of it
        // ends it. A verified one is told nothing extra here, because being
        // able to come back is not yet built and promising it would be a lie.
        content: verified ? null : Text(l.accountSignOutWarn),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: Text(l.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(true),
            child: Text(l.accountSignOutConfirm),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(accountRepositoryProvider).signOut();
  }

  /// Up to two letters, from the first and last word of the name. Works the
  /// same in Gurmukhi and Devanagari, where a "letter" is one grapheme and
  /// `substring(0, 1)` would cut a matra off its consonant.
  static String _initials(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '';
    String first(String w) => String.fromCharCodes(w.runes.take(1));
    if (words.length == 1) return first(words.first).toUpperCase();
    return (first(words.first) + first(words.last)).toUpperCase();
  }
}

/// One row of design 33's detail cards: an icon tile, a label, the value
/// under it, and either a state word or a chevron on the right.
class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.icon,
    required this.title,
    required this.value,
    this.trailing,
    this.chevron = false,
    this.onTap,
  });

  final String icon;
  final String title;
  final String value;
  final Widget? trailing;
  final bool chevron;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: c.card2,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: AppIcon(icon, size: 19, color: c.ink2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: HazriText.bodyStrong.copyWith(color: c.ink)),
                  Text(
                    value,
                    style: HazriText.caption.copyWith(color: c.muted),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (trailing != null)
              Padding(padding: const EdgeInsets.only(left: 10), child: trailing!),
            if (chevron)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: AppIcon(HazriIconData.chevronRight, size: 18, color: c.muted),
              ),
          ],
        ),
      ),
    );
  }
}
