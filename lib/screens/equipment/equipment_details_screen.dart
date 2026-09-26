import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../models/equipment.dart';
import '../../state/app_state.dart';
import '../../widgets/status_badge.dart';
import '../borrowing/request_equipment_screen.dart';

class EquipmentDetailsScreen extends StatelessWidget {
  final String equipmentId;
  const EquipmentDetailsScreen({super.key, required this.equipmentId});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final equipment = appState.equipmentById(equipmentId);

    if (equipment == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Equipment Details')),
        body: const Center(child: Text('Equipment not found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Equipment Details')),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 136,
                height: 136,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primarySoft,
                      AppColors.primarySoft.withValues(alpha: 0.35),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
                ),
                child: Icon(equipment.icon, size: 64, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(equipment.name, style: Theme.of(context).textTheme.headlineSmall),
                ),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: StatusBadge.availability(equipment.availabilityStatus),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Asset ID: ${equipment.assetId}', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            Text(equipment.description, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 20),
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
                  _InfoRow(label: 'Category', value: equipment.category),
                  const Divider(height: 22),
                  _InfoRow(label: 'Condition', value: equipment.condition.label),
                  const Divider(height: 22),
                  _InfoRow(label: 'Total Quantity', value: '${equipment.totalQuantity}'),
                  const Divider(height: 22),
                  _InfoRow(
                      label: 'Available Quantity', value: '${equipment.availableQuantity}'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primarySoft.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Borrowing requests are subject to approval by the Equipment Office. You will be notified once your request is reviewed.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      equipment.isAvailable ? AppColors.primary : AppColors.surfaceMuted,
                  foregroundColor: equipment.isAvailable ? Colors.white : AppColors.textTertiary,
                ),
                onPressed: equipment.isAvailable
                    ? () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => RequestEquipmentScreen(equipmentId: equipment.id)),
                        )
                    : null,
                icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                label: Text(equipment.isAvailable ? 'Request Equipment' : 'Currently Unavailable'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
