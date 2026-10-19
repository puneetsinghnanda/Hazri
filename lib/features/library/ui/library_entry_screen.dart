import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/router.dart';
import '../../../core/backend/backend.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/time/clock.dart';
import '../../../core/time/date_format.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/surfaces.dart';
import '../../settings/ui/screen_scaffold.dart';
import '../data/library_repository.dart';
import '../domain/library_entry.dart';
import 'library_screen.dart' show kindLabel;

/// One entry (docs/vichar-content.md "Layouts"). The source decides the
/// layout: a Gurpurab is a calendar card (A), a place is photo-led (B), a day
/// of history is a timeline (C), and anything else is the plain reader of
/// designs 44 and 45. Every layout shows the same text; only the frame differs.
class LibraryEntryScreen extends ConsumerWidget {
  const LibraryEntryScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final entry = ref.watch(libraryEntryProvider(id)).value;

    if (entry == null) {
      return HazriScreen(
        title: l.libraryTitle,
        children: [
          const SizedBox(height: 40),
          Center(
            child: Text(l.libraryNothingMatches,
                style: HazriText.body.copyWith(color: c.muted)),
          ),
        ],
      );
    }

    return switch (entry.layout) {
      EntryLayout.calendar => _CalendarArticle(entry: entry),
      EntryLayout.photo => _PhotoArticle(entry: entry),
      EntryLayout.timeline => _TimelineArticle(entry: entry),
      EntryLayout.plain => _PlainArticle(entry: entry),
    };
  }
}

/// The entries in calendar order from today: the next date first.
List<(LibraryEntry, String)> _upcoming(WidgetRef ref) {
  final today = localDateKey(ref.watch(clockProvider).today());
  final all = ref.watch(libraryEntriesProvider).value ?? const <LibraryEntry>[];
  return [
    for (final e in all)
      if (e.nextDate(today) case final String d) (e, d),
  ]..sort((a, b) => a.$2.compareTo(b.$2));
}

/// The date an entry is about: its next one, or its last when all are past.
DateTime? _dayOf(LibraryEntry e, DateTime today) {
  final d = e.nextDate(localDateKey(today)) ?? e.dates.lastOrNull;
  return d == null ? null : parseLocalDateKey(d);
}

Future<void> _share(LibraryEntry e) =>
    Share.share('${e.title}\n\n${e.summary}\n\n$kSiteBase/gurpurab/${e.id}'.trim(), subject: e.title);

/// A screen reached from a notification has nothing beneath it, so back goes
/// to Today rather than closing the app.
Widget _poppable(BuildContext context, Widget child) => PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(Routes.today);
      },
      child: child,
    );

void _back(BuildContext context) => context.canPop() ? context.pop() : context.go(Routes.library);

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.tooltip, required this.onTap, this.colour, this.fill});

  final String icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? colour;
  final Color? fill;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: Material(
          color: fill ?? Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox.square(
              dimension: 44,
              child: Center(child: AppIcon(icon, size: 21, color: colour ?? context.colors.ink)),
            ),
          ),
        ),
      );
}

/// The article's paragraphs. A paragraph that starts "## " is a heading, as
/// the website's story pages write them; [heading] draws it.
class _Body extends StatelessWidget {
  const _Body({required this.paragraphs, required this.heading, this.lede = false});

  final List<String> paragraphs;
  final Widget Function(String) heading;

  /// Whether the first paragraph is set larger, in ink.
  final bool lede;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < paragraphs.length; i++)
          if (paragraphs[i].startsWith('## '))
            Padding(
              padding: const EdgeInsets.only(top: 22, bottom: 2),
              child: heading(paragraphs[i].substring(3)),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(
                paragraphs[i],
                style: lede && i == 0
                    ? HazriText.body.copyWith(color: c.ink, fontSize: 17, height: 1.65)
                    : HazriText.body.copyWith(color: c.ink2, height: 1.7),
              ),
            ),
      ],
    );
  }
}

class _Facts extends StatelessWidget {
  const _Facts({required this.facts});

  final Map<String, String> facts;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final rows = facts.entries.toList();
    return HazriCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: i == rows.length - 1 ? null : Border(bottom: BorderSide(color: c.rule)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(rows[i].key, style: HazriText.bodySmall.copyWith(color: c.muted)),
                  ),
                  Expanded(
                    child: Text(rows[i].value,
                        textAlign: TextAlign.right,
                        style: HazriText.bodySmall.copyWith(color: c.ink, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Corrections extends StatelessWidget {
  const _Corrections();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Text(L.of(context).libraryCorrections,
            style: HazriText.caption.copyWith(color: context.colors.muted)),
      );
}

/// A row that opens another entry, with its date beside it.
class _EntryLink extends StatelessWidget {
  const _EntryLink({required this.entry, required this.date});

  final LibraryEntry entry;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dates = HazriDates.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: HazriCard(
        padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
        onTap: () => context.push(Routes.libraryEntry(entry.id)),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              child: Column(
                children: [
                  Text('${date.day}', style: HazriText.display22.copyWith(color: c.ink, height: 1)),
                  Text(dates.monthAbbrUpper(date), style: HazriText.eyebrow.copyWith(color: c.muted, fontSize: 10)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.title, style: HazriText.bodyStrong.copyWith(color: c.ink, fontSize: 15)),
                  if (entry.label.isNotEmpty)
                    Text(entry.label, style: HazriText.caption.copyWith(color: c.muted)),
                ],
              ),
            ),
            AppIcon(HazriIconData.chevronRight, size: 18, color: c.muted),
          ],
        ),
      ),
    );
  }
}

/// "In 8 days", "Tomorrow", "Today", or nothing for a day already past.
String? _countdown(L l, DateTime day, DateTime today) {
  final n = day.difference(today).inDays;
  if (n < 0) return null;
  if (n == 0) return l.today;
  if (n == 1) return l.tomorrow;
  return l.libraryInDays(n);
}

// ---------------------------------------------------------------------------
// A · the calendar card, for a Gurpurab.

class _CalendarArticle extends ConsumerWidget {
  const _CalendarArticle({required this.entry});

  final LibraryEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final dates = HazriDates.of(context);
    final today = ref.watch(clockProvider).today();
    final day = _dayOf(entry, today);
    final countdown = day == null ? null : _countdown(l, day, today);
    final eyebrow = [
      if (entry.label.isNotEmpty) entry.label.toUpperCase(),
      if (countdown != null) countdown.toUpperCase(),
    ].join(' · ');
    final upcoming = _upcoming(ref);
    final at = upcoming.indexWhere((u) => u.$1.id == entry.id);
    final next = (at < 0 ? upcoming : upcoming.skip(at + 1)).where((u) => u.$1.id != entry.id).take(2).toList();

    return _poppable(
      context,
      Scaffold(
        backgroundColor: c.bg,
        body: SafeArea(
          child: PhoneWidth(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                Row(
                  children: [
                    _RoundButton(icon: HazriIconData.chevronLeft, tooltip: l.actionBack, onTap: () => _back(context)),
                    Expanded(
                      child: Text(l.libraryTitle,
                          textAlign: TextAlign.center,
                          style: HazriText.bodyStrong.copyWith(color: c.ink2, fontSize: 15)),
                    ),
                    _RoundButton(icon: HazriIconData.share, tooltip: l.libraryShare, onTap: () => _share(entry)),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: c.primary, borderRadius: BorderRadius.circular(24)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (day != null) ...[
                            Container(
                              width: 64,
                              height: 72,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('${day.day}',
                                      style: HazriText.display26.copyWith(color: c.onPrimary, fontSize: 30, height: 1)),
                                  Text(dates.monthAbbrUpper(day),
                                      style: HazriText.eyebrow.copyWith(color: c.kesri, fontSize: 11)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (eyebrow.isNotEmpty)
                                  Text(eyebrow, style: HazriText.eyebrow.copyWith(color: c.kesri)),
                                if (day != null) ...[
                                  const SizedBox(height: 6),
                                  Text(dates.longDateWithYear(day),
                                      style: HazriText.bodySmall.copyWith(color: c.onPrimary.withValues(alpha: 0.75))),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(entry.title, style: HazriText.display26.copyWith(color: c.onPrimary, height: 1.15)),
                      if (entry.summary.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(entry.summary,
                            style: HazriText.bodySmall.copyWith(color: c.onPrimary.withValues(alpha: 0.75), height: 1.5)),
                      ],
                      if (entry.minutes > 0) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(l.libraryMinutes(entry.minutes),
                              style: HazriText.caption.copyWith(color: c.onPrimary)),
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _Body(
                    paragraphs: entry.paragraphs,
                    lede: true,
                    heading: (t) => Row(
                      children: [
                        Container(
                          width: 24,
                          height: 3,
                          decoration: BoxDecoration(color: c.kesri, borderRadius: BorderRadius.circular(2)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(t, style: HazriText.display22.copyWith(color: c.ink, fontSize: 20))),
                      ],
                    ),
                  ),
                ),
                if (entry.facts.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  _Facts(facts: entry.facts),
                ],
                if (next.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  Eyebrow(l.libraryNextInCalendar),
                  const SizedBox(height: 10),
                  for (final n in next) _EntryLink(entry: n.$1, date: parseLocalDateKey(n.$2)),
                ],
                const _Corrections(),
                const SizedBox(height: 16),
                PrimaryButton(label: l.libraryShare, onPressed: () => _share(entry)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// B · photo-led, for a place.

class _PhotoArticle extends ConsumerWidget {
  const _PhotoArticle({required this.entry});

  final LibraryEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final dates = HazriDates.of(context);
    final today = ref.watch(clockProvider).today();
    final day = _dayOf(entry, today);
    final upcoming = _upcoming(ref);
    final at = upcoming.indexWhere((u) => u.$1.id == entry.id);
    final prev = at > 0 ? upcoming[at - 1] : null;
    final next = at >= 0 && at + 1 < upcoming.length ? upcoming[at + 1] : null;
    final top = MediaQuery.paddingOf(context).top;

    Widget chip(String text, Color bg, Color fg) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
          child: Text(text.toUpperCase(), style: HazriText.eyebrow.copyWith(color: fg, fontSize: 11.5)),
        );

    Widget neighbour(String label, (LibraryEntry, String) n, {bool end = false}) => Expanded(
          child: HazriCard(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            onTap: () => context.pushReplacement(Routes.libraryEntry(n.$1.id)),
            child: Column(
              crossAxisAlignment: end ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(), style: HazriText.eyebrow.copyWith(color: c.muted, fontSize: 11)),
                const SizedBox(height: 6),
                Text(n.$1.title,
                    textAlign: end ? TextAlign.right : TextAlign.left,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: HazriText.bodySmall.copyWith(color: c.ink, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        );

    return _poppable(
      context,
      Scaffold(
        backgroundColor: c.bg,
        body: PhoneWidth(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              SizedBox(
                height: 300 + top,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const CustomPaint(painter: _GurdwaraPainter()),
                    Positioned(
                      left: 12,
                      right: 12,
                      top: top + 8,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _RoundButton(
                            icon: HazriIconData.chevronLeft,
                            tooltip: l.actionBack,
                            onTap: () => _back(context),
                            colour: Colors.white,
                            fill: const Color(0x73070A1E),
                          ),
                          _RoundButton(
                            icon: HazriIconData.share,
                            tooltip: l.libraryShare,
                            onTap: () => _share(entry),
                            colour: Colors.white,
                            fill: const Color(0x73070A1E),
                          ),
                        ],
                      ),
                    ),
                    if (entry.imageCaption.isNotEmpty)
                      Positioned(
                        left: 14,
                        right: 14,
                        bottom: 40,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0x80070A1E),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(entry.imageCaption,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: HazriText.caption.copyWith(color: Colors.white, fontSize: 11.5)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -28),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                  decoration: BoxDecoration(
                    color: c.bg,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (entry.label.isNotEmpty) chip(entry.label, c.kesriSoft, c.kesriInk),
                          for (final t in EntryKind.topics)
                            if (t != EntryKind.day && entry.tags.contains(t)) chip(kindLabel(l, t), c.card2, c.ink2),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(entry.title, style: HazriText.display26.copyWith(color: c.ink, height: 1.15)),
                      const SizedBox(height: 8),
                      Text(
                        [
                          if (day != null) dates.longDate(day),
                          if (entry.minutes > 0) l.libraryMinutes(entry.minutes),
                        ].join(' · '),
                        style: HazriText.bodySmall.copyWith(color: c.muted),
                      ),
                      if (entry.summary.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text(entry.summary, style: HazriText.body.copyWith(color: c.ink, fontSize: 17, height: 1.6)),
                      ],
                      _Body(
                        paragraphs: entry.paragraphs,
                        heading: (t) => Text(t, style: HazriText.display22.copyWith(color: c.ink, fontSize: 20)),
                      ),
                      if (prev != null || next != null) ...[
                        const SizedBox(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (prev != null) neighbour(l.libraryPrevious, prev) else const Spacer(),
                            const SizedBox(width: 10),
                            if (next != null) neighbour(l.libraryNext, next, end: true) else const Spacer(),
                          ],
                        ),
                      ],
                      const _Corrections(),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Design B's picture: a Gurdwara against the evening sky. Drawn, not
/// fetched: the app reaches no photo host (PRD §8), so the place is named by
/// the caption over it rather than shown.
class _GurdwaraPainter extends CustomPainter {
  const _GurdwaraPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final sx = w / 390, sy = h / 320;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF232659));
    canvas.drawRect(Rect.fromLTWH(0, 150 * sy, w, h - 150 * sy), Paint()..color = const Color(0xFF5E3550));
    canvas.drawOval(
      Rect.fromCenter(center: Offset(195 * sx, 250 * sy), width: 380 * sx, height: 180 * sy),
      Paint()..color = const Color(0x73D9730D),
    );
    final star = Paint()..color = const Color(0xFFF3F1FA);
    for (final (x, y, r) in const [(60.0, 40.0, 1.6), (140.0, 70.0, 1.2), (300.0, 50.0, 1.8), (350.0, 110.0, 1.2), (220.0, 30.0, 1.4)]) {
      canvas.drawCircle(Offset(x * sx, y * sy), r, star);
    }
    final ink = Paint()..color = const Color(0xFF0B0E26);
    Rect r(double x, double y, double rw, double rh) => Rect.fromLTWH(x * sx, y * sy, rw * sx, rh * sy);
    canvas.drawRect(r(0, 250, 390, 70), ink);
    canvas.drawRect(r(110, 190, 170, 60), ink);
    canvas.drawRect(r(160, 160, 70, 30), ink);
    canvas.drawPath(
      Path()
        ..moveTo(160 * sx, 160 * sy)
        ..cubicTo(160 * sx, 128 * sy, 180 * sx, 114 * sy, 195 * sx, 98 * sy)
        ..cubicTo(210 * sx, 114 * sy, 230 * sx, 128 * sy, 230 * sx, 160 * sy)
        ..close(),
      ink,
    );
    canvas.drawRect(r(194, 74, 2, 26), ink);
    for (final x in const [116.0, 256.0]) {
      canvas.drawRect(r(x, 172, 18, 18), ink);
      canvas.drawPath(
        Path()
          ..moveTo(x * sx, 172 * sy)
          ..cubicTo(x * sx, 162 * sy, (x + 9) * sx, 158 * sy, (x + 9) * sx, 150 * sy)
          ..cubicTo((x + 9) * sx, 158 * sy, (x + 18) * sx, 162 * sy, (x + 18) * sx, 172 * sy)
          ..close(),
        ink,
      );
    }
    canvas.drawRect(r(320, 110, 3, 140), ink);
    canvas.drawPath(
      Path()
        ..moveTo(323 * sx, 112 * sy)
        ..lineTo(362 * sx, 124 * sy)
        ..lineTo(323 * sx, 136 * sy)
        ..close(),
      Paint()..color = const Color(0xFFD9730D),
    );
    final lamp = Paint()..color = const Color(0xD9F2A24E);
    for (final (x, y, rw) in const [(185.0, 230.0, 20.0), (140.0, 224.0, 14.0), (236.0, 224.0, 14.0)]) {
      canvas.drawRRect(
        RRect.fromRectAndCorners(r(x, y - rw / 2, rw, 250 - y + rw / 2),
            topLeft: Radius.circular(rw / 2 * sx), topRight: Radius.circular(rw / 2 * sx)),
        lamp,
      );
    }
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, 120 * sy),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x8C070A1E), Color(0x00070A1E)],
        ).createShader(Rect.fromLTWH(0, 0, w, 120 * sy)),
    );
  }

  @override
  bool shouldRepaint(_GurdwaraPainter old) => false;
}

// ---------------------------------------------------------------------------
// C · the timeline, for a day of history.

class _TimelineArticle extends ConsumerWidget {
  const _TimelineArticle({required this.entry});

  final LibraryEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final dates = HazriDates.of(context);
    final today = ref.watch(clockProvider).today();
    final todayKey = localDateKey(today);
    final next = entry.nextDate(todayKey);
    final day = _dayOf(entry, today);
    final eyebrow = [
      if (entry.label.isNotEmpty) entry.label.toUpperCase(),
      if (day != null) dates.monthYear(day).toUpperCase(),
    ].join(' · ');

    // The story as steps: what comes before the first heading is the
    // opening; each heading and the paragraphs under it are one step.
    final intro = <String>[];
    final steps = <(String, List<String>)>[];
    for (final p in entry.paragraphs) {
      if (p.startsWith('## ')) {
        steps.add((p.substring(3), []));
      } else if (steps.isEmpty) {
        intro.add(p);
      } else {
        steps.last.$2.add(p);
      }
    }
    final calendar = {...entry.dates}.toList();

    return _poppable(
      context,
      Scaffold(
        backgroundColor: c.bg,
        body: PhoneWidth(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                color: c.primary,
                padding: EdgeInsets.fromLTRB(0, MediaQuery.paddingOf(context).top, 0, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _RoundButton(
                              icon: HazriIconData.chevronLeft,
                              tooltip: l.actionBack,
                              onTap: () => _back(context),
                              colour: c.onPrimary),
                          _RoundButton(
                              icon: HazriIconData.share,
                              tooltip: l.libraryShare,
                              onTap: () => _share(entry),
                              colour: c.onPrimary),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (eyebrow.isNotEmpty) Text(eyebrow, style: HazriText.eyebrow.copyWith(color: c.kesri)),
                          const SizedBox(height: 10),
                          Text(entry.title, style: HazriText.display26.copyWith(color: c.onPrimary, height: 1.12)),
                          if (entry.summary.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(entry.summary,
                                style: HazriText.bodySmall
                                    .copyWith(color: c.onPrimary.withValues(alpha: 0.75), height: 1.5)),
                          ],
                        ],
                      ),
                    ),
                    if (calendar.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(l.libraryInTheCalendar.toUpperCase(),
                            style: HazriText.eyebrow.copyWith(color: c.onPrimary.withValues(alpha: 0.75), fontSize: 11)),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 62,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          children: [
                            for (final d in calendar)
                              _DateTile(
                                date: parseLocalDateKey(d),
                                next: d == next,
                                past: d.compareTo(todayKey) < 0,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final p in intro)
                      Padding(
                        padding: const EdgeInsets.only(top: 18),
                        child: Text(p, style: HazriText.body.copyWith(color: c.ink, fontSize: 17, height: 1.65)),
                      ),
                    if (steps.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Eyebrow(l.libraryHowItUnfolds),
                      const SizedBox(height: 14),
                      for (var i = 0; i < steps.length; i++)
                        _Step(title: steps[i].$1, paragraphs: steps[i].$2, first: i == 0, last: i == steps.length - 1),
                    ],
                    if (entry.facts.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      _Facts(facts: entry.facts),
                    ],
                    const _Corrections(),
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

class _DateTile extends StatelessWidget {
  const _DateTile({required this.date, required this.next, required this.past});

  final DateTime date;
  final bool next;
  final bool past;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dates = HazriDates.of(context);
    final fg = next ? const Color(0xFF1C1206) : (past ? c.onPrimary.withValues(alpha: 0.5) : c.onPrimary);
    return Container(
      width: 52,
      margin: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(
        color: next ? c.kesri : Colors.white.withValues(alpha: past ? 0.05 : 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('${date.day}', style: HazriText.bodyStrong.copyWith(color: fg, fontSize: 17, height: 1)),
          const SizedBox(height: 4),
          Text(dates.monthAbbrUpper(date), style: HazriText.eyebrow.copyWith(color: fg, fontSize: 10)),
        ],
      ),
    );
  }
}

/// One step of the story: a dot on the line, its heading and its paragraphs.
/// The first is marked in kesri, where the story starts.
class _Step extends StatelessWidget {
  const _Step({required this.title, required this.paragraphs, required this.first, required this.last});

  final String title;
  final List<String> paragraphs;
  final bool first;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 22,
            child: Column(
              children: [
                const SizedBox(height: 4),
                if (first)
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: c.kesri,
                      shape: BoxShape.circle,
                      border: Border.all(color: c.kesriSoft, width: 4, strokeAlign: BorderSide.strokeAlignOutside),
                    ),
                  )
                else
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: c.card,
                      shape: BoxShape.circle,
                      border: Border.all(color: c.primary, width: 3),
                    ),
                  ),
                if (!last) Expanded(child: Container(width: 2, color: c.rule)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 4 : 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: HazriText.bodyStrong.copyWith(color: first ? c.kesriInk : c.ink, fontSize: 17, height: 1.3)),
                  for (final p in paragraphs)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(p, style: HazriText.body.copyWith(color: c.ink2, fontSize: 16, height: 1.65)),
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

// ---------------------------------------------------------------------------
// Designs 44 and 45: the plain reader, for an entry that names no layout. A
// Gurdwara has labelled facts and an article has paragraphs, and an entry
// with both shows both.

class _PlainArticle extends StatelessWidget {
  const _PlainArticle({required this.entry});

  final LibraryEntry entry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    return HazriScreen(
      title: entry.title,
      subtitle: entry.place.isEmpty ? null : entry.place,
      children: [
        const SizedBox(height: 4),
        Row(
          children: [
            Eyebrow(kindLabel(l, entry.kind)),
            if (entry.minutes > 0) ...[
              const SizedBox(width: 10),
              Text(l.libraryMinutes(entry.minutes), style: HazriText.caption.copyWith(color: c.muted)),
            ],
          ],
        ),
        if (entry.summary.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(entry.summary, style: HazriText.body.copyWith(color: c.ink, height: 1.6)),
        ],
        if (entry.facts.isNotEmpty) ...[
          const SizedBox(height: 14),
          HazriCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final fact in entry.facts.entries) ...[
                  if (fact.key != entry.facts.keys.first) const SizedBox(height: 12),
                  Text(fact.key, style: HazriText.eyebrow.copyWith(color: c.muted)),
                  const SizedBox(height: 2),
                  Text(fact.value, style: HazriText.bodySmall.copyWith(color: c.ink)),
                ],
              ],
            ),
          ),
        ],
        _Body(
          paragraphs: entry.paragraphs,
          heading: (t) => Text(t, style: HazriText.bodyStrong.copyWith(color: c.ink)),
        ),
        const _Corrections(),
      ],
    );
  }
}
