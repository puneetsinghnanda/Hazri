import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/widgets/surfaces.dart';

/// The standard pushed screen: a back button, a title, and a scrolling body
/// held to phone width.
class HazriScreen extends StatelessWidget {
  const HazriScreen({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.actions = const [],
    this.footer,
    this.padding = const EdgeInsets.fromLTRB(
      HazriSize.gutter,
      8,
      HazriSize.gutter,
      24,
    ),
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final List<Widget> actions;
  final Widget? footer;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: PhoneWidth(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(HazriSize.gutter, 8, HazriSize.gutter, 4),
                child: Row(
                  children: [
                    CardIconButton(
                      icon: HazriIconData.chevronLeft,
                      tooltip: L.of(context).actionBack,
                      onPressed: () =>
                          context.canPop() ? context.pop() : context.go(Routes.today),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: HazriText.display22.copyWith(color: c.ink),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (subtitle != null)
                            Text(
                              subtitle!,
                              style: HazriText.caption.copyWith(color: c.muted),
                            ),
                        ],
                      ),
                    ),
                    ...actions,
                  ],
                ),
              ),
              Expanded(
                child: ListView(padding: padding, children: children),
              ),
              if (footer != null) footer!,
            ],
          ),
        ),
      ),
    );
  }
}

/// A titled group of rows, as used throughout Settings and About.
class SettingsSection extends StatelessWidget {
  const SettingsSection({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
          child: Eyebrow(title),
        ),
        HazriCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1)
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Divider(height: 1, color: c.rule),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// One row inside a [SettingsSection].
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.title,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
    this.leadingIcon,
    this.danger = false,
  });

  final String title;
  final String? subtitle;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String? leadingIcon;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: HazriText.bodyStrong.copyWith(color: danger ? c.kesriInk : c.ink),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle!,
                        style: HazriText.bodySmall.copyWith(color: c.muted),
                      ),
                    ),
                ],
              ),
            ),
            if (value != null)
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  value!,
                  style: HazriText.chip.copyWith(color: c.ink2),
                ),
              ),
            if (trailing != null) Padding(padding: const EdgeInsets.only(left: 8), child: trailing!),
          ],
        ),
      ),
    );
  }
}
