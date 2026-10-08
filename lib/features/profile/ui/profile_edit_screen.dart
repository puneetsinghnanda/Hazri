import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/backend/api_exception.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/widgets/surfaces.dart';
import '../../reminders/data/reminders_controller.dart';
import '../../settings/ui/screen_scaffold.dart';
import '../data/profile_api.dart';
import '../data/profile_controller.dart';
import '../domain/validators.dart';
import 'change_email_dialog.dart';
import 'city_field.dart';
import 'messages.dart';

/// Edit profile (`01-accounts.md` §13.8): name and city; the email through
/// the Change Email dialog; the phone is not editable.
class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  String? _cityId;
  bool _busy = false;
  String? _nameServerError;

  @override
  void initState() {
    super.initState();
    final p = ref.read(profileProvider);
    _name = TextEditingController(text: p?.name ?? '');
    _cityId = p?.cityId;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _changed {
    final p = ref.read(profileProvider);
    if (p == null) return false;
    return normalizeName(_name.text) != p.name || _cityId != p.cityId;
  }

  Future<void> _save() async {
    final l = L.of(context);
    final p = ref.read(profileProvider);
    if (p == null || !_form.currentState!.validate()) return;
    final name = normalizeName(_name.text);
    setState(() {
      _busy = true;
      _nameServerError = null;
    });
    try {
      final updated = await ref.read(profileApiProvider).update(
            name: name == p.name ? null : name,
            cityId: _cityId == p.cityId ? null : _cityId,
          );
      await ref.read(profileControllerProvider.notifier).setProfile(updated);
      // A new city moves the sunrise in the Amrit Vela message.
      ref.read(reminderSchedulerProvider).requestReschedule();
      if (!mounted) return;
      ProfileMessages.snack(context, l.profileUpdated);
      context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        if (e.code == 'VALIDATION_ERROR' && e.fields['name'] != null) {
          _nameServerError = ProfileMessages.serverField(l, e.fields['name']!);
        }
      });
      if (e.code == 'NO_PROFILE') {
        await ref.read(profileControllerProvider.notifier).markNone();
      } else if (e.code == 'NOTHING_CHANGED') {
        // P-3: the button is disabled for this; nothing to say.
      } else if (e.code != 'VALIDATION_ERROR') {
        ProfileMessages.snack(context, ProfileMessages.of(l, e));
      }
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
    final p = ref.watch(profileProvider);

    return HazriScreen(
      title: l.profileEditTitle,
      children: [
        Form(
          key: _form,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _name,
                enabled: !_busy,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: l.profileFieldName, errorText: _nameServerError),
                onChanged: (_) => setState(() => _nameServerError = null),
                validator: (v) {
                  final e = validateName(v ?? '');
                  return e == null ? null : ProfileMessages.field(l, e);
                },
              ),
              const SizedBox(height: 12),
              CityField(
                cityId: _cityId,
                enabled: !_busy,
                onChanged: (id) => setState(() => _cityId = id),
              ),
              const SizedBox(height: 16),
              Text(l.profileRowEmail, style: HazriText.caption.copyWith(color: c.muted)),
              const SizedBox(height: 4),
              Text(p?.email ?? '', style: HazriText.bodyStrong.copyWith(color: c.ink)),
              if (p?.pendingEmail != null)
                Text(l.profileEmailPending(p!.pendingEmail!), style: HazriText.caption.copyWith(color: c.kesriInk)),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  onPressed: _busy ? null : () => showChangeEmailDialog(context),
                  child: Text(l.profileChangeEmail),
                ),
              ),
              const SizedBox(height: 24),
              _busy
                  ? const Center(child: CircularProgressIndicator())
                  : PrimaryButton(label: l.profileEditSave, onPressed: _changed ? _save : null),
            ],
          ),
        ),
      ],
    );
  }
}
