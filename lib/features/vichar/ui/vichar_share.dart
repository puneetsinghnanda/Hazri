import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/db/content_repository.dart';
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
      // The card is laid out 360 wide, so 3x gives 1080 x 1350.
      final image = await object.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return;

      final file = await writeShareImage(
        await getTemporaryDirectory(),
        bytes.buffer.asUint8List(),
        DateTime.now(),
      );

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
              maxHeight: 450,
              alignment: Alignment.topLeft,
              child: RepaintBoundary(
                key: _boundary,
                child: VicharShareCard(
                  vichar: widget.vichar,
                  language: language,
                  l: l,
                  ikOnkar: ref.watch(ikOnkarProvider).value ?? '',
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Writes the card under a name of its own and removes the earlier ones.
///
/// It was always `vichar.png`, and Android's share sheet keeps the preview it
/// made for a name: a phone that had shared the first, dark card went on
/// previewing that one while the cream card went out (2026-10-10). A new
/// name every time means the preview is drawn from the file being sent.
Future<File> writeShareImage(Directory dir, List<int> png, DateTime now) async {
  for (final old in dir.listSync().whereType<File>()) {
    final name = old.uri.pathSegments.last;
    if (name.startsWith('vichar') && name.endsWith('.png')) {
      try {
        old.deleteSync();
      } on FileSystemException {
        // Still open in another app; the next share tries again.
      }
    }
  }
  return File.fromUri(Uri.file('${dir.path}/vichar-${now.millisecondsSinceEpoch}.png'))
      .writeAsBytes(png, flush: true);
}

/// The picture that goes out, laid out at 360 x 450 and rendered at 3x.
///
/// A saroop folio: warm paper, a double rule set in from the edge the way a
/// page carries a margin, and ੴ resting in the corner. Its own palette rather
/// than the app theme, so the sender's theme does not decide what the
/// recipient sees — and a light card in a feed of dark ones gets looked at.
class VicharShareCard extends StatelessWidget {
  const VicharShareCard({
    super.key,
    required this.vichar,
    required this.language,
    required this.l,
    this.ikOnkar = '',
  });

  final Vichar vichar;
  final String language;
  final L l;

  /// ੴ, from content.db. Empty simply leaves the watermark off.
  final String ikOnkar;

  static const _paper = Color(0xFFF7F1E4);
  static const _ink = Color(0xFF2A2418);
  static const _muted = Color(0xFF6B6152);
  static const _kesri = Color(0xFF9A4F00);

  @override
  Widget build(BuildContext context) {
    final meaning = vichar.meaningIn(language);
    return Container(
      width: 360,
      height: 450,
      color: _paper,
      child: Stack(
        children: [
          // The watermark sits under the rule, bled off the corner.
          if (ikOnkar.isNotEmpty)
            Positioned(
              right: -22,
              bottom: -38,
              child: Text(
                ikOnkar,
                style: HazriText.gurmukhi(150).copyWith(
                  color: _kesri.withValues(alpha: 0.07),
                  height: 1,
                ),
              ),
            ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(11),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: _kesri.withValues(alpha: 0.30)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: _kesri.withValues(alpha: 0.16)),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(30, 34, 30, 26),
            child: Column(
              children: [
                Text(
                  l.vicharNative,
                  style: HazriText.gurmukhi(11).copyWith(
                    color: _kesri,
                    letterSpacing: 1.6,
                  ),
                ),
                const Spacer(),
                Text(
                  vichar.gurmukhi,
                  textAlign: TextAlign.center,
                  style: HazriText.gurmukhi(19).copyWith(color: _ink, height: 1.85),
                ),
                const SizedBox(height: 15),
                Container(width: 46, height: 1, color: _kesri.withValues(alpha: 0.5)),
                const SizedBox(height: 15),
                Text(
                  meaning,
                  textAlign: TextAlign.center,
                  style: HazriText.body.copyWith(
                    fontSize: 13,
                    color: _muted,
                    height: 1.5,
                  ),
                ),
                const Spacer(),
                Text(
                  l.vicharSource,
                  textAlign: TextAlign.center,
                  style: HazriText.caption.copyWith(fontSize: 10.5, color: _muted),
                ),
                const SizedBox(height: 7),
                Text(
                  l.shareCardFooter,
                  style: HazriText.caption.copyWith(
                    fontSize: 10.5,
                    color: _kesri,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
