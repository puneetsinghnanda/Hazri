import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/widgets/surfaces.dart';
import '../../settings/ui/screen_scaffold.dart';
import '../data/group_repository.dart';
import 'group_invite_screen.dart' show groupIdFromInvite;
import 'sangat_field.dart';

/// Joining a private group from the link somebody sent.
///
/// Typed rather than tapped, deliberately. The App Links that would make the
/// link itself open the app need a release fingerprint the project does not
/// have yet, so a link that cannot be tapped is still a link that can be
/// pasted — and the code at the end of it is all this needs.
class JoinByLinkScreen extends ConsumerStatefulWidget {
  const JoinByLinkScreen({super.key, this.arrivedWith});

  /// A group id the app was *opened* with, from a tapped invite. The box is
  /// filled in so the reader can see what they are joining, and left for them
  /// to confirm rather than joining a sangat the instant a link is tapped --
  /// joining is a thing you agree to, not a thing that happens to you.
  final String? arrivedWith;

  @override
  ConsumerState<JoinByLinkScreen> createState() => _JoinByLinkScreenState();
}

class _JoinByLinkScreenState extends ConsumerState<JoinByLinkScreen> {
  final _link = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final code = widget.arrivedWith;
    if (code != null && code.isNotEmpty) _link.text = code;
  }

  @override
  void dispose() {
    _link.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final l = L.of(context);
    final id = groupIdFromInvite(_link.text);
    if (id.isEmpty) {
      setState(() => _error = l.groupJoinByLinkLabel);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });

    final outcome = await ref.read(groupRepositoryProvider).join(id);
    if (!mounted) return;

    switch (outcome) {
      case GroupOk():
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.groupJoinedOne)));
        context.pushReplacement(Routes.group(id));
      case GroupNotFound():
        setState(() {
          _busy = false;
          _error = l.groupGone;
        });
      case GroupRefused():
        setState(() {
          _busy = false;
          _error = l.sangatRefused;
        });
      case GroupUnavailable():
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
      title: l.groupJoinByLinkTitle,
      children: [
        const SizedBox(height: 6),
        Text(l.groupJoinByLinkBody, style: HazriText.body.copyWith(color: c.ink2)),
        const SizedBox(height: 18),
        SangatField(
          label: l.groupJoinByLinkLabel,
          controller: _link,
          keyboardType: TextInputType.url,
        ),
        if (_error != null) ...[
          const SizedBox(height: 14),
          Text(_error!, style: HazriText.bodySmall.copyWith(color: c.kesriInk)),
        ],
        const SizedBox(height: 20),
        PrimaryButton(
          label: l.groupJoinByLinkCta,
          onPressed: _busy ? null : _join,
        ),
      ],
    );
  }
}
