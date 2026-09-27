import 'package:flutter_test/flutter_test.dart';
import 'package:tmcebms/data/api_mappers.dart';
import 'package:tmcebms/models/borrowing_transaction.dart';
import 'package:tmcebms/models/equipment.dart';
import 'package:tmcebms/models/notification_item.dart';
import 'package:tmcebms/models/user.dart';

/// Fakes mirroring the real Laravel API responses (see MobileController),
/// so the mapper layer can be tested without a running backend.
Map<String, dynamic> fakeUserJson({String status = 'Active'}) => {
      'id': 8,
      'role_id': 1,
      'first_name': 'Juan',
      'middle_name': null,
      'last_name': 'Dela Cruz',
      'username': 'juan.delacruz',
      'email': 'juan@tmc.edu',
      'contact_number': '09171234567',
      'email_verified_at': '2026-09-27T05:39:20.000000Z',
      'account_status': status,
    };

Map<String, dynamic> fakeEquipmentJson({int available = 15}) => {
      'id': 1,
      'name': 'Laptop',
      'description': 'College laptop for academic activities.',
      'quantity': 20,
      'available_quantity': available,
      'condition': 'Good',
      'status': 'Available',
      'category': {'id': 1, 'name': 'Information Technology'},
    };

Map<String, dynamic> fakeBorrowingJson({String status = 'Pending', List<Map<String, dynamic>>? returns}) => {
      'id': 13,
      'borrowing_date': '2026-09-27T00:00:00.000000Z',
      'expected_return_date': '2026-09-30T00:00:00.000000Z',
      'status': status,
      'remarks': 'Capstone defense equipment',
      'processed_by': null,
      'created_at': '2026-09-27T05:40:46.000000Z',
      'updated_at': '2026-09-27T05:40:46.000000Z',
      'items': [
        {
          'id': 21,
          'equipment_id': 1,
          'quantity': 2,
          'equipment': {
            ...fakeEquipmentJson(),
            'category': {'id': 1, 'name': 'Information Technology'},
          },
        },
      ],
      if (returns != null) 'returns': returns,
    };

void main() {
  group('mapUser', () {
    test('builds the full name from parts and maps status', () {
      final user = mapUser(fakeUserJson());
      expect(user.id, '8');
      expect(user.fullName, 'Juan Dela Cruz');
      expect(user.username, 'juan.delacruz');
      expect(user.email, 'juan@tmc.edu');
      expect(user.userType, UserType.student);
      expect(user.emailVerified, isTrue);
      expect(user.accountStatus, 'Active');
      expect(user.isActive, isTrue);
    });

    test('handles pending and banned statuses', () {
      expect(mapUser(fakeUserJson(status: 'Pending')).isPending, isTrue);
      expect(mapUser(fakeUserJson(status: 'Banned')).isBanned, isTrue);
    });

    test('degrades gracefully on malformed input', () {
      final user = mapUser({});
      expect(user.fullName, 'Student');
      expect(user.email, '');
    });
  });

  group('mapEquipment', () {
    test('maps category name and quantities', () {
      final eq = mapEquipment(fakeEquipmentJson());
      expect(eq.id, '1');
      expect(eq.name, 'Laptop');
      expect(eq.category, 'Information Technology');
      expect(eq.totalQuantity, 20);
      expect(eq.availableQuantity, 15);
      expect(eq.condition, EquipmentCondition.good);
      expect(eq.availabilityStatus, 'Available');
    });

    test('availability reflects stock', () {
      expect(mapEquipment(fakeEquipmentJson(available: 0)).availabilityStatus, 'Unavailable');
      expect(mapEquipment(fakeEquipmentJson(available: 2)).availabilityStatus, 'Limited');
    });
  });

  group('mapBorrowing', () {
    test('maps a pending request with items', () {
      final txn = mapBorrowing(fakeBorrowingJson());
      expect(txn.transactionId, '13');
      expect(txn.equipmentName, 'Laptop');
      expect(txn.quantity, 2);
      expect(txn.status, RequestStatus.pending);
      expect(txn.purpose, 'Capstone defense equipment');
      expect(txn.returnStatus, ReturnStatus.notReturned);
    });

    test('return status follows the attached return request', () {
      final pending = mapBorrowing(fakeBorrowingJson(
        status: 'Approved',
        returns: [
          {'id': 4, 'status': 'Pending', 'returned_at': null},
        ],
      ));
      expect(pending.returnStatus, ReturnStatus.returnPending);
      expect(pending.isCurrentlyBorrowed, isTrue);

      final confirmed = mapBorrowing(fakeBorrowingJson(
        status: 'Completed',
        returns: [
          {
            'id': 4,
            'status': 'Confirmed',
            'returned_at': '2026-09-28T10:00:00.000000Z',
          },
        ],
      ));
      expect(confirmed.returnStatus, ReturnStatus.returnConfirmed);
      expect(confirmed.actualReturnDate, isNotNull);
    });

    test('status mapping covers the admin lifecycle', () {
      expect(mapBorrowing(fakeBorrowingJson(status: 'Approved')).status, RequestStatus.approved);
      expect(mapBorrowing(fakeBorrowingJson(status: 'Rejected')).status, RequestStatus.rejected);
      expect(mapBorrowing(fakeBorrowingJson(status: 'Completed')).status, RequestStatus.completed);
      expect(mapBorrowing(fakeBorrowingJson(status: 'Cancelled')).status, RequestStatus.cancelled);
    });
  });

  group('mapNotification', () {
    test('maps success type to approval', () {
      final n = mapNotification({
        'id': 11,
        'title': 'Borrowing Request Approved',
        'message': 'Good news!',
        'type': 'Success',
        'read_at': null,
        'created_at': '2026-09-27T05:42:00.000000Z',
      });
      expect(n.type, NotificationType.approval);
      expect(n.isRead, isFalse);
    });

    test('read_at marks it read', () {
      final n = mapNotification({
        'id': 12,
        'title': 'Return Confirmed',
        'message': 'Thanks!',
        'type': 'Success',
        'read_at': '2026-09-27T06:00:00.000000Z',
        'created_at': '2026-09-27T05:42:00.000000Z',
      });
      expect(n.isRead, isTrue);
    });
  });
}
