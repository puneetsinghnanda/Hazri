import 'package:flutter/material.dart';

import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';

/// Hour · minute (in five-minute steps) · AM/PM, or 24-hour if the device is
/// set that way (Design 08).
class TimeWheel extends StatefulWidget {
  const TimeWheel({super.key, required this.value, required this.onChanged});

  final TimeOfDay value;
  final ValueChanged<TimeOfDay> onChanged;

  @override
  State<TimeWheel> createState() => _TimeWheelState();
}

class _TimeWheelState extends State<TimeWheel> {
  late FixedExtentScrollController _hours;
  late FixedExtentScrollController _minutes;
  late FixedExtentScrollController _meridiem;
  bool? _use24;

  @override
  void initState() {
    super.initState();
    _hours = FixedExtentScrollController();
    _minutes = FixedExtentScrollController();
    _meridiem = FixedExtentScrollController();
  }

  @override
  void dispose() {
    _hours.dispose();
    _minutes.dispose();
    _meridiem.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final use24 = MediaQuery.maybeOf(context)?.alwaysUse24HourFormat ?? false;
    if (_use24 == use24) return;
    _use24 = use24;
    final h = widget.value.hour;
    _hours = FixedExtentScrollController(
      initialItem: use24 ? h : (h % 12 == 0 ? 11 : h % 12 - 1),
    );
    _minutes = FixedExtentScrollController(initialItem: widget.value.minute ~/ 5);
    _meridiem = FixedExtentScrollController(initialItem: h < 12 ? 0 : 1);
  }

  void _emit() {
    final use24 = _use24 ?? false;
    final minute = (_minutes.selectedItem % 12) * 5;
    final int hour;
    if (use24) {
      hour = _hours.selectedItem % 24;
    } else {
      final base = (_hours.selectedItem % 12) + 1;
      final pm = _meridiem.selectedItem % 2 == 1;
      hour = base == 12 ? (pm ? 12 : 0) : (pm ? base + 12 : base);
    }
    widget.onChanged(TimeOfDay(hour: hour, minute: minute));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final use24 = _use24 ?? false;

    return Container(
      height: 168,
      decoration: BoxDecoration(
        color: c.card2,
        borderRadius: BorderRadius.circular(HazriRadius.card),
      ),
      child: Stack(
        children: [
          Center(
            child: Container(
              height: 46,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _Wheel(
                  controller: _hours,
                  count: use24 ? 24 : 12,
                  label: (i) => use24
                      ? i.toString().padLeft(2, '0')
                      : (i + 1).toString(),
                  onChanged: _emit,
                ),
              ),
              Text(':', style: HazriText.display22.copyWith(color: c.muted)),
              Expanded(
                child: _Wheel(
                  controller: _minutes,
                  count: 12,
                  label: (i) => (i * 5).toString().padLeft(2, '0'),
                  onChanged: _emit,
                ),
              ),
              if (!use24)
                Expanded(
                  child: _Wheel(
                    controller: _meridiem,
                    count: 2,
                    loop: false,
                    label: (i) => i == 0 ? 'AM' : 'PM',
                    onChanged: _emit,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Wheel extends StatelessWidget {
  const _Wheel({
    required this.controller,
    required this.count,
    required this.label,
    required this.onChanged,
    this.loop = true,
  });

  final FixedExtentScrollController controller;
  final int count;
  final String Function(int) label;
  final VoidCallback onChanged;
  final bool loop;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = HazriText.display22.copyWith(color: c.ink);
    Widget item(int i) => Center(child: Text(label(i), style: style));

    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: 46,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: (_) => onChanged(),
      childDelegate: loop
          ? ListWheelChildLoopingListDelegate(
              children: [for (var i = 0; i < count; i++) item(i)],
            )
          : ListWheelChildListDelegate(
              children: [for (var i = 0; i < count; i++) item(i)],
            ),
    );
  }
}
