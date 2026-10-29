import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/backend/api_exception.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/widgets/surfaces.dart';
import '../../profile/ui/messages.dart';
import '../../settings/ui/screen_scaffold.dart';
import '../data/sangat_api.dart';
import '../data/sangat_controller.dart';
import '../domain/sangat_models.dart';

/// Join (§8.2, IV7, IV8): a code typed or pasted, or filled from an App Link
/// or the install referrer. The clipboard is read only when Paste is tapped.
class JoinScreen extends ConsumerStatefulWidget {
  const JoinScreen({super.key, this.code});

  final String? code;

  @override
  ConsumerState<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends ConsumerState<JoinScreen> {
  late final _code = TextEditingController(
    text: widget.code == null ? '' : formatInviteCode(normalizeInviteCode(widget.code!) ?? widget.code!),
  );
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text ?? '';
    // A whole invite message pasted: take the code out of it.
    final match = RegExp(
      r'[A-Za-z2-9]{4}-?[A-Za-z2-9]{4}',
    ).allMatches(text).map((m) => m.group(0)!).where((c) => normalizeInviteCode(c) != null);
    setState(() {
      _code.text = match.isEmpty ? text.trim() : formatInviteCode(normalizeInviteCode(match.last)!);
      _error = null;
    });
  }

  Future<void> _join() async {
    final l = L.of(context);
    final code = normalizeInviteCode(_code.text);
    if (code == null) {
      setState(() => _error = l.sangatCodeInvalid);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final groupId = await ref.read(sangatApiProvider).join(code);
      await ref.read(sangatListsProvider.notifier).setMember(true);
      await ref.read(sangatListsProvider.notifier).refresh();
      if (mounted) context.pushReplacement(Routes.sangatGroup(groupId));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = switch (e.code) {
          'GROUP_FULL' => l.sangatGroupFull,
          'GROUP_INACTIVE' => l.sangatGroupEnded,
          'CODE_INVALID' || 'VALIDATION_ERROR' => l.sangatCodeInvalid,
          _ => ProfileMessages.of(l, e),
        };
      });
    } on NetworkException {
      if (!mounted) return;
      setState(() => _busy = false);
      ProfileMessages.snack(context, l.msgNetwork);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    return HazriScreen(
      title: l.sangatJoinTitle,
      children: [
        if (widget.code != null) ...[
          Text(l.sangatJoinFromInvite, style: HazriText.body.copyWith(color: c.ink2)),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: _code,
          enabled: !_busy,
          textCapitalization: TextCapitalization.characters,
          autocorrect: false,
          style: HazriText.display22.copyWith(color: c.ink, letterSpacing: 2),
          decoration: InputDecoration(labelText: l.sangatCodeLabel, hintText: 'XXXX-XXXX', errorText: _error),
          onChanged: (_) => setState(() => _error = null),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton(onPressed: _busy ? null : _paste, child: Text(l.sangatPasteCode)),
        ),
        const SizedBox(height: 16),
        _busy ? const Center(child: CircularProgressIndicator()) : PrimaryButton(label: l.sangatJoin, onPressed: _join),
      ],
    );
  }
}
