import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/time/date_format.dart';
import '../../../core/widgets/app_mark.dart';
import '../../../core/widgets/surfaces.dart';
import '../domain/hukamnama.dart';

/// Preview and share the 1080 x 1920 Hukamnama card (Design 25).
Future<void> showShareCardPreview(BuildContext context, Hukamnama hukamnama) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _SharePreview(hukamnama: hukamnama),
    );

class _SharePreview extends ConsumerStatefulWidget {
  const _SharePreview({required this.hukamnama});

  final Hukamnama hukamnama;

  @override
  ConsumerState<_SharePreview> createState() => _SharePreviewState();
}

class _SharePreviewState extends ConsumerState<_SharePreview> {
  final _boundary = GlobalKey();
  bool _sharing = false;

  /// Renders the card offscreen at 1080 x 1920 and hands it to the system
  /// share sheet.
  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      final object = _boundary.currentContext?.findRenderObject();
      if (object is! RenderRepaintBoundary) return;

      // The card is laid out 360 wide, so 3x gives the 1080 x 1920 the design
      // asks for.
      final image = await object.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return;

      final dir = await getTemporaryDirectory();
      final file = await File.fromUri(
        Uri.file('${dir.path}/hukamnama.png'),
      ).writeAsBytes(bytes.buffer.asUint8List(), flush: true);

      if (!mounted) return;
      await Share.shareXFiles([XFile(file.path)], subject: L.of(context).shareCardTitle);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(HazriSize.gutter, 12, HazriSize.gutter, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: c.rule,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(l.shareCardPreview, style: HazriText.display22.copyWith(color: c.ink)),
            const SizedBox(height: 16),
            FittedBox(
              child: RepaintBoundary(
                key: _boundary,
                child: HukamnamaShareCard(
                  hukamnama: widget.hukamnama,
                  settings: ref.watch(settingsProvider),
                  locale: Localizations.localeOf(context).languageCode,
                  l: l,
                  dates: HazriDates.of(context),
                ),
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: _sharing ? l.shareCardShare : l.shareCardShare,
              onPressed: _sharing ? null : _share,
            ),
          ],
        ),
      ),
    );
  }
}

/// The card itself, laid out at 360 x 640 and rendered at 3x.
class HukamnamaShareCard extends StatelessWidget {
  const HukamnamaShareCard({
    super.key,
    required this.hukamnama,
    required this.settings,
    required this.locale,
    required this.l,
    required this.dates,
  });

  final Hukamnama hukamnama;
  final AppSettings settings;
  final String locale;
  final L l;
  final HazriDates dates;

  /// Two lines, or up to and including the Rahao line — whichever comes first —
  /// so the card never overflows (PRD 1.11 AC).
  List<HukamnamaLine> get _lines {
    final out = <HukamnamaLine>[];
    for (final line in hukamnama.lines) {
      out.add(line);
      if (line.isRahao || out.length >= 2) break;
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    const dark = HazriColors.dark;
    final truncated = _lines.length < hukamnama.lines.length;

    final meanings = [
      for (final line in _lines)
        if (line.meanings[settings.meaningsLang] != null) line.meanings[settings.meaningsLang]!,
    ].join(' ');

    return Container(
      width: 360,
      height: 640,
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
      decoration: BoxDecoration(
        color: dark.bg,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [dark.bg, dark.card],
        ),
      ),
      child: DefaultTextStyle(
        style: HazriText.body.copyWith(color: dark.ink),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const AppMark(size: 26, arcColor: Color(0xFFF3EFE6), sunColor: Color(0xFFF2A24E)),
                const SizedBox(width: 8),
                Text(
                  l.appName,
                  style: HazriText.brand.copyWith(fontSize: 16, color: dark.ink),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              l.shareCardTitle,
              style: HazriText.display22.copyWith(fontSize: 20, color: dark.kesri),
            ),
            const SizedBox(height: 4),
            Text(
              '${dates.longDate(hukamnama.date)} · ${l.hukamnamaSource}',
              style: HazriText.caption.copyWith(color: dark.muted),
            ),
            const SizedBox(height: 22),
            for (final line in _lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  line.gurmukhi,
                  style: HazriText.gurmukhi(18).copyWith(color: dark.ink, height: 1.7),
                ),
              ),
            if (_lines.isNotEmpty && _lines.first.devanagari.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                _lines.first.devanagari,
                style: HazriText.devanagari(14).copyWith(color: dark.ink2, height: 1.6),
              ),
            ],
            const SizedBox(height: 16),
            if (meanings.isNotEmpty)
              Expanded(
                child: Text(
                  truncated ? '$meanings ${l.shareCardTruncated}' : meanings,
                  style: HazriText.bodySmall.copyWith(color: dark.ink2, height: 1.5),
                ),
              )
            else
              const Spacer(),
            Text(
              [
                if (hukamnama.ang != null) 'Ang ${hukamnama.ang}',
                if (hukamnama.raag != null) hukamnama.raag!,
                if (hukamnama.writer != null) hukamnama.writer!,
              ].join(' · '),
              style: HazriText.captionStrong.copyWith(color: dark.kesriInk),
            ),
            const SizedBox(height: 14),
            Divider(color: dark.rule, height: 1),
            const SizedBox(height: 12),
            Text(
              l.shareCardFooter,
              style: HazriText.caption.copyWith(color: dark.muted),
            ),
          ],
        ),
      ),
    );
  }
}
