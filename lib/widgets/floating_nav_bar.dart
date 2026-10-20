import 'package:flutter/material.dart';
import '../app/motion.dart';
import '../app/theme.dart';
import 'liquid_glass.dart';
import 'pressable.dart';

/// Floating Liquid Glass tab bar.
///
/// A detached, translucent pill with a glossy rim, soft depth and an animated
/// tinted lens behind the active tab. Labels stay visible for clarity.
class FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int unreadCount;
  final bool menuOpen;

  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.unreadCount = 0,
    this.menuOpen = false,
  });

  static const _icons = [
    Icons.grid_view_rounded,
    Icons.inventory_2_outlined,
    Icons.assignment_outlined,
    Icons.notifications_none_rounded,
    Icons.menu_rounded,
  ];

  static const _activeIcons = [
    Icons.grid_view_rounded,
    Icons.inventory_2_rounded,
    Icons.assignment_rounded,
    Icons.notifications_rounded,
    Icons.menu_open_rounded,
  ];

  static const _labels = ['Home', 'Gear', 'Requests', 'Alerts', 'Menu'];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 6),
        child: GlassPanel(
          blur: 30,
          strong: true,
          radius: AppRadius.pill,
          shadows: AppShadows.floating,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: SizedBox(
            height: 58,
            child: Row(
              children: List.generate(_icons.length, (i) {
                final isMenuSlot = i == 4;
                final isSelected =
                    isMenuSlot ? menuOpen : (!menuOpen && currentIndex == i);
                return Expanded(
                  child: _NavItem(
                    icon: _icons[i],
                    activeIcon: _activeIcons[i],
                    label: _labels[i],
                    selected: isSelected,
                    showDot: i == 3 && unreadCount > 0,
                    onTap: () => onTap(i),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final bool showDot;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.showDot,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final duration = AppMotion.responsive(context, AppMotion.normal);

    return Pressable(
      onTap: onTap,
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedScale(
                    scale: selected ? 1.06 : 1.0,
                    duration: duration,
                    curve: AppMotion.emphasized,
                    child: Icon(
                      selected ? activeIcon : icon,
                      size: 21,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                  if (showDot)
                    Positioned(
                      top: -2,
                      right: -3,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  letterSpacing: -0.1,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
