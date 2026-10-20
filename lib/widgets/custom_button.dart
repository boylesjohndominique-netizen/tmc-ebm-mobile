import 'package:flutter/material.dart';
import '../app/motion.dart';
import '../app/theme.dart';
import 'pressable.dart';

/// Primary / secondary action button with a Liquid Glass finish and a subtle
/// press-spring response.
class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool outlined;
  final bool loading;
  final IconData? icon;
  final Color? color;
  final Color? textColor;

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.outlined = false,
    this.loading = false,
    this.icon,
    this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = loading || onPressed == null;

    final child = AnimatedSwitcher(
      duration: AppMotion.responsive(context, AppMotion.fast),
      child: loading
          ? SizedBox(
              key: const ValueKey('loading'),
              width: 21,
              height: 21,
              child: CircularProgressIndicator(
                strokeWidth: 2.3,
                color: outlined ? AppColors.primary : AppColors.onPrimary,
              ),
            )
          : Row(
              key: const ValueKey('label'),
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
    );

    final radius = BorderRadius.circular(AppRadius.md);

    if (outlined) {
      return Opacity(
        opacity: disabled ? 0.55 : 1,
        child: Pressable(
          onTap: disabled ? null : onPressed,
          child: Container(
            height: 54,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: radius,
              boxShadow: disabled ? null : AppShadows.soft,
            ),
            child: IconTheme(
              data: const IconThemeData(color: AppColors.primary, size: 18),
              child: DefaultTextStyle.merge(
                style: TextStyle(
                  color: textColor ?? AppColors.primary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                child: child,
              ),
            ),
          ),
        ),
      );
    }

    final baseColor = color ?? AppColors.primary;
    final gradient = color == null
        ? AppColors.premiumGradient
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [baseColor.withValues(alpha: 0.92), baseColor],
          );

    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Pressable(
        onTap: disabled ? null : onPressed,
        child: Container(
          height: 54,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: radius,
            boxShadow: disabled ? null : AppShadows.primaryGlow,
          ),
          child: IconTheme(
            data: const IconThemeData(color: AppColors.onPrimary, size: 18),
            child: DefaultTextStyle.merge(
              style: TextStyle(
                color: textColor ?? AppColors.onPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.1,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
