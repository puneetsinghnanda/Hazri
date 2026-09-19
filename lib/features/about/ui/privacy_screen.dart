import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/surfaces.dart';
import '../../sangat/data/account_repository.dart';
import '../../sangat/data/group_repository.dart';
import '../../sangat/domain/sangat_account.dart';
import '../../settings/ui/screen_scaffold.dart';

/// Design 35 — what is on the phone, what the sangat sees, and the two
/// buttons that let somebody take it back.
///
/// The three headings are the point. Most of what this app knows never
/// leaves the phone, and saying which is which — rather than one paragraph
/// about caring deeply — is the only version of this screen worth having.
/// PRD §13.1 is what it must agree with, and neither runs ahead of the other.
class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final account = ref.watch(sangatAccountProvider).value;

    return HazriScreen(
      title: l.privacyDataTitle,
      children: [
        const SizedBox(height: 6),
        Text(l.privacyBody, style: HazriText.body.copyWith(color: c.ink2)),
        const SizedBox(height: 16),
        HazriCard(
          colour: c.sageSoft,
          child: Text(
            l.privacyNoAnalytics,
            style: HazriText.bodySmall.copyWith(color: c.sage),
          ),
        ),
        const SizedBox(height: 6),

        _Section(title: l.privacyOnPhoneOnly, icon: HazriIconData.lock, items: [
          l.privacyPhoneDiary,
          l.privacyPhoneProgress,
          l.privacyPhoneContent,
        ]),

        // Shown whether or not somebody joined, because what the sangat would
        // see is exactly what somebody deciding needs to read.
        _Section(title: l.privacySharedWithSangat, icon: HazriIconData.sangat, items: [
          l.privacyShareName,
          l.privacyShareCity,
          l.privacyShareGroups,
          l.privacyShareCounts,
        ]),

        _Section(title: l.privacyAccountOnly, icon: HazriIconData.mail, items: [
          l.privacyAccountEmail,
        ]),

        const SizedBox(height: 18),
        if (account == null)
          HazriCard(
            colour: c.card2,
            child: Text(l.privacyNotJoined,
                style: HazriText.bodySmall.copyWith(color: c.ink2)),
          )
        else ...[
          HazriCard(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                SettingsRow(
                  title: l.privacyShowMyName,
                  subtitle: l.privacyShowMyNameSub,
                  trailing: Switch(
                    value: account.showName,
                    onChanged: (v) => ref
                        .read(accountRepositoryProvider)
                        .updateProfile(account.copyWith(showName: v)),
                  ),
                ),
                Divider(height: 1, color: c.rule),
                SettingsRow(
                  title: l.privacyDownload,
                  subtitle: l.privacyDownloadSub,
                  onTap: () => _download(context, ref, account),
                ),
                Divider(height: 1, color: c.rule),
                SettingsRow(
                  title: l.privacyDelete,
                  subtitle: l.privacyDeleteSub,
                  danger: true,
                  onTap: () => _delete(context, ref, l),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        HazriCard(
          colour: c.card2,
          child: Text(
            l.privacySangat,
            style: HazriText.bodySmall.copyWith(color: c.ink2),
          ),
        ),
      ],
    );
  }

  /// Everything the server holds, as a file somebody can actually read.
  ///
  /// JSON rather than a formatted report: the promise is that this is what is
  /// held, and a rewritten summary is a different thing from the data.
  Future<void> _download(
    BuildContext context,
    WidgetRef ref,
    SangatAccount account,
  ) async {
    final groups = ref.read(myGroupsProvider).value ?? const [];
    final data = {
      'account': {
        'name': account.name,
        'city': account.city,
        'email': account.email,
        'phone': account.phone,
        'emailVerified': account.emailVerified,
        'showName': account.showName,
      },
      'groups': [
        for (final g in groups)
          {
            'name': g.name,
            'kind': g.kind.name,
            'yourCount': g.yours,
            'youAreAdmin': g.youAreAdmin,
          },
      ],
      'note': 'Your diary, goals and reading position are not here because '
          'they are not held anywhere but this phone.',
    };

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/hazri-my-data.json');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
    if (!context.mounted) return;
    await Share.shareXFiles([XFile(file.path)]);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, L l) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l.privacyDelete),
        content: Text(l.privacyDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: Text(l.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(true),
            child: Text(l.privacyDeleteDo),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    final outcome = await ref.read(accountRepositoryProvider).deleteEverything();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          outcome is JoinedSangat ? l.privacyDeleted : l.sangatUnavailable,
        ),
      ),
    );
  }
}

/// One heading and the plain list under it.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.icon, required this.items});

  final String title;
  final String icon;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
          child: Row(
            children: [
              AppIcon(icon, size: 16, color: c.muted),
              const SizedBox(width: 8),
              Flexible(child: Eyebrow(title)),
            ],
          ),
        ),
        HazriCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(color: c.muted, shape: BoxShape.circle),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(items[i],
                          style: HazriText.bodySmall.copyWith(color: c.ink2)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
