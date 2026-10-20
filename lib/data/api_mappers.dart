import '../models/borrowing_transaction.dart';
import '../models/equipment.dart';
import '../models/notification_item.dart';
import '../models/user.dart';

/// Converts raw backend JSON into the app's UI-facing models.
///
/// All mappers are defensive: any malformed field degrades to a sensible
/// default rather than throwing, so one bad row can never crash a screen.

// ---------------------------------------------------------------------------
// USER
// ---------------------------------------------------------------------------

AppUser mapUser(Map<String, dynamic> j) {
  final first = (j['first_name'] as String?) ?? '';
  final middle = (j['middle_name'] as String?) ?? '';
  final last = (j['last_name'] as String?) ?? '';
  final full = [first, if (middle.isNotEmpty) middle, last]
      .where((p) => p.isNotEmpty)
      .join(' ');

  return AppUser(
    id: (j['id'] ?? '').toString(),
    fullName: full.isNotEmpty ? full : 'Student',
    idNumber: (j['id_number'] as String?) ?? '',
    email: (j['email'] as String?) ?? '',
    username: (j['username'] as String?) ?? '',
    contactNumber: (j['contact_number'] as String?) ?? '',
    userType: UserType.student,
    emailVerified: j['email_verified_at'] != null,
    accountStatus: (j['account_status'] as String?) ?? 'Active',
    // Falls back to Active-status for older payloads that predate the flag.
    isIdVerified: (j['is_id_verified'] as bool?) ??
        ((j['account_status'] as String?) == 'Active'),
    hasSubmittedId: j['id_submitted_at'] != null,
  );
}

// ---------------------------------------------------------------------------
// EQUIPMENT
// ---------------------------------------------------------------------------

Equipment mapEquipment(Map<String, dynamic> j) => Equipment(
      id: (j['id'] ?? '').toString(),
      name: (j['name'] as String?) ?? 'Unknown',
      category:
          ((j['category'] as Map<String, dynamic>?)?['name'] as String?) ??
              'General',
      description: (j['description'] as String?) ?? '',
      condition: switch ((j['condition'] as String?)?.toLowerCase()) {
        'excellent' => EquipmentCondition.excellent,
        'fair' => EquipmentCondition.fair,
        _ => EquipmentCondition.good,
      },
      totalQuantity: (j['quantity'] as num?)?.toInt() ?? 0,
      availableQuantity: (j['available_quantity'] as num?)?.toInt() ?? 0,
    );

// ---------------------------------------------------------------------------
// BORROWING TRANSACTIONS
// ---------------------------------------------------------------------------

BorrowingTransaction mapBorrowing(Map<String, dynamic> j) {
  final items = (j['items'] as List?) ?? const [];
  final firstItem = items.isNotEmpty && items.first is Map<String, dynamic>
      ? items.first as Map<String, dynamic>
      : <String, dynamic>{};
  final equipment = firstItem['equipment'] as Map<String, dynamic>?;

  // A borrowing request may contain several items; the UI shows them joined.
  final name = items
      .map((i) => ((i as Map<String, dynamic>)['equipment']
          as Map<String, dynamic>?)?['name'])
      .whereType<String>()
      .join(', ');
  final quantity = items.fold<int>(
    0,
    (sum, i) =>
        sum + (((i as Map<String, dynamic>)['quantity'] as num?)?.toInt() ?? 0),
  );

  final returns = (j['returns'] as List?) ?? const [];
  final latestReturn =
      returns.isNotEmpty && returns.first is Map<String, dynamic>
          ? returns.first as Map<String, dynamic>
          : null;
  final returnStatus = _mapReturnStatus(
      (latestReturn?['status'] as String?), j['status'] as String?);

  return BorrowingTransaction(
    transactionId: (j['id'] ?? '').toString(),
    equipmentId:
        ((firstItem['equipment_id'] ?? equipment?['id'] ?? '')).toString(),
    equipmentName: name.isNotEmpty ? name : 'Equipment',
    assetId: equipment?['asset_id']?.toString() ?? '',
    category: ((equipment?['category'] as Map<String, dynamic>?)?['name']
            as String?) ??
        '',
    quantity: quantity > 0
        ? quantity
        : (((firstItem['quantity'] as num?)?.toInt()) ?? 1),
    borrowingDate: _parseDate(j['borrowing_date']),
    returnDate: _parseDate(j['expected_return_date']),
    actualReturnDate: latestReturn?['returned_at'] != null
        ? _parseDate(latestReturn?['returned_at'])
        : null,
    overdueDays: (latestReturn?['overdue_days'] as num?)?.toInt(),
    overdueFee: _parseNum(latestReturn?['overdue_fee']),
    purpose: (j['remarks'] as String?) ?? '',
    notes: '',
    requestDate: _parseDate(j['created_at']),
    approvalDate: j['status'] != 'Pending' ? _parseDate(j['updated_at']) : null,
    status: _mapRequestStatus(j['status'] as String?),
    returnStatus: returnStatus,
  );
}

RequestStatus _mapRequestStatus(String? s) => switch (s) {
      'Pending' => RequestStatus.pending,
      'Approved' => RequestStatus.approved,
      'Rejected' => RequestStatus.rejected,
      'Completed' => RequestStatus.completed,
      'Cancelled' => RequestStatus.cancelled,
      _ => RequestStatus.pending,
    };

ReturnStatus _mapReturnStatus(String? s, String? borrowingStatus) {
  switch (s) {
    case 'Pending':
      return ReturnStatus.returnPending;
    case 'Confirmed':
      return ReturnStatus.returnConfirmed;
    case 'Rejected':
      return ReturnStatus.notReturned;
    default:
      return borrowingStatus == 'Completed'
          ? ReturnStatus.completed
          : ReturnStatus.notReturned;
  }
}

DateTime _parseDate(dynamic v) {
  if (v is String) {
    return DateTime.tryParse(v) ?? DateTime.now();
  }
  return DateTime.now();
}

double? _parseNum(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

// ---------------------------------------------------------------------------
// NOTIFICATIONS
// ---------------------------------------------------------------------------

AppNotification mapNotification(Map<String, dynamic> j) => AppNotification(
      id: (j['id'] ?? '').toString(),
      title: (j['title'] as String?) ?? 'Notification',
      message: (j['message'] as String?) ?? '',
      type: switch ((j['type'] as String?)?.toLowerCase()) {
        'success' => NotificationType.approval,
        'request' => NotificationType.reminder,
        'return' => NotificationType.reminder,
        'error' => NotificationType.rejection,
        'warning' => NotificationType.overdue,
        _ => NotificationType.system,
      },
      date: _parseDate(j['created_at']),
      isRead: j['read_at'] != null,
    );
