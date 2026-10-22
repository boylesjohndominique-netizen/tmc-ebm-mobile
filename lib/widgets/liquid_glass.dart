import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import '../app/motion.dart';
import '../app/theme.dart';
import 'pressable.dart';

const String kTmcBackgroundAsset =
    'assets/images/pictures/Trinidad Municipal College Entrance.png';

/// Blurred, darkened Trinidad Municipal College entrance backdrop.
///
/// Wrapped in a [RepaintBoundary] so the blurred campus photo is rasterized
/// once by the GPU and remains cheap while scrolling lists above it.
class TmcBackgroundImage extends StatelessWidget {
  final double blurSigma;
  final double? imageOpacity;
  final Gradient? overlayGradient;

  const TmcBackgroundImage({
    super.key,
    this.blurSigma = 9.0,
    this.imageOpacity,
    this.overlayGradient,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final hasCustomOverlay = overlayGradient != null;
    final effectiveOpacity = imageOpacity ?? (dark ? 0.70 : 0.55);
    final effectiveOverlay =
        overlayGradient ??
        LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: dark
              ? const [Color(0x9918202F), Color(0x731B2436), Color(0xAD161E2C)]
              : const [Color(0xB3F2F5FA), Color(0x8CEEF2F8), Color(0xBFF0F4FA)],
          stops: const [0.0, 0.5, 1.0],
        );

    return RepaintBoundary(
      child: IgnorePointer(
        child: ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Transform.scale(
                scale: 1.08,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(
                    sigmaX: blurSigma,
                    sigmaY: blurSigma,
                    tileMode: TileMode.clamp,
                  ),
                  child: Image.asset(
                    kTmcBackgroundAsset,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    cacheWidth: 480,
                    filterQuality: FilterQuality.low,
                    opacity: AlwaysStoppedAnimation<double>(effectiveOpacity),
                    color: (dark || hasCustomOverlay)
                        ? const Color(0xFF18202F).withValues(alpha: 0.35)
                        : const Color(0xFFEEF2F7).withValues(alpha: 0.25),
                    colorBlendMode: (dark || hasCustomOverlay)
                        ? BlendMode.darken
                        : BlendMode.softLight,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(gradient: effectiveOverlay),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ambient, layered backdrop used by every screen.
class LiquidBackground extends StatelessWidget {
  final Widget child;
  final bool orbs;

  const LiquidBackground({super.key, required this.child, this.orbs = true});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.ambientGradient,
                  ),
                ),
                const TmcBackgroundImage(),
                if (orbs) ...[
                  Positioned(
                    top: -150,
                    right: -120,
                    child: _Orb(
                      size: 360,
                      color: AppColors.primary.withValues(
                        alpha: dark ? 0.18 : 0.10,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 260,
                    left: -190,
                    child: _Orb(
                      size: 380,
                      color: AppColors.gold.withValues(
                        alpha: dark ? 0.10 : 0.08,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -160,
                    right: -120,
                    child: _Orb(
                      size: 360,
                      color: AppColors.info.withValues(
                        alpha: dark ? 0.14 : 0.08,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

class _Orb extends StatelessWidget {
  final double size;
  final Color color;

  const _Orb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
            stops: const [0.0, 1.0],
          ),
        ),
      ),
    );
  }
}

/// Transparent Scaffold sitting on the ambient liquid backdrop.
class LiquidScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool resizeToAvoidBottomInset;
  final bool extendBody;

  const LiquidScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.resizeToAvoidBottomInset = true,
    this.extendBody = false,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBar,
        body: body,
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        extendBody: extendBody,
      ),
    );
  }
}

/// The signature Liquid Glass surface.
///
/// A translucent, blurred layer with a light-mode highlight and
/// soft depth. Use [blur] = 0 for repeated list tiles to keep rendering cheap;
/// reserve real backdrop blur for navigation, headers, sheets and heroes.
class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final double blur;
  final bool strong;
  final Color? tint;
  final Gradient? gradient;
  final List<BoxShadow>? shadows;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding,
    this.radius = AppRadius.lg,
    this.blur = 18,
    this.strong = false,
    this.tint,
    this.gradient,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    // Depend on the inherited theme so glass surfaces rebuild with it even
    // when their parent is a canonicalized `const` widget.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderRadius = BorderRadius.circular(radius);
    final fill =
        tint ?? (strong ? AppColors.glassFillStrong : AppColors.glassFill);
    final effectiveGradient =
        gradient ??
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark ? fill : AppColors.glassHighlight.withValues(alpha: 0.55),
            fill,
            fill,
          ],
          stops: const [0.0, 0.42, 1.0],
        );

    Widget surface = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: effectiveGradient,
      ),
      child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
    );

    if (blur > 0) {
      surface = ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: surface,
        ),
      );
    } else if (padding == null || padding == EdgeInsets.zero) {
      surface = ClipRRect(borderRadius: borderRadius, child: surface);
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: shadows ?? AppShadows.card,
      ),
      child: surface,
    );
  }
}

/// Lighter glass tile for long lists — no backdrop blur.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = AppRadius.lg,
  });

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      blur: 0,
      radius: radius,
      padding: padding,
      shadows: AppShadows.card,
      child: child,
    );
  }
}

/// Circular/rounded glass button used in headers and toolbars.
class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final double size;
  final double iconSize;
  final Color? iconColor;
  final bool active;
  final Widget? badge;
  final Color? tint;

  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.size = 44,
    this.iconSize = 21,
    this.iconColor,
    this.active = false,
    this.badge,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final content = SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Icon(
            icon,
            size: iconSize,
            color:
                iconColor ??
                (active ? AppColors.primary : AppColors.textPrimary),
          ),
          if (badge != null) Positioned(top: 6, right: 7, child: badge!),
        ],
      ),
    );

    return Pressable(
      onTap: onTap,
      child: Tooltip(
        message: tooltip ?? '',
        child: Semantics(button: true, label: tooltip, child: content),
      ),
    );
  }
}

/// Glass pill / segmented chip with animated fill.
class GlassChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final String? count;

  const GlassChip({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
    this.icon,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    final duration = AppMotion.responsive(context, AppMotion.fast);

    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: duration,
        curve: AppMotion.emphasized,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.premiumGradient : null,
          color: selected ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: selected ? AppShadows.primaryGlow : AppShadows.soft,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: selected ? AppColors.onPrimary : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.1,
                color: selected ? AppColors.onPrimary : AppColors.textPrimary,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 1.5,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.onPrimary.withValues(alpha: 0.22)
                      : AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  count!,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: selected
                        ? AppColors.onPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Section title with an optional trailing action.
class GlassSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const GlassSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(letterSpacing: -0.4),
          ),
        ),
        if (actionLabel != null)
          Pressable(
            onTap: onAction,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  actionLabel!,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 17,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Small uppercase section label in the iOS grouped-list tradition.
class GlassSectionLabel extends StatelessWidget {
  final String text;

  const GlassSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: AppColors.textTertiary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

/// Floating Liquid Glass dialog shell (intentionally not a native system alert).
class GlassDialog extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final String title;
  final String? message;
  final Widget? content;
  final List<Widget> actions;

  const GlassDialog({
    super.key,
    this.icon,
    this.iconColor,
    required this.title,
    this.message,
    this.content,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 26),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: GlassPanel(
          blur: 30,
          strong: true,
          radius: AppRadius.xl,
          shadows: AppShadows.floating,
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 28, color: iconColor ?? AppColors.primary),
                const SizedBox(height: 14),
              ],
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(
                  message!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
              ],
              if (content != null) ...[
                const SizedBox(height: 14),
                Flexible(child: content!),
              ],
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    for (var i = 0; i < actions.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      actions[i],
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

Future<T?> showGlassDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: Colors.black.withValues(alpha: 0.34),
    builder: builder,
  );
}

/// Inset, floating glass bottom sheet.
Future<T?> showGlassSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.36),
    builder: (ctx) {
      final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
      return AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.fromLTRB(10, 0, 10, 10 + bottomInset),
        child: GlassPanel(
          radius: AppRadius.xxl,
          blur: 30,
          strong: true,
          shadows: AppShadows.floating,
          padding: EdgeInsets.zero,
          child: SafeArea(top: false, child: builder(ctx)),
        ),
      );
    },
  );
}

/// Grip handle used at the top of glass sheets.
class GlassSheetHandle extends StatelessWidget {
  const GlassSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 42,
        height: 5,
        margin: const EdgeInsets.only(top: 12, bottom: 4),
        decoration: BoxDecoration(
          color: AppColors.textTertiary.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
    );
  }
}
