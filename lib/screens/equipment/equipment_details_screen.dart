import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/motion.dart';
import '../../app/theme.dart';
import '../../data/api_service.dart';
import '../../models/equipment.dart';
import '../../state/app_state.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/equipment_icon.dart';
import '../../widgets/equipment_borrowing_info.dart';
import '../../widgets/liquid_glass.dart';
import '../../widgets/pressable.dart';
import '../../widgets/status_badge.dart';
import '../borrowing/request_equipment_screen.dart';

class EquipmentDetailsScreen extends StatefulWidget {
  final String equipmentId;
  const EquipmentDetailsScreen({super.key, required this.equipmentId});

  @override
  State<EquipmentDetailsScreen> createState() => _EquipmentDetailsScreenState();
}

class _EquipmentDetailsScreenState extends State<EquipmentDetailsScreen> {
  final PageController _photoController = PageController();
  int _activePhotoIndex = 0;

  @override
  void initState() {
    super.initState();
    // Keep stock counters fresh when arriving from the dashboard or list.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppState>().refreshEquipment();
    });
  }

  @override
  void dispose() {
    _photoController.dispose();
    super.dispose();
  }

  void _selectPhoto(int index) {
    setState(() => _activePhotoIndex = index);
    if (_photoController.hasClients) {
      _photoController.animateToPage(
        index,
        duration: AppMotion.normal,
        curve: AppMotion.emphasized,
      );
    }
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
        body: const EmptyState(
          icon: Icons.inventory_2_outlined,
          title: 'Equipment not found',
          subtitle: 'This item may have been removed or is no longer listed.',
        ),
      );
    }

    final statusColor = switch (equipment.availabilityStatus) {
      'Available' => AppColors.success,
      'Limited' => AppColors.warning,
      _ => AppColors.danger,
    };
    final conditionColor = switch (equipment.condition) {
      EquipmentCondition.excellent => AppColors.success,
      EquipmentCondition.good => AppColors.primary,
      EquipmentCondition.fair => AppColors.warning,
    };
    final pending = appState.currentUser?.isPending == true;
    final canRequest = equipment.isAvailable && !pending;
    final allPhotos = equipment.allPhotos;
    final safePhotoIndex = allPhotos.isEmpty
        ? 0
        : _activePhotoIndex.clamp(0, allPhotos.length - 1);
    final inUseCount = (equipment.totalQuantity - equipment.availableQuantity)
        .clamp(0, equipment.totalQuantity);
    final stockRatio = equipment.totalQuantity <= 0
        ? 0.0
        : (equipment.availableQuantity / equipment.totalQuantity).clamp(
            0.0,
            1.0,
          );

    return LiquidScaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Equipment Details'),
      ),
      body: RefreshIndicator(
        backgroundColor: AppColors.surface,
        color: AppColors.primary,
        onRefresh: () => appState.refreshEquipment(),
        child: ListView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            // ── Hero Card: Visual Showcase + Identity ──────────────────────
            GlassPanel(
              blur: 22,
              strong: true,
              radius: AppRadius.xl,
              shadows: AppShadows.floating,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (allPhotos.isNotEmpty) ...[
                    _VisualShowcase(
                      equipment: equipment,
                      photos: allPhotos,
                      activeIndex: safePhotoIndex,
                      controller: _photoController,
                      onPageChanged: (idx) =>
                          setState(() => _activePhotoIndex = idx),
                      onTapPhoto: () =>
                          _openPhotoViewer(equipment, safePhotoIndex),
                    ),
                    if (allPhotos.length > 1) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 54,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: allPhotos.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, idx) {
                            final selected = idx == safePhotoIndex;
                            return Pressable(
                              onTap: () => _selectPhoto(idx),
                              child: AnimatedContainer(
                                duration: AppMotion.fast,
                                width: 68,
                                height: 54,
                                padding: EdgeInsets.all(selected ? 2 : 0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selected
                                        ? AppColors.primary
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    selected ? 9 : 11,
                                  ),
                                  child: Image.network(
                                    allPhotos[idx],
                                    headers: ApiConfig.mediaHeaders,
                                    fit: BoxFit.cover,
                                    cacheWidth: 204,
                                    filterQuality: FilterQuality.medium,
                                    opacity: AlwaysStoppedAnimation<double>(
                                      selected ? 1.0 : 0.65,
                                    ),
                                    errorBuilder: (_, __, ___) => ColoredBox(
                                      color: AppColors.surfaceMuted,
                                      child: const Center(
                                        child: Icon(
                                          Icons.broken_image_outlined,
                                          size: 18,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (allPhotos.isEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 2, right: 14),
                          child: Icon(
                            equipmentIcon(
                              '${equipment.category} ${equipment.name}',
                            ),
                            size: 38,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primarySoft,
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.pill,
                                    ),
                                  ),
                                  child: Text(
                                    equipment.category,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                StatusBadge.availability(
                                  equipment.availabilityStatus,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              equipment.name,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                    height: 1.2,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Stock & Specifications Card ────────────────────────────────
            const GlassSectionLabel('Inventory & Condition'),
            EquipmentBorrowingInfo(equipment: equipment),
            const SizedBox(height: 16),
            const SizedBox(height: 8),
            GlassCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _MetricColumn(
                          icon: Icons.verified_outlined,
                          iconColor: conditionColor,
                          label: 'Condition',
                          value: equipment.condition.label,
                          valueColor: conditionColor,
                        ),
                      ),
                      _verticalDivider(),
                      Expanded(
                        child: _MetricColumn(
                          icon: Icons.check_circle_outline_rounded,
                          iconColor: statusColor,
                          label: 'Available',
                          value:
                              '${equipment.availableQuantity} ${equipment.availableQuantity == 1 ? 'unit' : 'units'}',
                          valueColor: statusColor,
                        ),
                      ),
                      _verticalDivider(),
                      Expanded(
                        child: _MetricColumn(
                          icon: Icons.inventory_2_outlined,
                          iconColor: AppColors.primary,
                          label: 'Total Stock',
                          value:
                              '${equipment.totalQuantity} ${equipment.totalQuantity == 1 ? 'unit' : 'units'}',
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(height: 1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Live Availability',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        inUseCount > 0
                            ? '$inUseCount currently borrowed'
                            : 'All units in stock',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: LinearProgressIndicator(
                      value: stockRatio,
                      minHeight: 8,
                      backgroundColor: AppColors.divider.withValues(
                        alpha: 0.55,
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── About / Description Section ────────────────────────────────
            const GlassSectionLabel('About This Equipment'),
            const SizedBox(height: 8),
            GlassCard(
              padding: const EdgeInsets.all(18),
              child: Text(
                equipment.description.trim().isNotEmpty
                    ? equipment.description.trim()
                    : 'No additional description provided for this equipment.',
                style: equipment.description.trim().isNotEmpty
                    ? Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(height: 1.55)
                    : Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textTertiary,
                        fontStyle: FontStyle.italic,
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Verification / Borrowing Note ──────────────────────────────
            if (pending)
              GlassPanel(
                blur: 0,
                radius: AppRadius.lg,
                padding: const EdgeInsets.all(14),
                shadows: AppShadows.card,
                tint: AppColors.goldSoft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.lock_outline_rounded,
                        color: AppColors.warning,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Account Not Verified — you can view equipment details, but borrowing requires administrator verification of your school ID in Profile.',
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.45,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              GlassCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Requests are reviewed by the Equipment Office. Please present your school ID upon pickup.',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: CustomButton(
          label: pending
              ? 'Verification Required to Borrow'
              : (equipment.isAvailable
                    ? 'Request Equipment'
                    : 'Currently Unavailable'),
          icon: pending
              ? Icons.lock_outline_rounded
              : (equipment.isAvailable
                    ? Icons.assignment_add
                    : Icons.block_rounded),
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
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: AppColors.divider.withValues(alpha: 0.65),
    );
  }
}

// ---------------------------------------------------------------------------
// Visual Showcase — swipeable photo gallery or clean gradient icon stage.
// ---------------------------------------------------------------------------
class _VisualShowcase extends StatelessWidget {
  final Equipment equipment;
  final List<String> photos;
  final int activeIndex;
  final PageController controller;
  final ValueChanged<int> onPageChanged;
  final VoidCallback? onTapPhoto;

  const _VisualShowcase({
    required this.equipment,
    required this.photos,
    required this.activeIndex,
    required this.controller,
    required this.onPageChanged,
    this.onTapPhoto,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.lg);

    return GestureDetector(
      onTap: onTapPhoto,
      child: ClipRRect(
        borderRadius: radius,
        child: SizedBox(
          height: 210,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                controller: controller,
                itemCount: photos.length,
                onPageChanged: onPageChanged,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  return Image.network(
                    photos[index],
                    headers: ApiConfig.mediaHeaders,
                    fit: BoxFit.cover,
                    loadingBuilder: (ctx, child, progress) {
                      if (progress == null) return child;
                      return ColoredBox(
                        color: AppColors.surfaceMuted,
                        child: const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.2),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => ColoredBox(
                      color: AppColors.primarySoft,
                      child: Center(
                        child: Icon(
                          equipmentIcon(
                            '${equipment.category} ${equipment.name}',
                          ),
                          size: 56,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                right: 10,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.60),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.zoom_out_map_rounded,
                        size: 13,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        photos.length > 1
                            ? '${activeIndex + 1} / ${photos.length}'
                            : 'Tap to zoom',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
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
    );
  }
}

// ---------------------------------------------------------------------------
// Metric column inside Inventory & Condition card.
// ---------------------------------------------------------------------------
class _MetricColumn extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color? valueColor;

  const _MetricColumn({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            maxLines: 1,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: valueColor ?? AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
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
      if (index == 0) return 'Main Picture';
      return 'Gallery Photo $index';
    }
    return 'Photo ${index + 1}';
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
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
                        padding: EdgeInsets.all(selected ? 2.5 : 0),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.gold : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(9.5),
                          child: Image.network(
                            widget.photos[idx],
                            headers: ApiConfig.mediaHeaders,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const ColoredBox(
                              color: Colors.white12,
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: Colors.white54,
                                size: 20,
                              ),
                            ),
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
