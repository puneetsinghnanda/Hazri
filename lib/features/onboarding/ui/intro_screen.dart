import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/surfaces.dart';
import '../widgets/intro_art.dart';
import '../widgets/language_pill.dart';

/// The three intro pages (PRD 1.1).
class IntroScreen extends ConsumerStatefulWidget {
  const IntroScreen({super.key});

  @override
  ConsumerState<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends ConsumerState<IntroScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page >= 2) {
      context.go(Routes.setup(1));
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);

    final pages = <(String, String, Widget)>[
      (l.introTitle1, l.introBody1, const IntroArtDayArc()),
      (l.introTitle2, l.introBody2, const IntroArtFollowing()),
      (l.introTitle3, l.introBody3, const IntroArtScripts()),
    ];

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: PhoneWidth(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const LanguagePill(),
                    TextButton(
                      onPressed: () => context.go(Routes.setup(1)),
                      child: Text(
                        l.actionSkip,
                        style: HazriText.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: c.ink2,
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: pages.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (context, i) {
                      final (title, body, art) = pages[i];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Center(
                              child: SingleChildScrollView(child: art),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            title,
                            style: HazriText.display26.copyWith(
                              fontSize: 30,
                              height: 1.15,
                              color: c.ink,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            body,
                            style: HazriText.body.copyWith(
                              fontSize: 16,
                              height: 1.5,
                              color: c.ink2,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        for (var i = 0; i < pages.length; i++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 6),
                            height: 8,
                            width: i == _page ? 26 : 8,
                            decoration: BoxDecoration(
                              color: i == _page ? c.kesri : c.rule,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                      ],
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 150),
                      child: _NextButton(
                        label: _page >= 2 ? l.introGetStarted : l.actionNext,
                        onPressed: _next,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NextButton extends StatelessWidget {
  const _NextButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.primary,
      borderRadius: BorderRadius.circular(HazriRadius.button),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(HazriRadius.button),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26),
          child: SizedBox(
            height: HazriSize.buttonMinHeight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: HazriText.button.copyWith(color: c.onPrimary),
                  ),
                ),
                const SizedBox(width: 10),
                AppIcon(HazriIconData.chevronRight, size: 20, color: c.onPrimary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
