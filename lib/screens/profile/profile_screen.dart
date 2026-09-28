import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../models/user.dart';
import '../../state/app_state.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/id_upload_field.dart';
import '../../widgets/pressable.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
        children: [
          // Identity header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              boxShadow: AppShadows.primaryGlow,
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      user.initials,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user.fullName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    user.userType.label,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
                // Account status chip (admin-verified lifecycle).
                const SizedBox(height: 10),
                _AccountStatusChip(status: user.accountStatus),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Account details card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.divider.withValues(alpha: 0.6)),
              boxShadow: AppShadows.soft,
            ),
            child: Column(
              children: [
                _ProfileRow(icon: Icons.badge_outlined, label: 'ID Number', value: user.idNumber),
                const Divider(height: 24),
                _ProfileRow(icon: Icons.email_outlined, label: 'Email', value: user.email),
                const Divider(height: 24),
                _ProfileRow(
                    icon: Icons.alternate_email_rounded, label: 'Username', value: user.username),
                const Divider(height: 24),
                _ProfileRow(
                    icon: Icons.phone_outlined, label: 'Contact Number', value: user.contactNumber),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ID verification card — submit/review ID photos here instead of at
          // registration.
          _IdVerificationCard(status: appState.idVerificationStatus),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.divider.withValues(alpha: 0.6)),
              boxShadow: AppShadows.soft,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (appState.isDarkMode ? AppColors.gold : AppColors.primary)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    appState.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: appState.isDarkMode ? AppColors.gold : AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dark Mode', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        appState.isDarkMode ? 'Dark theme enabled' : 'Light theme enabled',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: appState.isDarkMode,
                  onChanged: (_) => appState.toggleDarkMode(),
                  activeTrackColor: AppColors.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _MenuTile(
            icon: Icons.edit_outlined,
            label: 'Edit Profile',
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const EditProfileScreen())),
          ),
          const SizedBox(height: 10),
          _MenuTile(
            icon: Icons.lock_outline_rounded,
            label: 'Change Password',
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
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

/// Small pill showing the account's admin-verification lifecycle on the
/// profile header: Pending → Active → Banned (mirrors the web admin).
class _AccountStatusChip extends StatelessWidget {
  final String status;

  const _AccountStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      'Pending' => (
        'Account Not Verified',
        AppColors.gold,
        Icons.hourglass_top_rounded,
      ),
      'Banned' => (
        'Account Banned',
        const Color(0xFFFFB4AE),
        Icons.block_rounded,
      ),
      _ => (
        'Account Verified',
        const Color(0xFF7FE0AE),
        Icons.verified_rounded,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// ID verification card: shows the current verification label and, when not
/// yet submitted, lets the user capture both sides of their ID in place.
/// Approved/rejected states come from the backend once the ID endpoint lands.
class _IdVerificationCard extends StatefulWidget {
  final IdVerificationStatus status;

  const _IdVerificationCard({required this.status});

  @override
  State<_IdVerificationCard> createState() => _IdVerificationCardState();
}

class _IdVerificationCardState extends State<_IdVerificationCard> {
  String? _idFrontPath;
  String? _idBackPath;
  String? _error;
  bool _loading = false;

  Future<void> _submit() async {
    if (_idFrontPath == null || _idBackPath == null) {
      setState(
          () => _error = 'Capture both sides of your ID to continue.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    await context.read<AppState>().submitIdVerification(
          idFrontPath: _idFrontPath!,
          idBackPath: _idBackPath!,
        );

    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.6)),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.verified_user_outlined,
                    size: 17, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ID Verification',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      'Prove your identity to unlock borrowing.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              _IdVerificationBadge(status: widget.status),
            ],
          ),

          // Capture slots only appear while verification is not yet submitted.
          if (widget.status == IdVerificationStatus.notSubmitted) ...[
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: IdPhotoField(
                    label: 'ID Front',
                    hint: 'Front side',
                    imagePath: _idFrontPath,
                    onChanged: (p) => setState(() {
                      _idFrontPath = p;
                      if (_idFrontPath != null && _idBackPath != null) _error = null;
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: IdPhotoField(
                    label: 'ID Back',
                    hint: 'Back side',
                    imagePath: _idBackPath,
                    onChanged: (p) => setState(() {
                      _idBackPath = p;
                      if (_idFrontPath != null && _idBackPath != null) _error = null;
                    }),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppColors.danger, size: 15),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(_error!,
                        style:
                            const TextStyle(fontSize: 12, color: AppColors.danger)),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            CustomButton(
              label: 'Submit for Verification',
              onPressed: _submit,
              loading: _loading,
            ),
          ],
        ],
      ),
    );
  }
}

/// Pill label identifying whether the user's ID is verified or not.
class _IdVerificationBadge extends StatelessWidget {
  final IdVerificationStatus status;

  const _IdVerificationBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      IdVerificationStatus.notSubmitted => (
        'Account Not Verified',
        AppColors.textTertiary,
        Icons.radio_button_unchecked_rounded,
      ),
      IdVerificationStatus.pending => (
        'Pending Review',
        AppColors.warning,
        Icons.hourglass_top_rounded,
      ),
      IdVerificationStatus.approved => (
        'Account Verified',
        AppColors.success,
        Icons.verified_rounded,
      ),
      IdVerificationStatus.rejected => (
        'Rejected',
        AppColors.danger,
        Icons.cancel_rounded,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 17, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
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
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimary;
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.6)),
          boxShadow: AppShadows.soft,
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: c.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: c, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(color: c, fontWeight: FontWeight.w600, fontSize: 14)),
            ),
            Icon(Icons.chevron_right_rounded, color: c.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}
