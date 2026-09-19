import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/surfaces.dart';
import '../../../app/router.dart';
import '../data/account_repository.dart';
import '../domain/sangat_account.dart';
import 'sangat_field.dart';

/// Design 32 — the form that joins the sangat.
///
/// Tapping Continue is the first network request this app ever makes on this
/// phone: the anonymous account is created here, not at launch. Nothing above
/// this screen has touched a server.
class JoinSangatScreen extends ConsumerStatefulWidget {
  const JoinSangatScreen({super.key});

  @override
  ConsumerState<JoinSangatScreen> createState() => _JoinSangatScreenState();
}

class _JoinSangatScreenState extends ConsumerState<JoinSangatScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _city = TextEditingController();

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _city]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _join() async {
    final l = L.of(context);
    final name = _name.text.trim();
    final email = _email.text.trim();
    final city = _city.text.trim();

    String? complaint;
    if (name.isEmpty) {
      complaint = l.sangatNeedName;
    } else if (email.isEmpty) {
      complaint = l.sangatNeedEmail;
    } else if (!SangatAccount.looksLikeEmail(email)) {
      complaint = l.sangatBadEmail;
    } else if (city.isEmpty) {
      complaint = l.sangatNeedCity;
    }
    if (complaint != null) {
      setState(() => _error = complaint);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final outcome = await ref.read(accountRepositoryProvider).join(
          name: name,
          email: email,
          city: city,
          phone: _phone.text.trim(),
        );
    if (!mounted) return;

    switch (outcome) {
      case JoinedSangat():
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.sangatJoined)));
        context.pop();
      case EmailAlreadyHasAccount(email: final existing):
        // Design 53's fork. Not an error: coming back and starting again are
        // both legitimate, and the screen that offers them keeps the address
        // so nobody types it twice.
        context.push(Routes.restore(email: existing));
        setState(() => _busy = false);
      case LinkDidNotWork():
        // Cannot arrive from a join; the switch is exhaustive so that a new
        // outcome cannot be forgotten here.
        setState(() {
          _busy = false;
          _error = l.sangatUnavailable;
        });
      case SangatUnavailable():
        setState(() {
          _busy = false;
          _error = l.sangatUnavailable;
        });
      case SangatRefused():
        // The server answered and said no, which is our bug rather than the
        // reader's circumstances. Telling them to check their signal would
        // send them hunting for a fault that is not theirs.
        setState(() {
          _busy = false;
          _error = l.sangatRefused;
        });
      case JoinFailed():
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

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: PhoneWidth(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
            children: [
              Row(
                children: [
                  CardIconButton(
                    icon: HazriIconData.chevronLeft,
                    tooltip: l.actionBack,
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.sangatProfileTitle,
                            style: HazriText.display22.copyWith(color: c.ink)),
                        Text(l.sangatProfileSub,
                            style: HazriText.caption.copyWith(color: c.muted)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SangatField(
                label: l.sangatFieldName,
                controller: _name,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 14),
              SangatField(
                label: l.sangatFieldEmail,
                controller: _email,
                hint: l.sangatFieldEmailHint,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),
              SangatField(
                label: l.sangatFieldPhone,
                controller: _phone,
                placeholder: l.sangatFieldPhoneHint,
                optionalLabel: l.sangatOptional,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),
              SangatField(
                label: l.sangatFieldCity,
                controller: _city,
                hint: l.sangatFieldCityHint,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 18),
              HazriCard(
                colour: c.card2,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppIcon(HazriIconData.check, size: 18, color: c.sage),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(l.sangatNoPasswordEver,
                          style: HazriText.caption.copyWith(color: c.ink2)),
                    ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(
                  _error!,
                  style: HazriText.bodySmall.copyWith(color: c.kesriInk),
                ),
              ],
              const SizedBox(height: 18),
              PrimaryButton(
                label: l.sangatContinue,
                onPressed: _busy ? null : _join,
              ),
              const SizedBox(height: 14),
              Center(
                child: Text(l.sangatWhatWeStore,
                    style: HazriText.caption.copyWith(color: c.muted)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
