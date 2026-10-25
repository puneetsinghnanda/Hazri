import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/widgets/app_mark.dart';
import '../domain/saakhi.dart';
import 'saakhi_reader_screen.dart' show SaakhiColors;

/// Where Share's link leads (13-saakhi.md SK-4): the website today.
const kSaakhiShareSite = 'hazri.me';

/// SK10: a picture of this page (or the cover, for the whole saakhi) with the
/// Hazri band, sent through Android's share sheet. The app itself sends
/// nothing (PRD §8).
Future<void> showSaakhiShareSheet(
  BuildContext context, {
  required Saakhi saakhi,
  required int page,
  required String language,
}) => showModalBottomSheet<void>(
  context: context,
  useSafeArea: true,
  isScrollControlled: true,
  backgroundColor: const Color(0xFF161A37),
  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
  builder: (_) => _ShareSheet(saakhi: saakhi, page: page, language: language),
);

/// The plain message that goes with the picture.
String saakhiShareMessage(L l, Saakhi s, String language) =>
    l.saakhiShareMessage(s.title.of(language), s.blurb.of(language), 'https://$kSaakhiShareSite');

class _ShareSheet extends StatefulWidget {
  const _ShareSheet({required this.saakhi, required this.page, required this.language});

  final Saakhi saakhi;
  final int page;
  final String language;

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  final _boundary = GlobalKey();
  late bool _whole = widget.page == 0 || widget.page > widget.saakhi.pages.length;
  bool _busy = false;
  String _message = '';

  /// The lesson shares the whole saakhi: it is the saakhi's last word.
  int? get _storyPage => _whole ? null : widget.page;

  Future<void> _shareImage() async {
    setState(() => _busy = true);
    try {
      final card = SaakhiShareCard(
        saakhi: widget.saakhi,
        page: _storyPage,
        language: widget.language,
        l: L.of(context),
      );
      await precacheImage(AssetImage(card.image), context);
      await WidgetsBinding.instance.endOfFrame;
      final object = _boundary.currentContext?.findRenderObject();
      if (object is! RenderRepaintBoundary) return;
      // Laid out 360 x 640, so 3x is 1080 x 1920.
      final image = await object.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return;
      final dir = await getTemporaryDirectory();
      for (final old in dir.listSync().whereType<File>()) {
        if (old.uri.pathSegments.last.startsWith('hazri-saakhi-')) {
          try {
            old.deleteSync();
          } on FileSystemException {
            // Still open in another app; the next share tries again.
          }
        }
      }
      final name =
          'hazri-saakhi-${widget.saakhi.id}${_storyPage == null ? '' : '-page-$_storyPage'}'
          '-${DateTime.now().millisecondsSinceEpoch}.png';
      final file = await File('${dir.path}/$name').writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      if (!mounted) return;
      await Share.shareXFiles([
        XFile(file.path),
      ], text: saakhiShareMessage(L.of(context), widget.saakhi, widget.language));
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copy() async {
    final l = L.of(context);
    await Clipboard.setData(ClipboardData(text: saakhiShareMessage(l, widget.saakhi, widget.language)));
    if (mounted) setState(() => _message = l.saakhiCopied);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final onStory = widget.page > 0 && widget.page <= widget.saakhi.pages.length;
    final card = SaakhiShareCard(saakhi: widget.saakhi, page: _storyPage, language: widget.language, l: l);
    Widget option(String label, bool on, VoidCallback onTap) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: ChoiceChip(
        label: Text(label),
        selected: on,
        onSelected: (_) => onTap(),
        labelStyle: HazriText.captionStrong.copyWith(color: on ? SaakhiColors.night : Colors.white),
        selectedColor: Colors.white,
        backgroundColor: Colors.transparent,
        side: BorderSide(color: Colors.white.withValues(alpha: on ? 1 : 0.2), width: 1.5),
        showCheckmark: false,
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(l.saakhiShareTitle, style: HazriText.display22.copyWith(color: const Color(0xFFEDECF6), fontSize: 19)),
          const SizedBox(height: 12),
          // The preview is the card itself, scaled down; the same boundary is
          // what becomes the picture.
          SizedBox(
            width: 170,
            height: 170 * 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: FittedBox(
                fit: BoxFit.contain,
                child: RepaintBoundary(key: _boundary, child: card),
              ),
            ),
          ),
          if (onStory) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                option(l.saakhiShareThisPage, !_whole, () => setState(() => _whole = false)),
                option(l.saakhiShareWhole, _whole, () => setState(() => _whole = true)),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: FilledButton.icon(
                  onPressed: _busy ? null : _shareImage,
                  icon: const Icon(Icons.share_outlined, size: 20),
                  label: Text(l.saakhiShareImage),
                  style: FilledButton.styleFrom(
                    backgroundColor: SaakhiColors.gold,
                    foregroundColor: SaakhiColors.onGold,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    textStyle: HazriText.bodyStrong.copyWith(fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _copy,
                  icon: const Icon(Icons.copy_rounded, size: 20),
                  label: Text(l.saakhiCopyText),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    textStyle: HazriText.bodyStrong.copyWith(fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: 26,
            child: Center(
              child: Text(_message, style: HazriText.caption.copyWith(color: Colors.white.withValues(alpha: 0.6))),
            ),
          ),
        ],
      ),
    );
  }
}

/// The picture that goes out, laid out at 360 x 640 and rendered at 3x: the
/// page's image, the saakhi's name, the page's words, and the band saying
/// where to read and listen to the rest (SK10).
class SaakhiShareCard extends StatelessWidget {
  const SaakhiShareCard({super.key, required this.saakhi, required this.page, required this.language, required this.l});

  final Saakhi saakhi;

  /// The story page to share, or null for the whole saakhi (the cover).
  final int? page;
  final String language;
  final L l;

  String get image => page == null ? saakhi.cover : saakhi.pages[page! - 1].image;

  @override
  Widget build(BuildContext context) {
    final pa = language == 'pa';
    final p = page == null ? null : saakhi.pages[page! - 1];
    final eyebrow = p == null
        ? l.saakhiShareEyebrow
        : '${l.saakhiPageOf(page!, saakhi.lessonPage)} · ${p.title.of(language)}';
    final words = p == null ? saakhi.blurb.of(language) : saakhiPlain(p.text.of(language));
    const night = SaakhiColors.night;
    return SizedBox(
      width: 360,
      height: 640,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(image, fit: BoxFit.cover, alignment: const Alignment(0, -0.2)),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0, 0.16, 0.42, 0.6, 1],
                colors: [
                  night.withValues(alpha: 0.55),
                  night.withValues(alpha: 0),
                  night.withValues(alpha: 0),
                  night.withValues(alpha: 0.82),
                  night.withValues(alpha: 0.98),
                ],
              ),
            ),
          ),
          if (p != null || !saakhi.coverTitleInImage)
            Positioned(
              left: 24,
              right: 24,
              top: 22,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    saakhi.title.of('pa'),
                    style: HazriText.display22.copyWith(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    saakhi.title.of('en'),
                    style: HazriText.display22.copyWith(color: Colors.white, fontSize: 18, height: 1.15),
                  ),
                ],
              ),
            ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pa ? eyebrow : eyebrow.toUpperCase(),
                  style: HazriText.captionStrong.copyWith(
                    color: SaakhiColors.goldInk,
                    fontSize: pa ? 12 : 10.5,
                    letterSpacing: pa ? 0 : 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  words,
                  maxLines: 9,
                  overflow: TextOverflow.ellipsis,
                  style: HazriText.body.copyWith(
                    color: Colors.white,
                    fontSize: pa ? 16.5 : 16,
                    height: pa ? 1.55 : 1.45,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 18,
            child: Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: SaakhiColors.gold, borderRadius: BorderRadius.circular(10)),
                    child: const AppMark(size: 28, arcColor: SaakhiColors.onGold, sunColor: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.saakhiShareBandTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: HazriText.bodyStrong.copyWith(color: Colors.white, fontSize: 13.5),
                        ),
                        Text(
                          l.saakhiShareBandSub(kSaakhiShareSite),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: HazriText.captionStrong.copyWith(color: SaakhiColors.goldInk, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
