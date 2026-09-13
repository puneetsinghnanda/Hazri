import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/settings_controller.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';

/// The ਪੰ / हि / En switch. Changing it re-renders the screen immediately,
/// with no restart (PRD 1.1).
class LanguagePill extends ConsumerWidget {
  const LanguagePill({super.key});

  static const _options = [
    ('pa', 'ਪੰ', 17.0),
    ('hi', 'हि', 17.0),
    ('en', 'En', 14.0),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final current = ref.watch(settingsProvider).locale.languageCode;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.card2,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (code, label, size) in _options)
            Semantics(
              button: true,
              selected: current == code,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => ref.read(settingsProvider.notifier).setLocale(Locale(code)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 32),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: current == code ? c.card : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: current == code ? c.shadows : null,
                  ),
                  child: Center(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontFamily: HazriFonts.display,
                        fontSize: size,
                        fontWeight: FontWeight.w700,
                        color: current == code ? c.ink : c.muted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
