import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/time/date_format.dart';
import '../../../core/widgets/surfaces.dart';
import '../../audio/data/notification_access.dart';
import '../../profile/data/profile_controller.dart';
import '../../settings/ui/screen_scaffold.dart';
import '../data/announcement_api.dart';

/// What a tapped announcement opens (02-notifications AN4): the title, the
/// date and the message. Opening it reports the tap once, with a profile
/// (AN5); without a connection it says so and reports nothing.
class AnnouncementScreen extends ConsumerStatefulWidget {
  const AnnouncementScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<AnnouncementScreen> createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends ConsumerState<AnnouncementScreen> {
  Future<Announcement>? _load;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load ??= _fetch();
  }

  Future<Announcement> _fetch() async {
    final lang = Localizations.localeOf(context).languageCode;
    final api = ref.read(announcementApiProvider);
    final a = await api.fetch(widget.id, lang);
    if (ref.read(profileControllerProvider) is ProfileLoaded) {
      unawaited(api.opened(widget.id).catchError((Object e) => debugPrint('Hazri: open not reported ($e)')));
    }
    return a;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    return HazriScreen(
      title: l.announcementTitle,
      children: [
        FutureBuilder<Announcement>(
          future: _load,
          builder: (context, snap) {
            if (snap.hasError) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Text(l.announcementOffline, style: HazriText.body.copyWith(color: c.ink2)),
                  const SizedBox(height: 16),
                  PrimaryButton(label: l.actionRetry, secondary: true, onPressed: () => setState(() => _load = _fetch())),
                ],
              );
            }
            final a = snap.data;
            if (a == null) {
              return const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()));
            }
            return HazriCard(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(a.title, style: HazriText.display22.copyWith(color: c.ink)),
                  if (a.createdAt != null) ...[
                    const SizedBox(height: 4),
                    Text(HazriDates.of(context).longDateWithYear(a.createdAt!),
                        style: HazriText.caption.copyWith(color: c.muted)),
                  ],
                  const SizedBox(height: 14),
                  AnnouncementText(a.message),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

/// The admin editor's short formatting, drawn (AN4): paragraphs split by a
/// blank line, "- " bullets, **bold**, *italic*, [text](https://...) links
/// that open in the browser. Anything else is plain text.
class AnnouncementText extends ConsumerWidget {
  const AnnouncementText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final base = HazriText.body.copyWith(color: c.ink, height: 1.5);
    void open(String url) => unawaited(ref.read(systemSettingsProvider).openUrl(url));
    final blocks = <Widget>[];
    for (final para in text.trim().split(RegExp(r'\n\s*\n'))) {
      final lines = para.split('\n');
      if (lines.every((x) => x.trimLeft().startsWith('- '))) {
        for (final x in lines) {
          blocks.add(Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('•  ', style: base),
                Expanded(child: Text.rich(TextSpan(children: inlineSpans(x.trimLeft().substring(2), base, c.primary, open)))),
              ],
            ),
          ));
        }
      } else {
        blocks.add(Text.rich(TextSpan(children: inlineSpans(lines.join('\n'), base, c.primary, open))));
      }
      blocks.add(const SizedBox(height: 10));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: blocks);
  }
}

/// **bold**, *italic* and [text](https://...) within one paragraph.
List<InlineSpan> inlineSpans(String s, TextStyle base, Color link, void Function(String url) open) {
  final out = <InlineSpan>[];
  final re = RegExp(r'\*\*(.+?)\*\*|\*(.+?)\*|\[([^\]]+)\]\((https?://[^\s)]+)\)');
  var at = 0;
  for (final m in re.allMatches(s)) {
    if (m.start > at) out.add(TextSpan(text: s.substring(at, m.start), style: base));
    if (m.group(1) != null) {
      out.add(TextSpan(text: m.group(1), style: base.copyWith(fontWeight: FontWeight.w700)));
    } else if (m.group(2) != null) {
      out.add(TextSpan(text: m.group(2), style: base.copyWith(fontStyle: FontStyle.italic)));
    } else {
      final url = m.group(4)!;
      out.add(TextSpan(
        text: m.group(3),
        style: base.copyWith(color: link, decoration: TextDecoration.underline),
        recognizer: TapGestureRecognizer()..onTap = () => open(url),
      ));
    }
    at = m.end;
  }
  if (at < s.length) out.add(TextSpan(text: s.substring(at), style: base));
  return out;
}
