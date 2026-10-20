import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../data/api_service.dart';
import '../../models/equipment.dart';
import '../../state/app_state.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/equipment_icon.dart';
import '../../widgets/liquid_glass.dart';
import '../../widgets/pressable.dart';
import '../borrowing/request_equipment_screen.dart';

class EquipmentDetailsScreen extends StatefulWidget {
  final String equipmentId;
  const EquipmentDetailsScreen({super.key, required this.equipmentId});

  @override
  State<EquipmentDetailsScreen> createState() => _EquipmentDetailsScreenState();
}

class _EquipmentDetailsScreenState extends State<EquipmentDetailsScreen> {
  @override
  void initState() {
    super.initState();
    // Keep stock counters fresh when arriving from the dashboard.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().refreshEquipment();
    });
  }

  void _openPhotoViewer(Equipment equipment, int initialIndex) {
    final photos = equipment.allPhotos;
    if (photos.isEmpty) return;

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (ctx, animation, _) => FadeTransition(
          opacity: animation,
          child: _EquipmentPhotoViewerDialog(
            equipmentName: equipment.name,
            photos: photos,
            hasMainPhoto:
                equipment.imageUrl != null && equipment.imageUrl!.isNotEmpty,
            initialIndex: initialIndex.clamp(0, photos.length - 1),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final equipment = appState.equipmentById(widget.equipmentId);

    if (equipment == null) {
      return LiquidScaffold(
        appBar: AppBar(title: const Text('Equipment Details')),
        body: const Center(child: Text('Equipment not found.')),
      );
    }

    final statusColor = switch (equipment.availabilityStatus) {
      'Available' => AppColors.success,
      'Limited' => AppColors.warning,
      _ => AppColors.danger,
    };
    final pending = appState.currentUser?.isPending == true;
    final canRequest = equipment.isAvailable && !pending;
    final hasMainPhoto =
        equipment.imageUrl != null && equipment.imageUrl!.isNotEmpty;
    final galleryPhotos = equipment.galleryUrls;
    final allPhotos = equipment.allPhotos;

    return LiquidScaffold(
      extendBody: true,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 130),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Hero(
              equipment: equipment,
              statusColor: statusColor,
              onBack: () => Navigator.of(context).maybePop(),
              onTapHeroPhoto: allPhotos.isNotEmpty
                  ? () => _openPhotoViewer(equipment, 0)
                  : null,
            ),
            Transform.translate(
              offset: const Offset(0, -24),
              child: _BodySheet(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Spec chips ──────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _SpecChip(
                            icon: Icons.check_circle_outline_rounded,
                            label: equipment.condition.label,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _SpecChip(
                            icon: Icons.inventory_2_outlined,
                            label: '${equipment.availableQuantity} left',
                            color: AppColors.gold,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _SpecChip(
                            icon: Icons.circle,
                            iconSize: 9,
                            label: equipment.availabilityStatus,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 26),

                    // ── About ────────────────────────────────────────────
                    if (equipment.description.trim().isNotEmpty) ...[
                      const GlassSectionLabel('About'),
                      const SizedBox(height: 10),
                      Text(
                        equipment.description,
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(height: 1.6),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // ── Description / Gallery Pictures ───────────────────
                    if (galleryPhotos.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const GlassSectionLabel('More Pictures'),
                          Text(
                            '${galleryPhotos.length} ${galleryPhotos.length == 1 ? 'photo' : 'photos'} · Tap to zoom',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 112,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          clipBehavior: Clip.none,
                          itemCount: galleryPhotos.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, idx) {
                            final photoUrl = galleryPhotos[idx];
                            final viewerIdx = hasMainPhoto ? idx + 1 : idx;
                            return Pressable(
                              onTap: () =>
                                  _openPhotoViewer(equipment, viewerIdx),
                              child: GlassPanel(
                                blur: 14,
                                radius: 18,
                                padding: const EdgeInsets.all(3),
                                shadows: AppShadows.soft,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: SizedBox(
                                    width: 144,
                                    height: 106,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.network(
                                          photoUrl,
                                          headers: ApiConfig.mediaHeaders,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              Container(
                                            color: AppColors.primarySoft,
                                            child: const Icon(
                                              Icons.broken_image_outlined,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          right: 7,
                                          bottom: 7,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 7,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.black
                                                  .withValues(alpha: 0.56),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      AppRadius.pill),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.fullscreen_rounded,
                                                  size: 13,
                                                  color: Colors.white,
                                                ),
                                                const SizedBox(width: 3),
                                                Text(
                                                  '${idx + 1}/${galleryPhotos.length}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 26),
                    ],

                    // ── Availability card with stock bar ─────────────────
                    GlassCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text('Availability',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                              ),
                              Text(
                                '${equipment.availableQuantity}/${equipment.totalQuantity}',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 13),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            child: LinearProgressIndicator(
                              value: equipment.totalQuantity == 0
                                  ? 0
                                  : equipment.availableQuantity /
                                      equipment.totalQuantity,
                              minHeight: 8,
                              backgroundColor:
                                  AppColors.divider.withValues(alpha: 0.55),
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(statusColor),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'of total units',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // ── Approval note / Verification status ──────────────
                    if (pending) ...[
                      GlassPanel(
                        blur: 0,
                        radius: AppRadius.md,
                        padding: const EdgeInsets.all(14),
                        shadows: AppShadows.soft,
                        tint: AppColors.warning
                            .withValues(alpha: AppColors.isDark ? 0.16 : 0.10),
                        borderColor: AppColors.warning.withValues(alpha: 0.32),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.lock_outline_rounded,
                                color: Color(0xFFD97706), size: 19),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Account Not Verified — you can view equipment, but borrowing requires administrator verification of your ID.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  height: 1.5,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else ...[
                      Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 15, color: AppColors.textTertiary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Requests are reviewed by the Equipment Office.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        child: GlassPanel(
          blur: 28,
          strong: true,
          radius: AppRadius.xl,
          shadows: AppShadows.floating,
          padding: const EdgeInsets.all(10),
          child: CustomButton(
            label: pending
                ? 'Verification Required to Borrow'
                : (equipment.isAvailable
                    ? 'Request Equipment'
                    : 'Currently Unavailable'),
            icon: pending
                ? Icons.lock_outline_rounded
                : Icons.add_circle_outline_rounded,
            onPressed: canRequest
                ? () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            RequestEquipmentScreen(equipmentId: equipment.id),
                      ),
                    )
                : null,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Gradient hero with floating glass back control and product tile.
// ---------------------------------------------------------------------------
class _Hero extends StatelessWidget {
  final Equipment equipment;
  final Color statusColor;
  final VoidCallback onBack;
  final VoidCallback? onTapHeroPhoto;

  const _Hero({
    required this.equipment,
    required this.statusColor,
    required this.onBack,
    this.onTapHeroPhoto,
  });

  @override
  Widget build(BuildContext context) {
    final totalPhotos = equipment.allPhotos.length;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.premiumGradient,
        boxShadow: AppShadows.primaryGlow,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(38)),
        child: Stack(
          children: [
            Positioned(
              top: -80,
              right: -70,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.20),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 20, 34),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GlassIconButton(
                          icon: Icons.arrow_back_rounded,
                          tooltip: 'Back',
                          iconColor: Colors.white,
                          tint: Colors.white.withValues(alpha: 0.16),
                          borderColor: Colors.white.withValues(alpha: 0.26),
                          onTap: onBack,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: GestureDetector(
                        onTap: onTapHeroPhoto,
                        child: GlassPanel(
                          blur: 22,
                          radius: 34,
                          padding: const EdgeInsets.all(4),
                          tint: Colors.white.withValues(alpha: 0.14),
                          borderColor: Colors.white.withValues(alpha: 0.28),
                          shadows: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 30,
                              offset: const Offset(0, 16),
                            ),
                          ],
                          child: Container(
                            width: 228,
                            height: 164,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withValues(alpha: 0.20),
                                  Colors.white.withValues(alpha: 0.05),
                                ],
                              ),
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                EquipmentVisual(
                                  equipment: equipment,
                                  iconSize: 74,
                                  iconColor:
                                      Colors.white.withValues(alpha: 0.94),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                if (totalPhotos > 0)
                                  Positioned(
                                    right: 10,
                                    bottom: 10,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 9,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black
                                            .withValues(alpha: 0.55),
                                        borderRadius: BorderRadius.circular(
                                            AppRadius.pill),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.photo_library_outlined,
                                            size: 12,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '$totalPhotos ${totalPhotos == 1 ? 'photo' : 'photos'}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            equipment.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 27,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.7,
                              height: 1.12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.pill),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.22),
                                  ),
                                ),
                                child: Text(
                                  equipment.category,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.92),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                equipment.availabilityStatus,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.82),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
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
// Full-screen interactive zoomable photo viewer for main + description photos.
// ---------------------------------------------------------------------------
class _EquipmentPhotoViewerDialog extends StatefulWidget {
  final String equipmentName;
  final List<String> photos;
  final bool hasMainPhoto;
  final int initialIndex;

  const _EquipmentPhotoViewerDialog({
    required this.equipmentName,
    required this.photos,
    required this.hasMainPhoto,
    required this.initialIndex,
  });

  @override
  State<_EquipmentPhotoViewerDialog> createState() =>
      _EquipmentPhotoViewerDialogState();
}

class _EquipmentPhotoViewerDialogState
    extends State<_EquipmentPhotoViewerDialog> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _captionFor(int index) {
    if (widget.hasMainPhoto) {
      if (index == 0) return 'Main Profile Picture';
      return 'Description Photo $index';
    }
    return 'Description Photo ${index + 1}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.92),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.equipmentName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_captionFor(_currentIndex)}  ·  ${_currentIndex + 1} of ${widget.photos.length}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.photos.length,
                onPageChanged: (idx) => setState(() => _currentIndex = idx),
                itemBuilder: (context, idx) {
                  return InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 4.0,
                    child: Center(
                      child: Image.network(
                        widget.photos[idx],
                        headers: ApiConfig.mediaHeaders,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white54,
                          size: 64,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (widget.photos.length > 1)
              SizedBox(
                height: 76,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: widget.photos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, idx) {
                    final selected = idx == _currentIndex;
                    return GestureDetector(
                      onTap: () => _pageController.animateToPage(
                        idx,
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOutCubic,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected ? AppColors.gold : Colors.white24,
                            width: selected ? 2.5 : 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(9.5),
                          child: Image.network(
                            widget.photos[idx],
                            headers: ApiConfig.mediaHeaders,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Frosted body sheet that overlaps the hero.
// ---------------------------------------------------------------------------
class _BodySheet extends StatelessWidget {
  final Widget child;
  const _BodySheet({required this.child});

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.vertical(top: Radius.circular(34));
    return Container(
      decoration: const BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 30,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.surface
                      .withValues(alpha: AppColors.isDark ? 0.90 : 0.92),
                  AppColors.background
                      .withValues(alpha: AppColors.isDark ? 0.94 : 0.96),
                ],
              ),
              border: Border(
                top: BorderSide(color: AppColors.glassBorder, width: 1),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Spec chip — small tinted glass square icon + label.
// ---------------------------------------------------------------------------
class _SpecChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final double? iconSize;

  const _SpecChip({
    required this.icon,
    required this.label,
    required this.color,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      blur: 0,
      radius: AppRadius.md,
      padding: EdgeInsets.zero,
      shadows: AppShadows.soft,
      tint: color.withValues(alpha: 0.10),
      borderColor: color.withValues(alpha: 0.18),
      child: SizedBox(
        height: 62,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: iconSize ?? 16, color: color),
              const SizedBox(height: 5),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
