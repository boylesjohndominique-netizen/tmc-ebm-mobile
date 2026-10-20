import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app/theme.dart';
import '../state/app_state.dart';
import 'liquid_glass.dart';
import 'pressable.dart';

/// Clean, aesthetic button that toggles between light and dark mode.
///
/// Features smooth rotation and scale micro-transitions, translucent
/// frosted styling, and appropriate contrasting colors for both modes.
class ThemeToggleButton extends StatelessWidget {
  final bool isHeaderStyle;
  final VoidCallback? onToggled;

  const ThemeToggleButton({
    super.key,
    this.isHeaderStyle = true,
    this.onToggled,
  });

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDark = appState.isDarkMode;

    void handleTap() {
      appState.toggleDarkMode();
      onToggled?.call();
    }

    final buttonContent = AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return RotationTransition(
          turns: Tween<double>(begin: 0.75, end: 1.0).animate(animation),
          child: ScaleTransition(scale: animation, child: child),
        );
      },
      child: Icon(
        isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
        key: ValueKey<bool>(isDark),
        // On tinted headers (gradient) use white/gold; on plain surfaces use
        // theme-aware ink so the icon stays visible in both modes.
        color: isHeaderStyle
            ? (isDark ? AppColors.gold : Colors.white)
            : (isDark ? AppColors.gold : AppColors.textPrimary),
        size: 21,
      ),
    );

    return Pressable(
      onTap: handleTap,
      child: Tooltip(
        message: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
        child: GlassPanel(
          blur: 14,
          radius: 15,
          padding: EdgeInsets.zero,
          shadows: AppShadows.soft,
          tint: isHeaderStyle
              ? Colors.white.withValues(alpha: isDark ? 0.12 : 0.18)
              : null,
          borderColor:
              isHeaderStyle ? Colors.white.withValues(alpha: 0.24) : null,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(child: buttonContent),
          ),
        ),
      ),
    );
  }
}
