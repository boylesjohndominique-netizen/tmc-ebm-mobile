import 'package:flutter/material.dart';
import 'dart:ui' show ImageFilter;
import '../app/motion.dart';
import '../app/theme.dart';

/// Floating iOS-style, icon-only bottom navigation.
///
/// Rendered as a detached pill that floats above the bottom edge with blur,
/// soft depth, an animated active pill and a springy icon scale — with no
/// text labels, per the design spec.
class FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int unreadCount;

  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.unreadCount = 0,
  });

  static const _icons = [
    Icons.space_dashboard_rounded,
    Icons.inventory_2_outlined,
    Icons.assignment_outlined,
    Icons.notifications_none_rounded,
    Icons.person_outline_rounded,
  ];

  static const _activeIcons = [
    Icons.space_dashboard_rounded,
    Icons.inventory_2_rounded,
    Icons.assignment_rounded,
    Icons.notifications_rounded,
    Icons.person_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: AppColors.isDark ? 0.88 : 0.92),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: AppColors.isDark
                      ? AppColors.divider.withValues(alpha: 0.8)
                      : Colors.white.withValues(alpha: 0.6),
                ),
                boxShadow: AppShadows.floating,
              ),
              child: Row(
                children: List.generate(_icons.length, (i) {
                  return Expanded(child: _NavButton(
                    icon: _icons[i],
                    activeIcon: _activeIcons[i],
                    selected: currentIndex == i,
                    showDot: i == 3 && unreadCount > 0,
                    onTap: () => onTap(i),
                  ));
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final bool selected;
  final bool showDot;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.activeIcon,
    required this.selected,
    required this.showDot,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: selected ? 1.0 : 0.0),
        duration: const Duration(milliseconds: 260),
        curve: selected ? Curves.easeOutBack : AppMotion.emphasized,
        builder: (context, t, child) {
          final clampedT = t.clamp(0.0, 1.5);
          final scale = 1.0 + 0.14 * (1.0 - (1.0 - clampedT) * (1.0 - clampedT));
          return Transform.scale(
            scale: scale,
            child: Opacity(opacity: (0.55 + 0.45 * clampedT).clamp(0.0, 1.0), child: child),
          );
        },
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Animated background pill for the active tab.
            AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: AppMotion.emphasized,
              width: selected ? 52 : 0,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary
                    .withValues(alpha: selected ? (AppColors.isDark ? 0.22 : 0.13) : 0.0),
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            Icon(
              selected ? activeIcon : icon,
              size: 24,
              color: selected ? AppColors.primary : AppColors.textTertiary,
            ),
            if (showDot)
              Positioned(
                top: 6,
                right: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
