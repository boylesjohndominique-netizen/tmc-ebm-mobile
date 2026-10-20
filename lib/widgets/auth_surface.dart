import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../app/motion.dart';
import '../app/theme.dart';
import 'liquid_glass.dart';

/// Ambient backdrop shared by the auth screens: a soft radial brand wash with
/// three slowly drifting color orbs for organic depth. Never distracts from
/// the foreground content.
class AmbientBackground extends StatefulWidget {
  final Widget child;
  final bool withLogoHeader;

  const AmbientBackground({
    super.key,
    required this.child,
    this.withLogoHeader = true,
  });

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _orbController;

  @override
  void initState() {
    super.initState();
    // Single shared controller for the three background orbs.
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _orbController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        // ── Isolated background + drifting orbs layer ───────────────────────
        Positioned.fill(
          child: RepaintBoundary(
            child: IgnorePointer(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration:
                        BoxDecoration(gradient: AppColors.ambientGradient),
                  ),
                  const TmcBackgroundImage(),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(-0.2, -1.0),
                        radius: 1.5,
                        colors: [
                          AppColors.primary.withValues(
                            alpha: AppColors.isDark ? 0.26 : 0.16,
                          ),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.8],
                      ),
                    ),
                  ),
                  ...List.generate(3, (i) {
                    final colors = [
                      [AppColors.primary, AppColors.primaryDeep],
                      [AppColors.gold, const Color(0xFFFFD98A)],
                      [AppColors.info, AppColors.primary],
                    ][i];
                    final sizes = [260.0, 180.0, 220.0][i];
                    final phase = i * 2.1;
                    return Positioned(
                      top: [-80.0, 130.0, 40.0][i],
                      right: [-90.0, -70.0, null][i],
                      left: [null, null, -100.0][i],
                      child: AnimatedBuilder(
                        animation: _orbController,
                        builder: (context, child) {
                          final angle =
                              _orbController.value * 2 * math.pi + phase;
                          return Transform.translate(
                            offset: Offset(
                              math.sin(angle) * (10.0 + i * 4),
                              math.cos(angle) * (8.0 + i * 3),
                            ),
                            child: child,
                          );
                        },
                        child: Container(
                          width: sizes,
                          height: sizes,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                colors.first
                                    .withValues(alpha: isDark ? 0.18 : 0.10),
                                colors.last.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),

        // ── Foreground content ──────────────────────────────────────────────
        widget.child,
      ],
    );
  }
}

/// Brand header: logo + letterspaced wordmark.
class AmbientLogoHeader extends StatelessWidget {
  const AmbientLogoHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          'assets/images/tmc_logo.png',
          width: 44,
          height: 44,
          cacheWidth: 132,
        ),
        const SizedBox(width: 12),
        Text(
          'TMCEBMS',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.6,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// Elevated frosted form card used as the main surface on auth screens.
class AmbientFormCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const AmbientFormCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: GlassPanel(
        blur: 26,
        strong: true,
        radius: AppRadius.xl,
        shadows: AppShadows.floating,
        padding: padding,
        child: child,
      ),
    );
  }
}

/// Small caps-style field label matching the auth form design.
class FieldLabel extends StatelessWidget {
  final String text;

  const FieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
        color: AppColors.textSecondary,
      ),
    );
  }
}

/// Wrap an input row with an animated glow ring when [focused] is true.
class FocusGlow extends StatelessWidget {
  final bool focused;
  final Widget child;

  const FocusGlow({super.key, required this.focused, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.normal,
      curve: AppMotion.emphasized,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md + 4),
        boxShadow: focused
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ]
            : const [],
      ),
      child: child,
    );
  }
}
