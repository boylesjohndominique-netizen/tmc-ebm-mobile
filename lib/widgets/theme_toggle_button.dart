import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app/theme.dart';
import '../state/app_state.dart';

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
        color: isDark ? AppColors.gold : Colors.white,
        size: 21,
      ),
    );

    if (isHeaderStyle) {
      return Material(
        color: Colors.white.withValues(alpha: isDark ? 0.14 : 0.18),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: handleTap,
          borderRadius: BorderRadius.circular(14),
          child: Tooltip(
            message: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            child: SizedBox(
              width: 42,
              height: 42,
              child: Center(child: buttonContent),
            ),
          ),
        ),
      );
    }

    return IconButton(
      onPressed: handleTap,
      tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
      icon: buttonContent,
    );
  }
}
