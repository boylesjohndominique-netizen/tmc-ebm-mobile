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

/// Profile — clean, minimal, iOS-inspired.
///
/// Structure: centered identity header → account card → verification card
/// (state-aware) → grouped settings list. Wording kept to a minimum;
/// iconography and color carry the meaning.
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
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          // ── Identity ───────────────────────────────────────────────────
          const SizedBox(height: 8),
          _IdentityHeader(user: user),
          const SizedBox(height: 28),

          // ── Account details ────────────────────────────────────────────
          // Not const: reads theme-dependent AppColors getters (see the
          // Verification section note above).
          _SectionLabel('Account'),
          const SizedBox(height: 8),
          _Card(
            child: Column(
              children: [
                _DetailRow(icon: Icons.badge_outlined, value: user.idNumber),
                const Divider(height: 1, indent: 40),
                _DetailRow(icon: Icons.mail_outline_rounded, value: user.email),
                const Divider(height: 1, indent: 40),
                _DetailRow(
                    icon: Icons.phone_outlined, value: user.contactNumber.isEmpty ? '—' : user.contactNumber),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── ID verification (state-aware) ──────────────────────────────
          // NOTE: deliberately not `const` — these widgets read AppColors
          // getters that change with the theme. Dart canonicalizes identical
          // const instances, so a const copy would be reused across theme
          // switches and the card would stay stuck in the old theme's colors.
          _SectionLabel('Verification'),
          const SizedBox(height: 8),
          _VerificationCard(status: appState.idVerificationStatus),
          const SizedBox(height: 24),

          // ── Settings ───────────────────────────────────────────────────
          _SectionLabel('Settings'),
          const SizedBox(height: 8),
          _Card(
            child: Column(
              children: [
                _AppearanceTile(isDark: appState.isDarkMode),
                const Divider(height: 1, indent: 56),
                _SettingsRow(
                  icon: Icons.edit_outlined,
                  label: 'Edit Profile',
                  onTap: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                ),
                const Divider(height: 1, indent: 56),
                _SettingsRow(
                  icon: Icons.lock_outline_rounded,
                  label: 'Password',
                  onTap: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
                ),
                const Divider(height: 1, indent: 56),
                _SettingsRow(
                  icon: Icons.logout_rounded,
                  label: 'Log Out',
                  tint: AppColors.danger,
                  onTap: () => _confirmLogout(context),
                ),
              ],
            ),
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

// ---------------------------------------------------------------------------
// Identity header — avatar, name, role + one status pill. No card, no clutter.
// ---------------------------------------------------------------------------
class _IdentityHeader extends StatelessWidget {
  final AppUser user;
  const _IdentityHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    // Verification is its own dimension — a banned user who was verified
    // keeps the badge, and an unbanned Pending user does not get one.
    final verified = user.isIdVerified;

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
                boxShadow: AppShadows.soft,
              ),
              child: CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primarySoft,
                child: Text(
                  user.initials,
                  style: const TextStyle(
                      color: AppColors.primary, fontSize: 26, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            if (verified)
              Positioned(
                right: 2,
                bottom: 2,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 2.5),
                  ),
                  child: const Icon(Icons.check_rounded, size: 11, color: Colors.white),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          user.fullName,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.4),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              user.userType.label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(width: 8),
            _StatusDot(status: user.accountStatus),
          ],
        ),
      ],
    );
  }
}

/// Tiny colored dot — the quietest possible status indicator.
class _StatusDot extends StatelessWidget {
  final String status;
  const _StatusDot({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'Pending' => AppColors.warning,
      'Banned' => AppColors.danger,
      _ => AppColors.success,
    };
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

// ---------------------------------------------------------------------------
// Section label — one word, small caps, whisper-quiet.
// ---------------------------------------------------------------------------
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

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

// ---------------------------------------------------------------------------
// Shared card shell — surface, hairline border, soft depth.
// ---------------------------------------------------------------------------
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.6)),
        boxShadow: AppShadows.soft,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Detail row — icon + value. Labels dropped; the values speak for themselves.
// ---------------------------------------------------------------------------
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String value;
  const _DetailRow({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textTertiary),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Verification card — four quiet states:
//   notSubmitted → capture slots + Submit
//   pending      → under review
//   rejected     → rejected
//   approved     → verified
// ---------------------------------------------------------------------------
class _VerificationCard extends StatefulWidget {
  final IdVerificationStatus status;
  const _VerificationCard({required this.status});

  @override
  State<_VerificationCard> createState() => _VerificationCardState();
}

class _VerificationCardState extends State<_VerificationCard> {
  String? _idFrontPath;
  String? _idBackPath;
  String? _error;
  bool _loading = false;

  Future<void> _submit() async {
    if (_idFrontPath == null || _idBackPath == null) {
      setState(() => _error = 'Capture both sides of your ID to continue.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    final error = await context.read<AppState>().submitIdVerification(
          idFrontPath: _idFrontPath!,
          idBackPath: _idBackPath!,
        );

    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    // None of these may be `const`: _Card's surface/border and the label text
    // color come from theme-dependent sources, and Dart canonicalizes const
    // instances — a const card would be skipped on rebuild and stay stuck in
    // the previous theme after a Light/Dark switch.
    return switch (widget.status) {
      IdVerificationStatus.notSubmitted => _buildCapture(context),
      IdVerificationStatus.pending => _Card(
          child: _StateRow(
            icon: Icons.hourglass_top_rounded,
            tint: AppColors.warning,
            label: 'Under review',
            trailing: _Pill('Pending', AppColors.warning),
          ),
        ),
      IdVerificationStatus.rejected => _Card(
          child: _StateRow(
            icon: Icons.cancel_outlined,
            tint: AppColors.danger,
            label: 'ID rejected',
            trailing: _Pill('Rejected', AppColors.danger),
          ),
        ),
      IdVerificationStatus.approved => _Card(
          child: _StateRow(
            icon: Icons.verified_outlined,
            tint: AppColors.success,
            label: 'ID verified',
            trailing: _Pill('Verified', AppColors.success),
          ),
        ),
    };
  }

  Widget _buildCapture(BuildContext context) {
    return _Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Not const: the title must pick up the theme's text color.
            Row(
              children: [
                _IconBox(icon: Icons.verified_user_outlined, tint: AppColors.primary),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Verify your ID', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                ),
                _Pill('Required', AppColors.warning),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: IdPhotoField(
                    label: 'Front',
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
                    label: 'Back',
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
                  const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 15),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(_error!, style: const TextStyle(fontSize: 12, color: AppColors.danger)),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            CustomButton(label: 'Submit', onPressed: _submit, loading: _loading),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small building blocks
// ---------------------------------------------------------------------------

/// Rounded soft-tinted icon container (app-wide visual language).
class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color tint;
  const _IconBox({required this.icon, required this.tint});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 17, color: tint),
    );
  }
}

/// Compact status pill — single word on a soft tint.
class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Quiet one-line state row used by non-capture verification states.
class _StateRow extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final String label;
  final Widget trailing;
  const _StateRow({
    required this.icon,
    required this.tint,
    required this.label,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          _IconBox(icon: icon, tint: tint),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ),
          trailing,
        ],
      ),
    );
  }
}

/// Appearance row — dark mode toggle. Tapping anywhere on the row toggles.
class _AppearanceTile extends StatelessWidget {
  final bool isDark;
  const _AppearanceTile({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final tint = isDark ? AppColors.gold : AppColors.primary;
    final appState = context.read<AppState>();
    return Pressable(
      onTap: () => appState.toggleDarkMode(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _IconBox(icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, tint: tint),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Appearance', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ),
            Switch.adaptive(
              value: isDark,
              onChanged: (_) => appState.toggleDarkMode(),
              activeTrackColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Settings row — icon, one-word label, chevron.
class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? tint;
  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final c = tint ?? AppColors.primary;
    return Pressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _IconBox(icon: icon, tint: c),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: tint ?? AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
