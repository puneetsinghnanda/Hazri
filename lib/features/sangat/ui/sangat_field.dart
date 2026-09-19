import 'package:flutter/material.dart';

import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';

/// One labelled box on a sangat form (designs 32 and 34).
///
/// Shared rather than copied because the two screens ask for the same thing —
/// an email address — and a person who corrects theirs on screen 34 should
/// not feel they have moved to a different app.
class SangatField extends StatelessWidget {
  const SangatField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.placeholder,
    this.optionalLabel,
    this.keyboardType,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final TextEditingController controller;

  /// The explanation under the box — why the app is asking at all.
  final String? hint;
  final String? placeholder;
  final String? optionalLabel;
  final TextInputType? keyboardType;
  final bool autofocus;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Flexible, not bare: "Paste the link from the email" is already
            // at the edge in English and longer in Punjabi, and a bare Text
            // beside the optional marker overflows rather than wrapping.
            Flexible(
              child: Text(label,
                  style: HazriText.captionStrong.copyWith(color: c.ink2)),
            ),
            if (optionalLabel != null) ...[
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  optionalLabel!,
                  style: HazriText.caption.copyWith(color: c.muted),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          autofocus: autofocus,
          textCapitalization: textCapitalization,
          style: HazriText.body.copyWith(color: c.ink),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: HazriText.body.copyWith(color: c.muted),
            filled: true,
            fillColor: c.card,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: c.rule),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: c.kesri, width: 1.5),
            ),
          ),
        ),
        if (hint != null) ...[
          const SizedBox(height: 5),
          Text(hint!, style: HazriText.caption.copyWith(color: c.muted)),
        ],
      ],
    );
  }
}
