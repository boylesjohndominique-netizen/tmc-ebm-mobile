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

/// Equipment as served by the backend. The icon is derived from the
/// category name at render time — no hardcoded IconData per item.
class Equipment {
  final String id;
  final String name;
  final String category;
  final String description;
  final EquipmentCondition condition;
  final int totalQuantity;
  final int availableQuantity;

  Equipment({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.condition,
    required this.totalQuantity,
    required this.availableQuantity,
  });

  String get availabilityStatus {
    if (availableQuantity <= 0) return 'Unavailable';
    if (availableQuantity <= (totalQuantity * 0.3).ceil()) return 'Limited';
    return 'Available';
  }

  bool get isAvailable => availableQuantity > 0;
}
