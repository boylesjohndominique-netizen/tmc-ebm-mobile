import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../app/motion.dart';
import '../app/theme.dart';
import 'liquid_glass.dart';

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

  Future<void> _selectPhoto(BuildContext context) async {
    final source = await showGlassSheet<ImageSource>(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const GlassSheetHandle(),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Take a photo'),
            onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
    if (source == null || !context.mounted) return;

    final picker = ImagePicker();
    try {
      final photo = await picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 80,
      );
      if (photo != null && context.mounted) {
        onChanged(photo.path);
      }
    } catch (_) {
      // Source unavailable or permission denied — keep current state; the
      // slot stays tappable so the user can retry.
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              source == ImageSource.camera
                  ? 'Could not open the camera. Please try again.'
                  : 'Could not open the gallery. Please try again.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _confirmRemove(BuildContext context) async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove photo?'),
        content: Text(
          'The $label photo will be removed from your registration.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
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
          onTap: () => _selectPhoto(context),
          child: AnimatedContainer(
            duration: AppMotion.responsive(context, AppMotion.normal),
            curve: AppMotion.emphasized,
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: errorText != null
                  ? AppColors.danger.withValues(alpha: 0.08)
                  : AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: AppShadows.soft,
            ),
            child: hasImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
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
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black54],
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.success,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                const Expanded(
                                  child: Text(
                                    'Selected',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                _IconAction(
                                  icon: Icons.refresh_rounded,
                                  tooltip: 'Change photo',
                                  onTap: () => _selectPhoto(context),
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
                      const Icon(
                        Icons.photo_camera_outlined,
                        color: AppColors.primary,
                        size: 28,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        hint ?? 'Tap to add a photo',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Camera or gallery',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.danger,
                size: 14,
              ),
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
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Icon(
              icon,
              size: 18,
              color: danger ? const Color(0xFFFFB4AE) : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
