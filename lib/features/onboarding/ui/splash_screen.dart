import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/widgets/app_mark.dart';

/// The branded splash, shown briefly on first launch only (PRD 1.1).
///
/// Later launches fall straight through to Today, so a returning user sees the
/// system splash and then their day.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _go());
  }

  Future<void> _go() async {
    final done = ref.read(settingsProvider).onboardingDone;
    if (done) {
      if (mounted) context.go(Routes.today);
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (mounted) context.go(Routes.intro);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    const ink = Color(0xFFF3EFE6);

    return Scaffold(
      backgroundColor: HazriColors.dark.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _DawnGlow(),
          const Positioned(left: 0, right: 0, bottom: 0, height: 260, child: _HorizonArcs()),
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 120),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppMark(size: 104, arcColor: ink, sunColor: Color(0xFFF2A24E)),
                const SizedBox(height: 22),
                Text(
                  l.appName,
                  style: HazriText.display44.copyWith(color: ink),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'ਹਾਜ਼ਰੀ',
                      style: HazriText.display22.copyWith(
                        color: const Color(0xFFD8D6E8),
                        fontWeight: FontWeight.w600,
                        fontSize: 21,
                      ),
                    ),
                    Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF2A24E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      'हाज़िरी',
                      style: HazriText.display22.copyWith(
                        color: const Color(0xFFD8D6E8),
                        fontWeight: FontWeight.w600,
                        fontSize: 21,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  l.tagline,
                  textAlign: TextAlign.center,
                  style: HazriText.body.copyWith(fontSize: 16, color: const Color(0xFFB9BAD3)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The saffron dawn glow rising from below the horizon.
class _DawnGlow extends StatelessWidget {
  const _DawnGlow();

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: CustomPaint(painter: _GlowPainter()),
  );
}

class _GlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height + 60);
    final radius = size.width * 0.95;
    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: const [Color(0x8CF2A24E), Color(0x1AF2A24E), Color(0x00F2A24E)],
          stops: const [0, 0.6, 1],
        ).createShader(Rect.fromCircle(center: centre, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(_GlowPainter old) => false;
}

/// Three faint concentric arcs standing in for the day's path.
class _HorizonArcs extends StatelessWidget {
  const _HorizonArcs();

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _ArcsPainter());
}

class _ArcsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const colour = Color(0xFFF2A24E);
    for (final (radius, opacity) in [(0.46, 0.45), (0.33, 0.28), (0.205, 0.18)]) {
      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(size.width / 2, size.height),
          radius: size.width * radius,
        ),
        math.pi,
        math.pi,
        false,
        Paint()
          ..color = colour.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcsPainter old) => false;
}
