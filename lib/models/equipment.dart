import 'package:flutter/material.dart';

enum EquipmentCondition { excellent, good, fair }

extension EquipmentConditionLabel on EquipmentCondition {
  String get label {
    switch (this) {
      case EquipmentCondition.excellent:
        return 'Excellent';
      case EquipmentCondition.good:
        return 'Good';
      case EquipmentCondition.fair:
        return 'Fair';
    }
  }
}

class Equipment {
  final String id;
  final String assetId;
  final String name;
  final String category;
  final String description;
  final EquipmentCondition condition;
  final int totalQuantity;
  int availableQuantity;
  final IconData icon;

  Equipment({
    required this.id,
    required this.assetId,
    required this.name,
    required this.category,
    required this.description,
    required this.condition,
    required this.totalQuantity,
    required this.availableQuantity,
    required this.icon,
  });

  String get availabilityStatus {
    if (availableQuantity <= 0) return 'Unavailable';
    if (availableQuantity <= (totalQuantity * 0.3).ceil()) return 'Limited';
    return 'Available';
  }

  bool get isAvailable => availableQuantity > 0;
}
