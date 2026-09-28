import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../models/equipment.dart';
import '../../state/app_state.dart';
import '../../widgets/equipment_icon.dart';
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

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final equipment = appState.equipmentById(widget.equipmentId);

    if (equipment == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Equipment Details')),
        body: const Center(child: Text('Equipment not found.')),
      );
    }

    final statusColor = switch (equipment.availabilityStatus) {
      'Available' => AppColors.success,
      'Limited' => AppColors.warning,
      _ => AppColors.danger,
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero header — full-width image placeholder ────────────────
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
              child: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                      child: Row(
                        children: [
                          _HeroIconButton(
                            icon: Icons.arrow_back_rounded,
                            onTap: () => Navigator.of(context).maybePop(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Full-bleed image slot — swap for Image.network once the
                    // backend serves equipment photos.
                    Center(
                      child: Container(
                        width: 240,
                        height: 170,
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          border:
                              Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Icon(
                          equipmentIcon('${equipment.category} ${equipment.name}'),
                          size: 72,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 10, 24, 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  equipment.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                    height: 1.15,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.6),
                                      width: 1.5),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            equipment.category,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Body sheet ────────────────────────────────────────────────
            Transform.translate(
              offset: const Offset(0, -16),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Spec chips ────────────────────────────────────────
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
                            icon: Icons.circle_outlined,
                            iconSize: 12,
                            label: equipment.availabilityStatus,
                            iconColorOverride: statusColor,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── About ─────────────────────────────────────────────
                    if (equipment.description.trim().isNotEmpty) ...[
                      Text('About', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 10),
                      Text(
                        equipment.description,
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(height: 1.55),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // ── Availability card with stock bar ──────────────────
                    Container(
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
                              Expanded(
                                child: Text('Availability',
                                    style: Theme.of(context).textTheme.titleMedium),
                              ),
                              Text(
                                '${equipment.availableQuantity}/${equipment.totalQuantity}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: equipment.totalQuantity == 0
                                  ? 0
                                  : equipment.availableQuantity / equipment.totalQuantity,
                              minHeight: 6,
                              backgroundColor: AppColors.divider.withValues(alpha: 0.7),
                              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                            ),
                          ),
                          const SizedBox(height: 6),
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
                    const SizedBox(height: 24),

                    // ── Approval note / Verification status ──────────────
                    if (appState.currentUser?.isPending == true) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.35)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.lock_outline_rounded,
                                color: Color(0xFFD97706), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Account Not Verified: You can view equipment, but borrowing requires administrator verification of your ID.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).textTheme.bodySmall?.color,
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
                      const SizedBox(height: 20),
                    ],

                    // ── CTA ───────────────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (equipment.isAvailable && appState.currentUser?.isPending != true)
                              ? AppColors.primary
                              : AppColors.surfaceMuted,
                          foregroundColor: (equipment.isAvailable && appState.currentUser?.isPending != true)
                              ? Colors.white
                              : AppColors.textTertiary,
                        ),
                        onPressed: (equipment.isAvailable && appState.currentUser?.isPending != true)
                            ? () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) => RequestEquipmentScreen(
                                          equipmentId: equipment.id)),
                                )
                            : null,
                        icon: Icon(
                          appState.currentUser?.isPending == true
                              ? Icons.lock_outline_rounded
                              : Icons.add_circle_outline_rounded,
                          size: 20,
                        ),
                        label: Text(
                          appState.currentUser?.isPending == true
                              ? 'Verification Required to Borrow'
                              : (equipment.isAvailable ? 'Request' : 'Unavailable'),
                        ),
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
// Hero header icon button — frosted square.
// ---------------------------------------------------------------------------
class _HeroIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _HeroIconButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Spec chip — small tinted square icon + label.
// ---------------------------------------------------------------------------
class _SpecChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color? iconColorOverride;
  final double? iconSize;

  const _SpecChip({
    required this.icon,
    required this.label,
    required this.color,
    this.iconColorOverride,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: iconSize ?? 15, color: iconColorOverride ?? color),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
