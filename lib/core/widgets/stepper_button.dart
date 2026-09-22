import 'package:flutter/material.dart';

import '../theme/hazri_colors.dart';
import '../theme/hazri_text.dart';

/// One half of a stepper: a large − or + in a soft square.
///
/// Designs 20, 40 and 42 all draw the same control, and two of the three
/// screens had been using an ✕ and a sparkle for want of a minus and a plus
/// in the icon set. The glyph is text, as the goal sheet always had it.
class StepperButton extends StatelessWidget {
  const StepperButton({
    super.key,
    required this.label,
    required this.onTap,
    this.tooltip,
    this.size = 52,
  });

  final String label;
  final VoidCallback? onTap;
  final String? tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final button = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(HazriRadius.chip),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: c.card2,
          borderRadius: BorderRadius.circular(HazriRadius.chip),
        ),
        child: Center(
          child: Text(
            label,
            style: HazriText.display22.copyWith(
              color: onTap == null ? c.muted : c.ink,
            ),
          ),
        ),
      ),
    );
    return tooltip == null
        ? Semantics(button: true, child: button)
        : Tooltip(message: tooltip!, child: button);
  }
}
