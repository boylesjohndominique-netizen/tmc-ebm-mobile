import 'package:flutter/material.dart';
import '../models/equipment.dart';
import 'liquid_glass.dart';

class EquipmentBorrowingInfo extends StatelessWidget {
  final Equipment equipment;
  const EquipmentBorrowingInfo({super.key, required this.equipment});

  @override
  Widget build(BuildContext context) {
    final min = equipment.minBorrowingDays;
    final max = equipment.maxBorrowingDays;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'School pickup location',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            equipment.pickupLocation.isEmpty
                ? 'Ask the administrator for the pickup location.'
                : equipment.pickupLocation,
          ),
          const SizedBox(height: 12),
          Text(
            'Allowed loan duration',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            min != null && max != null
                ? '$min–$max days after your borrowing date'
                : 'No duration restriction',
          ),
        ],
      ),
    );
  }
}
