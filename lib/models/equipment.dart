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

/// Equipment as served by the backend. When an admin uploads a main profile
/// picture (`imageUrl`) or additional description photos (`galleryUrls`), the
/// mobile UI displays them and falls back to the category icon otherwise.
class Equipment {
  final String id;
  final String name;
  final String category;
  final String description;
  final EquipmentCondition condition;
  final int totalQuantity;
  final int availableQuantity;
  final String? imageUrl;
  final List<String> galleryUrls;

  Equipment({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.condition,
    required this.totalQuantity,
    required this.availableQuantity,
    this.imageUrl,
    this.galleryUrls = const [],
  });

  /// All photos starting with the main profile picture followed by additional
  /// description photos.
  List<String> get allPhotos => [
        if (imageUrl != null && imageUrl!.isNotEmpty) imageUrl!,
        ...galleryUrls.where((u) => u.isNotEmpty),
      ];

  String get availabilityStatus {
    if (availableQuantity <= 0) return 'Unavailable';
    if (availableQuantity <= (totalQuantity * 0.3).ceil()) return 'Limited';
    return 'Available';
  }

  bool get isAvailable => availableQuantity > 0;
}
