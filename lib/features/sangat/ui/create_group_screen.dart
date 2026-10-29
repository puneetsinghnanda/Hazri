import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/backend/api_exception.dart';
import '../../../core/db/content_repository.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/time/clock.dart';
import '../../../core/time/date_format.dart';
import '../../../core/widgets/surfaces.dart';
import '../../nitnem/domain/bani.dart';
import '../../profile/ui/messages.dart';
import '../../settings/ui/screen_scaffold.dart';
import '../data/sangat_api.dart';
import '../data/sangat_controller.dart';

/// The group day in India Standard Time (08-sangat §2), whatever the phone's
/// zone.
DateTime istToday([DateTime? now]) {
  final ist = (now ?? DateTime.now()).toUtc().add(const Duration(hours: 5, minutes: 30));
  return DateTime(ist.year, ist.month, ist.day);
}

/// Create group (§8.2): a name, then the goal straight after (CG3), then
/// the group, where Share invite is offered.
class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _target = TextEditingController();
  bool _simran = false;
  String? _baniId;
  late DateTime _end = istToday().add(const Duration(days: 39));
  bool _busy = false;
  String? _baniError;

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final l = L.of(context);
    setState(() => _baniError = !_simran && _baniId == null ? l.sangatChooseBani : null);
    if (!_form.currentState!.validate() || _baniError != null) return;
    setState(() => _busy = true);
    final api = ref.read(sangatApiProvider);
    try {
      final group = await api.create(_name.text.trim());
      await api.setGoal(
        group.groupId,
        type: _simran ? 'SIMRAN' : 'BANI',
        baniId: _simran ? null : _baniId,
        target: int.parse(_target.text),
        endDay: localDateKey(_end),
      );
      await ref.read(sangatListsProvider.notifier).setMember(true);
      await ref.read(sangatListsProvider.notifier).refresh();
      if (mounted) context.pushReplacement(Routes.sangatGroup(group.groupId, share: true));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ProfileMessages.snack(
        context,
        e.code == 'GROUP_LIMIT_REACHED' ? l.sangatLimitReached(e.limit ?? 5) : ProfileMessages.of(l, e),
      );
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
    final dates = HazriDates.of(context);
    final banis = ref.watch(banisProvider).value ?? const <Bani>[];
    final today = istToday();

    return HazriScreen(
      title: l.sangatCreate,
      children: [
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _name,
                enabled: !_busy,
                maxLength: 64,
                decoration: InputDecoration(labelText: l.sangatGroupName),
                validator: (v) => (v ?? '').trim().isEmpty ? l.sangatNameRequired : null,
              ),
              const SizedBox(height: 12),
              Eyebrow(l.sangatGoalTitle),
              const SizedBox(height: 8),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(value: false, label: Text(l.sangatGoalBani)),
                  ButtonSegment(value: true, label: Text(l.sangatGoalSimran)),
                ],
                selected: {_simran},
                onSelectionChanged: _busy ? null : (s) => setState(() => _simran = s.first),
              ),
              const SizedBox(height: 12),
              // A Naam Simran goal counts minutes (08-sangat SG-1), so it
              // needs no bani and no sitting length: only its target.
              if (!_simran)
                DropdownButtonFormField<String>(
                  initialValue: _baniId,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l.sangatChooseBani, errorText: _baniError),
                  items: [for (final b in banis) DropdownMenuItem(value: b.id, child: Text(b.name(l.localeName)))],
                  onChanged: _busy ? null : (v) => setState(() => _baniId = v),
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _target,
                enabled: !_busy,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(labelText: _simran ? l.sangatGoalTargetMinutes : l.sangatGoalTarget),
                validator: (v) {
                  final t = int.tryParse(v ?? '');
                  return t == null || t < 1 || t > 1000000 ? l.sangatTargetInvalid : null;
                },
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _busy
                    ? null
                    : () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _end,
                          firstDate: today,
                          lastDate: today.add(const Duration(days: 364)),
                        );
                        if (picked != null) setState(() => _end = picked);
                      },
                child: InputDecorator(
                  decoration: InputDecoration(labelText: l.sangatGoalEnds),
                  child: Text(dates.shortDate(_end), style: HazriText.body.copyWith(color: c.ink)),
                ),
              ),
              const SizedBox(height: 10),
              Text(l.sangatGoalOnce, style: HazriText.caption.copyWith(color: c.muted)),
              const SizedBox(height: 20),
              _busy
                  ? const Center(child: CircularProgressIndicator())
                  : PrimaryButton(label: l.sangatCreateAction, onPressed: _create),
            ],
          ),
        ),
      ],
    );
  }
}
