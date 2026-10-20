import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app/theme.dart';
import '../state/app_state.dart';
import 'pressable.dart';

/// Clean, aesthetic button that toggles between light and dark mode.
///
/// Features smooth rotation and scale micro-transitions and appropriate
/// contrasting colors for both modes.
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
    final isDark = context.select<AppState, bool>((s) => s.isDarkMode);

    void handleTap() {
      context.read<AppState>().toggleDarkMode();
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
        color: isDark ? AppColors.gold : AppColors.primary,
        size: 21,
      ),
    );

    return Pressable(
      onTap: handleTap,
      child: Tooltip(
        message: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(child: buttonContent),
        ),
      ),
    );
  }
}
