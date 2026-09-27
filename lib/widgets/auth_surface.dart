import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../app/motion.dart';
import '../app/theme.dart';
import 'theme_toggle_button.dart';

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
    with TickerProviderStateMixin {
  late final List<AnimationController> _orbControllers;

  @override
  void initState() {
    super.initState();
    // Slow ambient drift for the three background orbs.
    _orbControllers = List.generate(3, (i) {
      return AnimationController(
        vsync: this,
        duration: Duration(seconds: 9 + i * 3),
        value: math.Random(i * 7 + 1).nextDouble(),
      )..repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    for (final c in _orbControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Gradient wash ────────────────────────────────────────────────────
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.2, -1.0),
                radius: 1.6,
                colors: [
                  AppColors.primary.withValues(alpha: 0.18),
                  AppColors.background,
                ],
                stops: const [0.0, 0.75],
              ),
            ),
          ),
        ),

        // ── Drifting orbs ───────────────────────────────────────────────────
        ...List.generate(3, (i) {
          final colors = [
            [AppColors.primary, AppColors.primaryDeep],
            [AppColors.gold, const Color(0xFFFFD98A)],
            [AppColors.info, AppColors.primary],
          ][i];
          final sizes = [260.0, 180.0, 220.0][i];
          return Positioned(
            top: [-80.0, 130.0, 40.0][i],
            right: [-90.0, -70.0, null][i],
            left: [null, null, -100.0][i],
            child: AnimatedBuilder(
              animation: _orbControllers[i],
              builder: (context, child) {
                final t = _orbControllers[i].value;
                return Transform.translate(
                  offset: Offset(
                    math.sin(t * 2 * math.pi) * (10.0 + i * 4),
                    math.cos(t * 2 * math.pi) * (8.0 + i * 3),
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
                      colors.first.withValues(alpha: 0.30),
                      colors.last.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),

        // ── Foreground content ──────────────────────────────────────────────
        widget.child,
      ],
    );
  }
}

/// Brand header: gradient logo tile with glow + letterspaced wordmark.
class AmbientLogoHeader extends StatelessWidget {
  const AmbientLogoHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(19),
            boxShadow: AppShadows.primaryGlow,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
              width: 1.2,
            ),
          ),
          child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 28),
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
        const Spacer(),
        const ThemeToggleButton(),
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
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: AppColors.isDark ? 0.94 : 0.92),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: AppColors.isDark ? AppColors.divider : Colors.white,
          width: 1.2,
        ),
        boxShadow: AppShadows.floating,
      ),
      child: child,
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
