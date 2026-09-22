import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/surfaces.dart';
import '../../settings/ui/screen_scaffold.dart';
import '../data/group_repository.dart';
import '../domain/sangat_group.dart';

/// Where an invite points.
///
/// **The website does not exist yet, so the link does not open anything.**
/// That is why this screen leads with the code rather than the URL: the code
/// is the group id, the join screen takes it pasted or typed, and it works
/// today. The link is here so an invite sent now still reads sensibly once
/// the site is built, and the share message says which half to use.
const String kInviteBase = 'https://puneetsinghnanda.vercel.app/hazri-app/j';

String inviteLinkFor(String groupId) => '$kInviteBase/$groupId';

/// The group id inside an invite, whether somebody pasted the whole link or
/// typed the code off the end of it.
///
/// Deliberately forgiving: it takes the last non-empty path segment, so a
/// trailing slash, a `?from=whatsapp` a messaging app added, and a bare code
/// all lead to the same group. Being strict here would only mean telling
/// somebody their own invite is wrong.
String groupIdFromInvite(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return '';
  final withoutQuery = trimmed.split('?').first.split('#').first;
  final parts = withoutQuery.split('/').where((p) => p.isNotEmpty).toList();
  return parts.isEmpty ? '' : parts.last;
}

/// Design 41 — the link, and who is already in.
class GroupInviteScreen extends ConsumerWidget {
  const GroupInviteScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final group = ref.watch(groupProvider(groupId)).value;
    final members = ref.watch(groupMembersProvider(groupId)).value ?? const <GroupMember>[];
    final link = inviteLinkFor(groupId);

    return HazriScreen(
      title: l.groupInviteTitle,
      subtitle: group?.name,
      children: [
        const SizedBox(height: 6),
        // The code first, because the code is the part that works.
        Eyebrow(l.groupInviteCode),
        const SizedBox(height: 8),
        HazriCard(
          colour: c.kesriSoft,
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: groupId));
            if (!context.mounted) return;
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(l.groupCodeCopied)));
          },
          child: Row(
            children: [
              Expanded(
                child: SelectableText(
                  groupId,
                  style: HazriText.bodyStrong.copyWith(color: c.kesriInk),
                ),
              ),
              const SizedBox(width: 10),
              AppIcon(HazriIconData.copy, size: 19, color: c.kesriInk),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(l.groupInviteCodeHow,
            style: HazriText.caption.copyWith(color: c.muted)),
        const SizedBox(height: 16),
        PrimaryButton(
          label: l.groupInviteShare,
          icon: HazriIconData.share,
          // The message carries the code and how to use it, so what lands in
          // somebody's WhatsApp is something they can act on rather than a
          // link that goes nowhere yet.
          onPressed: () => Share.share(
            l.groupInviteShareText(group?.name ?? l.sangatTitle, groupId),
            subject: group?.name,
          ),
        ),
        const SizedBox(height: 18),
        Eyebrow(l.groupInviteShareLink),
        const SizedBox(height: 8),
        HazriCard(
          colour: c.card2,
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: link));
            if (!context.mounted) return;
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(l.groupInviteCopied)));
          },
          child: Row(
            children: [
              Expanded(
                child: Text(
                  link,
                  style: HazriText.caption.copyWith(color: c.muted),
                  maxLines: 2,
                ),
              ),
              const SizedBox(width: 10),
              AppIcon(HazriIconData.copy, size: 17, color: c.muted),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Eyebrow(l.groupMembers(members.length)),
        const SizedBox(height: 8),
        HazriCard(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            children: [
              for (var i = 0; i < members.length; i++) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              members[i].name.isEmpty
                                  ? l.groupAnonMember
                                  : members[i].name,
                              style: HazriText.bodyStrong.copyWith(color: c.ink),
                            ),
                            if (members[i].isAdmin)
                              Text(l.groupInviteStarted,
                                  style: HazriText.caption.copyWith(color: c.muted)),
                          ],
                        ),
                      ),
                      if (members[i].isAdmin)
                        HazriChip(
                          label: l.groupAdmin,
                          background: c.card2,
                          foreground: c.muted,
                          minHeight: 26,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 3),
                        ),
                    ],
                  ),
                ),
                if (i != members.length - 1) Divider(height: 1, color: c.rule),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
