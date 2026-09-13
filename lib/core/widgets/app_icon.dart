import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/hazri_text.dart';

/// Renders one icon from `HazriIconData`.
///
/// The design's icons are 24 dp outlines with a 1.8 stroke; the constants hold
/// only the inner markup, so the `<svg>` root that carries those defaults is
/// added here.
class AppIcon extends StatelessWidget {
  const AppIcon(this.data, {super.key, this.size = 22, this.color, this.semanticLabel});

  final String data;
  final double size;
  final Color? color;
  final String? semanticLabel;

  static String _wrap(String inner) =>
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" '
      'stroke="currentColor" stroke-width="1.8" stroke-linecap="round" '
      'stroke-linejoin="round">$inner</svg>';

  @override
  Widget build(BuildContext context) {
    final tint = color ?? IconTheme.of(context).color ?? Theme.of(context).colorScheme.onSurface;
    return SvgPicture.string(
      _wrap(data),
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
      semanticsLabel: semanticLabel,
    );
  }
}

/// A skip icon with its seconds count drawn in the middle.
///
/// The design draws the "10" as SVG `<text>`, which flutter_svg does not
/// render, so the numeral is a real text layer on top of the arc.
class SeekIcon extends StatelessWidget {
  const SeekIcon(this.data, {super.key, this.seconds = 10, this.size = 26, this.color});

  final String data;
  final int seconds;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? IconTheme.of(context).color ?? Theme.of(context).colorScheme.onSurface;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AppIcon(data, size: size, color: tint),
          Padding(
            padding: EdgeInsets.only(top: size * 0.10),
            child: Text(
              '$seconds',
              style: TextStyle(
                fontFamily: HazriFonts.ui,
                fontSize: size * 0.30,
                fontWeight: FontWeight.w700,
                color: tint,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
