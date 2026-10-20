import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../models/equipment.dart';
import 'equipment_icon.dart';
import 'liquid_glass.dart';
import 'pressable.dart';
import 'status_badge.dart';

class EquipmentCard extends StatelessWidget {
  final Equipment equipment;
  final VoidCallback onTap;

  const EquipmentCard(
      {super.key, required this.equipment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primarySoft,
                    AppColors.primarySoft.withValues(alpha: 0.45),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.14),
                ),
              ),
              child: Icon(
                equipmentIcon('${equipment.category} ${equipment.name}'),
                color: AppColors.primary,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    equipment.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${equipment.category} • ${equipment.condition.label}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      StatusBadge.availability(equipment.availabilityStatus),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '${equipment.availableQuantity}/${equipment.totalQuantity} units',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.glassFill,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.glassBorderSoft),
              ),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
