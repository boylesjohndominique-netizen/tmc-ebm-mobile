import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../app/motion.dart';
import '../app/theme.dart';

/// A tappable capture slot for one side of an ID (front or back).
///
/// Shows an upload target when empty and a photo preview with retake/remove
/// actions once a picture has been taken. Validation is driven by the parent
/// through [errorText] (e.g. via a [FormField] wrapper).
class IdPhotoField extends StatelessWidget {
  final String label;
  final String? hint;
  final String? imagePath;
  final String? errorText;
  final ValueChanged<String?> onChanged;

  const IdPhotoField({
    super.key,
    required this.label,
    required this.onChanged,
    this.hint,
    this.imagePath,
    this.errorText,
  });

  Future<void> _capture(BuildContext context) async {
    final picker = ImagePicker();
    try {
      final photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        imageQuality: 80,
      );
      if (photo != null) {
        onChanged(photo.path);
      }
    } catch (_) {
      // Camera unavailable or permission denied — keep current state; the
      // slot stays tappable so the user can retry.
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not open the camera. Please try again.')),
        );
      }
    }
  }

  Future<void> _confirmRemove(BuildContext context) async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove photo?'),
        content:
            Text('The $label photo will be removed from your registration.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (remove == true) onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null;
    final borderColor = errorText != null
        ? AppColors.danger.withValues(alpha: 0.55)
        : AppColors.divider;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _capture(context),
          child: AnimatedContainer(
            duration: AppMotion.responsive(context, AppMotion.normal),
            curve: AppMotion.emphasized,
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: hasImage ? null : AppColors.glassSheen,
              color: hasImage ? Colors.black.withValues(alpha: 0.03) : null,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: hasImage
                    ? AppColors.primary.withValues(alpha: 0.4)
                    : (errorText != null ? borderColor : AppColors.glassBorder),
                width: hasImage ? 1.6 : 1.2,
              ),
              boxShadow: hasImage ? null : AppShadows.soft,
            ),
            child: hasImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.lg - 1),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(File(imagePath!), fit: BoxFit.cover),
                        // Bottom scrim with capture status + actions.
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black54],
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded,
                                    color: AppColors.success, size: 18),
                                const SizedBox(width: 6),
                                const Expanded(
                                  child: Text(
                                    'Captured',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                                _IconAction(
                                  icon: Icons.refresh_rounded,
                                  tooltip: 'Retake',
                                  onTap: () => _capture(context),
                                ),
                                const SizedBox(width: 4),
                                _IconAction(
                                  icon: Icons.delete_outline_rounded,
                                  tooltip: 'Remove',
                                  danger: true,
                                  onTap: () => _confirmRemove(context),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.photo_camera_outlined,
                              color: AppColors.primary, size: 22),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        hint ?? 'Tap to take a photo',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Camera will open — make sure all text is readable',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textTertiary),
                      ),
                    ],
                  ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppColors.danger, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  errorText!,
                  style: const TextStyle(fontSize: 12, color: AppColors.danger),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool danger;
  final VoidCallback onTap;

  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.22),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Icon(
              icon,
              size: 16,
              color: danger ? const Color(0xFFFFB4AE) : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
