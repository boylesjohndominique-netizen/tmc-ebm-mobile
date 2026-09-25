import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../models/user.dart';
import '../../state/app_state.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().currentUser!;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.primaryBlue,
                  child: Text(
                    user.initials,
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 12),
                Text(user.fullName, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.lightBlue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user.userType.label,
                    style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                _ProfileRow(icon: Icons.badge_outlined, label: 'ID Number', value: user.idNumber),
                const Divider(height: 24),
                _ProfileRow(icon: Icons.email_outlined, label: 'Email', value: user.email),
                const Divider(height: 24),
                _ProfileRow(icon: Icons.alternate_email_rounded, label: 'Username', value: user.username),
                const Divider(height: 24),
                _ProfileRow(icon: Icons.phone_outlined, label: 'Contact Number', value: user.contactNumber),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _MenuTile(
            icon: Icons.edit_outlined,
            label: 'Edit Profile',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditProfileScreen())),
          ),
          const SizedBox(height: 10),
          _MenuTile(
            icon: Icons.lock_outline_rounded,
            label: 'Change Password',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
          ),
          const SizedBox(height: 10),
          _MenuTile(
            icon: Icons.logout_rounded,
            label: 'Logout',
            color: AppColors.danger,
            onTap: () => _confirmLogout(context),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log Out?'),
        content: const Text('Are you sure you want to log out of your account?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<AppState>().logout();
              Navigator.of(ctx).pop();
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ProfileRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primaryBlue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _MenuTile({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Icon(icon, color: c, size: 20),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: TextStyle(color: c, fontWeight: FontWeight.w600))),
            Icon(Icons.chevron_right_rounded, color: c.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }
}
