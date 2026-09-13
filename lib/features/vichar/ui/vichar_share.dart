import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/surfaces.dart';
import '../domain/vichar.dart';

/// Asks whether to send the Vichar as words or as a picture, then sends it.
///
/// Both, because they travel differently: text can be replied to and quoted in
/// a family group, while an image is what goes on a WhatsApp status.
Future<void> showVicharShareSheet(BuildContext context, Vichar vichar) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(HazriSize.gutter, 20, HazriSize.gutter, 24),
      child: _ShareChoices(vichar: vichar),
    ),
  );
}

class _ShareChoices extends ConsumerStatefulWidget {
  const _ShareChoices({required this.vichar});

  final Vichar vichar;

  @override
  ConsumerState<_ShareChoices> createState() => _ShareChoicesState();
}

class _ShareChoicesState extends ConsumerState<_ShareChoices> {
  final _boundary = GlobalKey();
  bool _busy = false;

  /// The plain-text form: the line, its meaning, and where it is from.
  String _asText(L l, String language) {
    final v = widget.vichar;
    final buffer = StringBuffer()
      ..writeln(v.gurmukhi)
      ..writeln()
      ..writeln(v.meaningIn(language));
    if (language != 'en' && v.hasEnglish) buffer.writeln(v.meaningEn);
    buffer
      ..writeln()
      ..writeln('— ${l.vicharSource}')
      ..write(l.shareCardFooter);
    return buffer.toString();
  }

  Future<void> _shareText() async {
    final l = L.of(context);
    final language = Localizations.localeOf(context).languageCode;
    await Share.share(_asText(l, language), subject: l.shareCardTitle);
    if (mounted) Navigator.of(context).pop();
  }

  /// Renders the card offscreen at 1080 x 1920 and hands it to the system
  /// share sheet.
  Future<void> _shareImage() async {
    setState(() => _busy = true);
    try {
      final object = _boundary.currentContext?.findRenderObject();
      if (object is! RenderRepaintBoundary) return;
      // The card is laid out 360 wide, so 3x gives 1080 x 1920.
      final image = await object.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return;

      final dir = await getTemporaryDirectory();
      final file = await File.fromUri(Uri.file('${dir.path}/vichar.png'))
          .writeAsBytes(bytes.buffer.asUint8List(), flush: true);

      if (!mounted) return;
      await Share.shareXFiles([XFile(file.path)],
          subject: L.of(context).shareCardTitle);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    final language = Localizations.localeOf(context).languageCode;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIcon(HazriIconData.share, size: 26, color: c.kesriInk),
        const SizedBox(height: 12),
        Text(l.vicharShareTitle,
            textAlign: TextAlign.center,
            style: HazriText.display22.copyWith(color: c.ink)),
        const SizedBox(height: 4),
        Text(l.vicharShareBody,
            textAlign: TextAlign.center,
            style: HazriText.body.copyWith(color: c.ink2)),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: PrimaryButton(
                label: l.vicharShareAsText,
                secondary: true,
                onPressed: _busy ? null : _shareText,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PrimaryButton(
                label: l.vicharShareAsImage,
                onPressed: _busy ? null : _shareImage,
              ),
            ),
          ],
        ),
        // Laid out but never shown: the boundary has to be in the tree for
        // toImage to have anything to rasterise.
        SizedBox(
          height: 0,
          child: ClipRect(
            child: OverflowBox(
              maxWidth: 360,
              maxHeight: 640,
              alignment: Alignment.topLeft,
              child: RepaintBoundary(
                key: _boundary,
                child: VicharShareCard(
                  vichar: widget.vichar,
                  language: language,
                  l: l,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The picture that goes out, laid out at 360 x 640 and rendered at 3x.
///
/// Deliberately its own palette rather than the app's theme: it has to read on
/// a WhatsApp status behind whatever else is on the screen, in either theme.
class VicharShareCard extends StatelessWidget {
  const VicharShareCard({
    super.key,
    required this.vichar,
    required this.language,
    required this.l,
  });

  final Vichar vichar;
  final String language;
  final L l;

  static const _ground = Color(0xFF0C0F24);
  static const _ink = Color(0xFFF6F1E7);
  static const _muted = Color(0xFF9EA3C2);
  static const _kesri = Color(0xFFF2A24E);

  @override
  Widget build(BuildContext context) {
    final meaning = vichar.meaningIn(language);
    return Container(
      width: 360,
      height: 640,
      color: _ground,
      padding: const EdgeInsets.fromLTRB(30, 44, 30, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            l.vicharNative,
            style: HazriText.caption.copyWith(
              color: _kesri,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const Spacer(),
          Text(
            vichar.gurmukhi,
            textAlign: TextAlign.center,
            style: HazriText.gurmukhi(24).copyWith(color: _ink, height: 1.75),
          ),
          const SizedBox(height: 22),
          Container(width: 56, height: 1, color: _kesri.withValues(alpha: 0.55)),
          const SizedBox(height: 22),
          Text(
            meaning,
            textAlign: TextAlign.center,
            style: HazriText.body.copyWith(color: _muted, height: 1.55),
          ),
          const Spacer(),
          Text(
            l.vicharSource,
            textAlign: TextAlign.center,
            style: HazriText.caption.copyWith(color: _muted),
          ),
          const SizedBox(height: 10),
          Text(
            l.shareCardFooter,
            style: HazriText.caption.copyWith(
              color: _kesri.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
