import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../models/user.dart';
import '../../state/app_state.dart';
import '../../widgets/floating_nav_bar.dart';
import '../../widgets/liquid_glass.dart';
import '../../widgets/pressable.dart';
import '../borrowing/my_requests_screen.dart';
import '../equipment/equipment_list_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import '../profile/settings_screen.dart';
import 'dashboard_screen.dart';

enum _MenuAction { profile, settings, logout }

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _index = 0;
  bool _menuOpen = false;

  void goToTab(int i) {
    if (i == 4) {
      _showMenuPopup();
      return;
    }
    setState(() => _index = i);
  }

  Future<void> _showMenuPopup() async {
    setState(() => _menuOpen = true);
    final action = await showGeneralDialog<_MenuAction>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss menu',
      barrierColor: Colors.black.withValues(alpha: 0.22),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (ctx, _, __) => const _BottomNavMenuPopup(),
      transitionBuilder: (ctx, anim, _, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.90, end: 1.0).animate(curved),
            alignment: Alignment.bottomRight,
            child: child,
          ),
        );
      },
    );
    if (!mounted) return;
    setState(() => _menuOpen = false);

    if (action == null) return;
    switch (action) {
      case _MenuAction.profile:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        );
        break;
      case _MenuAction.settings:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        );
        break;
      case _MenuAction.logout:
        _confirmLogout();
        break;
    }
  }

  void _confirmLogout() {
    showGlassDialog(
      context: context,
      builder: (ctx) => GlassDialog(
        icon: Icons.logout_rounded,
        iconColor: AppColors.danger,
        title: 'Log Out?',
        message: 'Are you sure you want to log out of your account?',
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<AppState>().logout();
              Navigator.of(ctx).pop();
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/login', (route) => false);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<AppState>().unreadCount;
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          const DashboardScreen(),
          EquipmentListScreen(onBack: () => goToTab(0)),
          const MyRequestsScreen(),
          const NotificationsScreen(),
        ],
      ),
      bottomNavigationBar: FloatingNavBar(
        currentIndex: _index,
        onTap: goToTab,
        unreadCount: unread,
        menuOpen: _menuOpen,
      ),
    );
  }
}

class _BottomNavMenuPopup extends StatelessWidget {
  const _BottomNavMenuPopup();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().currentUser;

    return SafeArea(
      child: Stack(
        children: [
          Positioned(
            right: 18,
            bottom: 78,
            child: Material(
              color: Colors.transparent,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: 215,
                  maxWidth: 245,
                ),
                child: GlassPanel(
                  blur: 30,
                  strong: true,
                  radius: AppRadius.xl,
                  shadows: AppShadows.floating,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (user != null) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: AppColors.primarySoft,
                                child: Text(
                                  user.initials,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.fullName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      user.userType.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, indent: 12, endIndent: 12),
                        const SizedBox(height: 4),
                      ],
                      _PopupMenuItem(
                        icon: Icons.person_outline_rounded,
                        label: 'Profile',
                        tint: AppColors.primary,
                        onTap: () =>
                            Navigator.of(context).pop(_MenuAction.profile),
                      ),
                      _PopupMenuItem(
                        icon: Icons.settings_outlined,
                        label: 'Settings',
                        tint: AppColors.info,
                        onTap: () =>
                            Navigator.of(context).pop(_MenuAction.settings),
                      ),
                      const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: Divider(height: 1),
                      ),
                      _PopupMenuItem(
                        icon: Icons.logout_rounded,
                        label: 'Log Out',
                        tint: AppColors.danger,
                        isDestructive: true,
                        onTap: () =>
                            Navigator.of(context).pop(_MenuAction.logout),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PopupMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color tint;
  final bool isDestructive;
  final VoidCallback onTap;

  const _PopupMenuItem({
    required this.icon,
    required this.label,
    required this.tint,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: tint.withValues(alpha: 0.18)),
              ),
              child: Icon(icon, size: 17, color: tint),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isDestructive ? AppColors.danger : null,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: isDestructive
                  ? AppColors.danger.withValues(alpha: 0.7)
                  : AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
