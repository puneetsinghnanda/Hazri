import 'package:flutter/material.dart';

import '../theme/hazri_colors.dart';
import '../theme/hazri_text.dart';
import 'app_icon.dart';

/// The standard card: 20 dp radius with the token shadow in light and a
/// hairline in dark.
class HazriCard extends StatelessWidget {
  const HazriCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.colour,
    this.gradient,
    this.border,
    this.radius = HazriRadius.card,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? colour;

  /// Painted over [colour] when given (the Nitnem slots, design 2A).
  final Gradient? gradient;
  final BoxBorder? border;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final shape = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colour ?? c.card,
        gradient: gradient,
        borderRadius: shape,
        boxShadow: c.shadows,
        border: border,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: shape,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// A fully rounded chip. Pass [onTap] to make it a button.
class HazriChip extends StatelessWidget {
  const HazriChip({
    super.key,
    required this.label,
    this.icon,
    this.background,
    this.foreground,
    this.onTap,
    this.minHeight = 34,
    this.trailing,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  });

  final String label;
  final String? icon;
  final Color? background;
  final Color? foreground;
  final VoidCallback? onTap;
  final double minHeight;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = foreground ?? c.ink2;
    final body = ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Padding(
        padding: padding,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[AppIcon(icon!, size: 16, color: fg), const SizedBox(width: 6)],
            Flexible(
              child: Text(
                label,
                style: HazriText.chip.copyWith(color: fg),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 6), trailing!],
          ],
        ),
      ),
    );
    final shape = BorderRadius.circular(HazriRadius.chip);
    return DecoratedBox(
      decoration: BoxDecoration(color: background ?? c.card2, borderRadius: shape),
      child: onTap == null
          ? body
          : Material(
              type: MaterialType.transparency,
              child: InkWell(onTap: onTap, borderRadius: shape, child: body),
            ),
    );
  }
}

/// The full-width primary action, 52 dp min height and 16 dp radius.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailing,
    this.secondary = false,
    this.minHeight,
    this.expanded = true,
    this.background,
    this.foreground,
  });

  final String label;
  final VoidCallback? onPressed;
  final String? icon;
  final String? trailing;
  final bool secondary;
  final double? minHeight;
  final bool expanded;

  /// Colours for a button that is not on a themed surface.
  ///
  /// The Simran screen is a night sky whatever the theme, so its buttons took
  /// the light theme's indigo primary and looked like they belonged to a
  /// different app.
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bg = background ?? (secondary ? c.card2 : c.primary);
    final fg = foreground ?? (secondary ? c.ink : c.onPrimary);
    final shape = BorderRadius.circular(HazriRadius.button);
    final height = minHeight ?? HazriSize.buttonMinHeight;

    return Opacity(
      opacity: onPressed == null ? 0.55 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(color: bg, borderRadius: shape),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onPressed,
            borderRadius: shape,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: height),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
                  mainAxisAlignment: trailing == null ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[AppIcon(icon!, size: 22, color: fg), const SizedBox(width: 10)],
                          Flexible(
                            child: Text(
                              label,
                              style: HazriText.button.copyWith(color: fg),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (trailing != null)
                      Text(
                        trailing!,
                        style: HazriText.bodySmall.copyWith(
                          color: fg.withValues(alpha: 0.75),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A square icon button on a card surface, 12 dp radius.
class CardIconButton extends StatelessWidget {
  const CardIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 44,
    this.iconSize = 22,
    this.background,
    this.foreground,
    this.radius = 14,
    this.child,
  });

  final String icon;

  /// Drawn instead of [icon]: a Material icon the app's set does not have.
  final Widget? child;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final double iconSize;
  final Color? background;
  final Color? foreground;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final shape = BorderRadius.circular(radius);
    final button = DecoratedBox(
      decoration: BoxDecoration(
        color: background ?? c.card,
        borderRadius: shape,
        boxShadow: background == null ? c.shadows : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onPressed,
          borderRadius: shape,
          child: SizedBox.square(
            dimension: size,
            child: Center(
              child: child ?? AppIcon(icon, size: iconSize, color: foreground ?? c.ink),
            ),
          ),
        ),
      ),
    );
    return tooltip == null ? Semantics(button: true, child: button) : Tooltip(message: tooltip!, child: button);
  }
}

/// A small uppercase label above a group of rows.
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.colour});

  final String text;
  final Color? colour;

  @override
  Widget build(BuildContext context) =>
      Text(text.toUpperCase(), style: HazriText.eyebrow.copyWith(color: colour ?? context.colors.muted));
}

/// Keeps content to a phone-width column on tablets (PRD §4.1).
class PhoneWidth extends StatelessWidget {
  const PhoneWidth({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: HazriSize.maxContentWidth),
      child: child,
    ),
  );
}
