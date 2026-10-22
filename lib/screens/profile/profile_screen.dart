import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../data/api_service.dart';
import '../../models/user.dart';
import '../../state/app_state.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/id_upload_field.dart';
import '../../widgets/liquid_glass.dart';
import '../../widgets/pressable.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';

/// Profile screen — displays overall profile details, edit profile button,
/// ID verification status, and change password action.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return LiquidScaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: RefreshIndicator(
        onRefresh: () => appState.refreshProfile(),
        child: ListView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 60),
          children: [
            // ── Identity ───────────────────────────────────────────────────
            const SizedBox(height: 8),
            _IdentityHeader(user: user),
            const SizedBox(height: 28),

            // ── Overall Profile Details ────────────────────────────────────
            const _SectionLabel('Overall Profile'),
            const SizedBox(height: 8),
            _Card(
              child: Column(
                children: [
                  _LabeledDetailRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Full Name',
                    value: user.fullName,
                  ),
                  const Divider(height: 1, indent: 46),
                  _LabeledDetailRow(
                    icon: Icons.alternate_email_rounded,
                    label: 'Username',
                    value: user.username.isEmpty ? '—' : '@${user.username}',
                  ),
                  const Divider(height: 1, indent: 46),
                  _LabeledDetailRow(
                    icon: Icons.badge_outlined,
                    label: 'Student ID',
                    value: user.idNumber.trim().isEmpty
                        ? 'No Student ID set (00-000000)'
                        : user.idNumber,
                    muted: user.idNumber.trim().isEmpty,
                  ),
                  const Divider(height: 1, indent: 46),
                  _LabeledDetailRow(
                    icon: Icons.mail_outline_rounded,
                    label: 'Email Address',
                    value: user.email,
                  ),
                  const Divider(height: 1, indent: 46),
                  _LabeledDetailRow(
                    icon: Icons.phone_outlined,
                    label: 'Contact Number',
                    value: user.contactNumber.isEmpty
                        ? '—'
                        : user.contactNumber,
                    muted: user.contactNumber.isEmpty,
                  ),
                  const Divider(height: 1, indent: 46),
                  _LabeledDetailRow(
                    icon: Icons.school_outlined,
                    label: 'Role & Status',
                    value: '${user.userType.label} • ${user.accountStatus}',
                  ),
                  const Divider(height: 1, indent: 46),
                  _SettingsRow(
                    icon: Icons.edit_outlined,
                    label: 'Edit Profile',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const EditProfileScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── ID verification (state-aware) ──────────────────────────────
            const _SectionLabel('Verification Status'),
            const SizedBox(height: 8),
            _VerificationCard(status: appState.idVerificationStatus),
            const SizedBox(height: 24),

            // ── Security (Change Password) ─────────────────────────────────
            const _SectionLabel('Security'),
            const SizedBox(height: 8),
            _Card(
              child: _SettingsRow(
                icon: Icons.lock_outline_rounded,
                label: 'Change Password',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ChangePasswordScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Identity header — avatar (with photo picker), adjacent edit icon button,
// name, role + status pill.
// ---------------------------------------------------------------------------
class _IdentityHeader extends StatefulWidget {
  final AppUser user;
  const _IdentityHeader({required this.user});

  @override
  State<_IdentityHeader> createState() => _IdentityHeaderState();
}

class _IdentityHeaderState extends State<_IdentityHeader> {
  bool _uploadingPhoto = false;

  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final file = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (file == null || !mounted) return;
      setState(() => _uploadingPhoto = true);
      final error = await context.read<AppState>().updateProfilePhoto(
        file.path,
      );
      if (!mounted) return;
      setState(() => _uploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Profile picture updated!'),
          backgroundColor: error != null ? AppColors.danger : null,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _uploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not select photo. Please try again.'),
        ),
      );
    }
  }

  void _showAvatarOptions() {
    showGlassSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const GlassSheetHandle(),
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 10, bottom: 8),
              child: Text(
                'Profile Picture',
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const _IconBox(
                icon: Icons.photo_library_outlined,
                tint: AppColors.primary,
              ),
              title: const Text(
                'Choose from Gallery',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickAndUploadAvatar(ImageSource.gallery);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const _IconBox(
                icon: Icons.photo_camera_outlined,
                tint: AppColors.primary,
              ),
              title: const Text(
                'Take a Photo',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickAndUploadAvatar(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final verified = user.isIdVerified;
    final hasAvatar = user.avatarUrl != null && user.avatarUrl!.isNotEmpty;

    return GlassPanel(
      blur: 22,
      strong: true,
      radius: AppRadius.xl,
      shadows: AppShadows.floating,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Spacer balances the edit button on the right so the avatar
              // remains centered in the header card.
              const SizedBox(width: 48),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  GestureDetector(
                    onTap: _uploadingPhoto ? null : _showAvatarOptions,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.premiumGradient,
                        boxShadow: AppShadows.primaryGlow,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surface,
                        ),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.primarySoft,
                          child: _uploadingPhoto
                              ? const SizedBox(
                                  width: 26,
                                  height: 26,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: AppColors.primary,
                                  ),
                                )
                              : hasAvatar
                              ? ClipOval(
                                  child: Image.network(
                                    user.avatarUrl!,
                                    headers: ApiConfig.mediaHeaders,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Text(
                                      user.initials,
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 27,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                )
                              : Text(
                                  user.initials,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 27,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                  // Camera badge on bottom-left of avatar to add/change photo
                  Positioned(
                    left: -2,
                    bottom: 2,
                    child: GestureDetector(
                      onTap: _uploadingPhoto ? null : _showAvatarOptions,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: AppShadows.soft,
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 13,
                          color: AppColors.onPrimary,
                        ),
                      ),
                    ),
                  ),
                  if (verified)
                    Positioned(
                      right: 0,
                      bottom: 2,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          boxShadow: AppShadows.soft,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 12,
                          color: AppColors.onPrimary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              // Edit Profile icon button right beside the profile circle
              GlassIconButton(
                icon: Icons.edit_outlined,
                tooltip: 'Edit Profile',
                size: 38,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            user.fullName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.45,
            ),
          ),
          const SizedBox(height: 9),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  user.userType.label,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _StatusDot(status: user.accountStatus),
              const SizedBox(width: 5),
              Text(
                user.accountStatus,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
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
// Section label — small caps, whisper-quiet.
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
          color: AppColors.textTertiaryFor(Theme.of(context).brightness),
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
    return GlassCard(
      padding: EdgeInsets.zero,
      radius: AppRadius.lg,
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Labeled detail row — icon + label + value for overall profile clarity.
// ---------------------------------------------------------------------------
class _LabeledDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool muted;

  const _LabeledDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textTertiary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: muted ? FontWeight.w500 : FontWeight.w600,
                    fontSize: 14,
                    color: muted ? AppColors.textTertiary : null,
                  ),
                ),
              ],
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
      setState(
        () => _error = 'Add photos of both sides of your ID to continue.',
      );
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
      if (error == null) {
        _idFrontPath = null;
        _idBackPath = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return switch (widget.status) {
      IdVerificationStatus.notSubmitted ||
      IdVerificationStatus.rejected => _buildCapture(context),
      IdVerificationStatus.pending => const _Card(
        child: _StateRow(
          icon: Icons.hourglass_top_rounded,
          tint: AppColors.warning,
          label: 'Under review',
          trailing: _Pill('Pending', AppColors.warning),
        ),
      ),
      IdVerificationStatus.approved => const _Card(
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
    final rejectionReason = context
        .watch<AppState>()
        .currentUser
        ?.idRejectionReason;
    return _Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                _IconBox(
                  icon: Icons.verified_user_outlined,
                  tint: AppColors.primary,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Verify your ID',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
                _Pill('Required', AppColors.warning),
              ],
            ),
            const SizedBox(height: 14),
            if (widget.status == IdVerificationStatus.rejected) ...[
              Text(
                'ID verification rejected. Reason: ${rejectionReason ?? 'Please submit new ID photos.'}',
                style: const TextStyle(color: AppColors.danger, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Text(
                'Add new front and back photos of your ID and submit them for review.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 14),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: IdPhotoField(
                    label: 'Front',
                    imagePath: _idFrontPath,
                    onChanged: (p) => setState(() {
                      _idFrontPath = p;
                      if (_idFrontPath != null && _idBackPath != null) {
                        _error = null;
                      }
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
                      if (_idFrontPath != null && _idBackPath != null) {
                        _error = null;
                      }
                    }),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.danger,
                    size: 15,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            CustomButton(
              label: widget.status == IdVerificationStatus.rejected
                  ? 'Resubmit ID'
                  : 'Submit',
              onPressed: _submit,
              loading: _loading,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small building blocks
// ---------------------------------------------------------------------------

/// Clean icon wrapper without background box.
class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color tint;
  const _IconBox({required this.icon, required this.tint});

  @override
  Widget build(BuildContext context) {
    return Icon(icon, size: 20, color: tint);
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
        color: color.withValues(alpha: 0.14),
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
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

/// Settings row — icon, label, chevron.
class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const c = AppColors.primary;
    return Pressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            const _IconBox(icon: Icons.lock_outline_rounded, tint: c).icon ==
                    icon
                ? const _IconBox(icon: Icons.lock_outline_rounded, tint: c)
                : _IconBox(icon: icon, tint: c),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
