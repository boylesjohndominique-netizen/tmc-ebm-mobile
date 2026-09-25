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
      appBar: AppBar(title: Text(equipment.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(color: AppColors.lightBlue, borderRadius: BorderRadius.circular(28)),
                child: Icon(equipment.icon, size: 68, color: AppColors.primaryBlue),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(equipment.name, style: Theme.of(context).textTheme.headlineSmall),
                ),
                StatusBadge.availability(equipment.availabilityStatus),
              ],
            ),
            const SizedBox(height: 4),
            Text('Asset ID: ${equipment.assetId}', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            Text('Description', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(equipment.description, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  _InfoRow(label: 'Category', value: equipment.category),
                  const Divider(height: 22),
                  _InfoRow(label: 'Condition', value: equipment.condition.label),
                  const Divider(height: 22),
                  _InfoRow(label: 'Total Quantity', value: '${equipment.totalQuantity}'),
                  const Divider(height: 22),
                  _InfoRow(label: 'Available Quantity', value: '${equipment.availableQuantity}'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.lightBlue,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.primaryBlue, size: 20),
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
                onPressed: equipment.isAvailable
                    ? () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => RequestEquipmentScreen(equipmentId: equipment.id)),
                        )
                    : null,
                icon: const Icon(Icons.add_circle_outline_rounded),
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }
}
