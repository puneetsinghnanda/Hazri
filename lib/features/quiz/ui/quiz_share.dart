import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/backend/backend.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/widgets/app_mark.dart';
import '../domain/quiz.dart';
import 'quiz_widgets.dart';

/// The link a shared quiz carries (QZ24, QZ25): it opens that topic's quiz.
String quizLink(String topicId) => '$kSiteBase/q/$topicId';

/// QZ24: a 1080 x 1920 picture of the score and the challenge, with the
/// Hazri band and the link, sent through Android's share sheet. The app
/// itself sends nothing (PRD §8).
Future<void> showQuizShareSheet(
  BuildContext context, {
  required QuizTopic topic,
  required int score,
  required String language,
}) => showModalBottomSheet<void>(
  context: context,
  useSafeArea: true,
  isScrollControlled: true,
  backgroundColor: _night,
  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
  builder: (_) => _ShareSheet(topic: topic, score: score, language: language),
);

const _night = Color(0xFF161A37);
const _gold = Color(0xFFF2A24E);

class _ShareSheet extends StatefulWidget {
  const _ShareSheet({required this.topic, required this.score, required this.language});

  final QuizTopic topic;
  final int score;
  final String language;

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  final _boundary = GlobalKey();
  bool _busy = false;
  String _message = '';

  String _text(L l) => l.quizShareMessage(widget.score, widget.topic.name(widget.language), quizLink(widget.topic.id));

  Future<void> _shareImage() async {
    setState(() => _busy = true);
    final text = _text(L.of(context));
    try {
      await WidgetsBinding.instance.endOfFrame;
      final object = _boundary.currentContext?.findRenderObject();
      if (object is! RenderRepaintBoundary) return;
      // Laid out 360 x 640, so 3x is 1080 x 1920.
      final image = await object.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return;
      final dir = await getTemporaryDirectory();
      for (final old in dir.listSync().whereType<File>()) {
        if (old.uri.pathSegments.last.startsWith('hazri-quiz-')) {
          try {
            old.deleteSync();
          } on FileSystemException {
            // Still open in another app; the next share tries again.
          }
        }
      }
      final file = await File(
        '${dir.path}/hazri-quiz-${widget.topic.id}-${DateTime.now().millisecondsSinceEpoch}.png',
      ).writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      await Share.shareXFiles([XFile(file.path)], text: text);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copy() async {
    final l = L.of(context);
    await Clipboard.setData(ClipboardData(text: _text(l)));
    if (mounted) setState(() => _message = l.saakhiCopied);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final card = QuizShareCard(topic: widget.topic, score: widget.score, language: widget.language, l: l);
    ButtonStyle style(Color bg, Color fg) => FilledButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: fg,
      minimumSize: const Size.fromHeight(52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: HazriText.bodyStrong.copyWith(fontSize: 14),
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
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(2)),
          ),
          Text(l.quizShareButton, style: HazriText.display22.copyWith(color: const Color(0xFFEDECF6), fontSize: 19)),
          const SizedBox(height: 12),
          SizedBox(
            width: 170,
            height: 170 * 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: FittedBox(fit: BoxFit.contain, child: RepaintBoundary(key: _boundary, child: card)),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: FilledButton.icon(
                  onPressed: _busy ? null : _shareImage,
                  icon: const Icon(Icons.share_outlined, size: 20),
                  label: Text(l.saakhiShareImage),
                  style: style(_gold, const Color(0xFF1C1206)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _copy,
                  icon: const Icon(Icons.copy_rounded, size: 20),
                  label: Text(l.saakhiCopyText),
                  style: style(Colors.white.withValues(alpha: 0.08), Colors.white),
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

/// The picture, laid out at 360 x 640: the topic's drawing and name, the
/// score, the challenge, and the band saying where to take the same quiz.
class QuizShareCard extends StatelessWidget {
  const QuizShareCard({super.key, required this.topic, required this.score, required this.language, required this.l});

  final QuizTopic topic;
  final int score;
  final String language;
  final L l;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 360,
      height: 640,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1E48), Color(0xFF3A3577), Color(0xFFC9773A)],
            stops: [0, 0.6, 1],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 40, 26, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.quizTitle.toUpperCase(),
                style: HazriText.captionStrong.copyWith(color: _gold, fontSize: 12, letterSpacing: 1.4),
              ),
              const SizedBox(height: 26),
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(color: const Color(0xFFFFF4E4), borderRadius: BorderRadius.circular(26)),
                alignment: Alignment.center,
                child: topic.drawn
                    ? QuizCategoryDrawing(topic.glyph, size: 70)
                    : QuizCategoryDrawing(topic.category.name, size: 70),
              ),
              const SizedBox(height: 18),
              Text(
                topic.name(language),
                style: HazriText.display26.copyWith(color: Colors.white, fontSize: 28, height: 1.15),
              ),
              const Spacer(),
              Text(
                l.quizShareYourScore(score),
                style: HazriText.display44.copyWith(color: Colors.white, fontSize: 52, height: 1),
              ),
              const SizedBox(height: 12),
              Text(
                l.quizShareChallenge(score),
                style: HazriText.display22.copyWith(color: Colors.white, fontSize: 22, height: 1.25),
              ),
              const SizedBox(height: 28),
              Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: _gold, borderRadius: BorderRadius.circular(10)),
                      child: const AppMark(size: 28, arcColor: Color(0xFF1C1206), sunColor: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.quizShareBand,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: HazriText.bodyStrong.copyWith(color: Colors.white, fontSize: 13),
                          ),
                          Text(
                            quizLink(topic.id).replaceFirst('https://', ''),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: HazriText.captionStrong.copyWith(color: _gold, fontSize: 11.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
