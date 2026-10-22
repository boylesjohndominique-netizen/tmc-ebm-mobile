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
  final String pickupLocation;
  final int? minBorrowingDays;
  final int? maxBorrowingDays;

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
    this.pickupLocation = '',
    this.minBorrowingDays,
    this.maxBorrowingDays,
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

  static DateTime get schoolToday {
    final now = DateTime.now().toUtc().add(const Duration(hours: 8));
    return DateTime(now.year, now.month, now.day);
  }

  DateTime firstReturnDate(DateTime borrowingDate) => DateTime(
    borrowingDate.year,
    borrowingDate.month,
    borrowingDate.day + (minBorrowingDays ?? 1),
  );

  DateTime lastReturnDate(DateTime borrowingDate) => DateTime(
    borrowingDate.year,
    borrowingDate.month,
    borrowingDate.day + (maxBorrowingDays ?? 90),
  );

  static int borrowingDays(DateTime borrowingDate, DateTime returnDate) =>
      DateTime.utc(returnDate.year, returnDate.month, returnDate.day)
          .difference(
            DateTime.utc(
              borrowingDate.year,
              borrowingDate.month,
              borrowingDate.day,
            ),
          )
          .inDays;

  bool allowsBorrowingPeriod(DateTime borrowingDate, DateTime returnDate) {
    final days = borrowingDays(borrowingDate, returnDate);
    return days >= 1 &&
        (minBorrowingDays == null || days >= minBorrowingDays!) &&
        (maxBorrowingDays == null || days <= maxBorrowingDays!);
  }
}
