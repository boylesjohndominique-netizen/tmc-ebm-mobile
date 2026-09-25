import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../models/equipment.dart';
import 'status_badge.dart';

class EquipmentCard extends StatelessWidget {
  final Equipment equipment;
  final VoidCallback onTap;

  const EquipmentCard({super.key, required this.equipment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.lightBlue,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(equipment.icon, color: AppColors.primaryBlue, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(equipment.name, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 3),
                  Text(
                    '${equipment.category} • ${equipment.condition.label}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      StatusBadge.availability(equipment.availabilityStatus),
                      const SizedBox(width: 8),
                      Text(
                        '${equipment.availableQuantity}/${equipment.totalQuantity} units',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.neutral),
          ],
        ),
      ),
    );
  }
}
