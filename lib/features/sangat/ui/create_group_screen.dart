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
import '../data/group_repository.dart';
import '../domain/sangat_group.dart';
import 'sangat_field.dart';

/// Design 39 — making a group.
///
/// Every group made here is private. Listing one puts its name in front of
/// people who never met whoever chose it, which is the question the reader
/// asked first about this feature, and the answer is that a name is read
/// before it appears. `firestore.rules` refuses `listed` from a phone, so
/// this is not a promise the UI keeps by being polite.
class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _name = TextEditingController();
  GroupKind _kind = GroupKind.family;
  bool _wantsListed = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final l = L.of(context);
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = l.groupNeedName);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });

    final outcome = await ref.read(groupRepositoryProvider).create(
          name: name,
          kind: _kind,
          wantsListing: _wantsListed,
        );
    if (!mounted) return;

    switch (outcome) {
      case GroupOk(group: final group):
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.groupCreated)));
        if (group != null && group.id.isNotEmpty) {
          context.pushReplacement(Routes.group(group.id));
        } else {
          context.pop();
        }
      case GroupUnavailable():
        setState(() {
          _busy = false;
          _error = l.sangatUnavailable;
        });
      case GroupRefused():
        setState(() {
          _busy = false;
          _error = l.sangatRefused;
        });
      case GroupNotFound():
      case GroupFailed():
        setState(() {
          _busy = false;
          _error = l.sangatUnavailable;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);

    return HazriScreen(
      title: l.groupCreateTitle,
      children: [
        const SizedBox(height: 6),
        Eyebrow(l.groupWhatKind),
        const SizedBox(height: 8),
        HazriCard(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            children: [
              for (final kind in GroupKind.values) ...[
                _ChoiceRow(
                  title: switch (kind) {
                    GroupKind.family => l.groupKindFamily,
                    GroupKind.sangat => l.groupKindSangat,
                    GroupKind.circle => l.groupKindCircle,
                  },
                  subtitle: switch (kind) {
                    GroupKind.family => l.groupKindFamilySub,
                    GroupKind.sangat => l.groupKindSangatSub,
                    GroupKind.circle => l.groupKindCircleSub,
                  },
                  selected: _kind == kind,
                  onTap: () => setState(() => _kind = kind),
                ),
                if (kind != GroupKind.values.last)
                  Divider(height: 1, color: c.rule),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        SangatField(
          label: l.groupNameLabel,
          controller: _name,
          hint: l.groupNameHint,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 18),
        Eyebrow(l.groupWhoCanFind),
        const SizedBox(height: 8),
        HazriCard(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            children: [
              _ChoiceRow(
                title: l.groupPrivate,
                subtitle: l.groupPrivateSub,
                selected: !_wantsListed,
                onTap: () => setState(() => _wantsListed = false),
              ),
              Divider(height: 1, color: c.rule),
              _ChoiceRow(
                title: l.groupListed,
                subtitle: l.groupListedSub,
                selected: _wantsListed,
                onTap: () => setState(() => _wantsListed = true),
              ),
            ],
          ),
        ),
        if (_wantsListed) ...[
          const SizedBox(height: 10),
          HazriCard(
            colour: c.card2,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppIcon(HazriIconData.alert, size: 18, color: c.kesriInk),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(l.groupListedNote,
                      style: HazriText.caption.copyWith(color: c.ink2)),
                ),
              ],
            ),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 14),
          Text(_error!, style: HazriText.bodySmall.copyWith(color: c.kesriInk)),
        ],
        const SizedBox(height: 20),
        PrimaryButton(
          label: l.groupCreateCta,
          onPressed: _busy ? null : _create,
        ),
      ],
    );
  }
}

/// A radio row that does not look like a radio: the tick is the selection.
class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: HazriText.bodyStrong.copyWith(color: c.ink)),
                  Text(subtitle, style: HazriText.caption.copyWith(color: c.muted)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (selected)
              AppIcon(HazriIconData.check, size: 20, color: c.kesri)
            else
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: c.rule, width: 1.5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
