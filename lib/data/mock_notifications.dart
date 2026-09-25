import '../models/notification_item.dart';

List<AppNotification> buildMockNotifications() {
  final now = DateTime.now();
  return [
    AppNotification(
      id: 'n-001',
      title: 'Borrowing Request Approved',
      message: 'Your request for Laptop (TMC-LAP-001) has been approved.',
      type: NotificationType.approval,
      date: now.subtract(const Duration(days: 2, hours: 1)),
      isRead: false,
    ),
    AppNotification(
      id: 'n-002',
      title: 'Return Reminder',
      message: 'Your laptop is due for return in 1 day.',
      type: NotificationType.reminder,
      date: now.subtract(const Duration(hours: 6)),
      isRead: false,
    ),
    AppNotification(
      id: 'n-003',
      title: 'Equipment Overdue',
      message: 'Your borrowed Projector (TMC-PRJ-002) is overdue. Please return it as soon as possible.',
      type: NotificationType.overdue,
      date: now.subtract(const Duration(hours: 20)),
      isRead: false,
    ),
    AppNotification(
      id: 'n-004',
      title: 'Scheduled Maintenance',
      message: 'The Equipment Office will be closed on Friday for inventory maintenance.',
      type: NotificationType.system,
      date: now.subtract(const Duration(days: 1, hours: 4)),
      isRead: true,
    ),
    AppNotification(
      id: 'n-005',
      title: 'Borrowing Request Rejected',
      message: 'Your request for Computer Set (TMC-PCS-009) was rejected due to unit unavailability.',
      type: NotificationType.rejection,
      date: now.subtract(const Duration(days: 5)),
      isRead: true,
    ),
    AppNotification(
      id: 'n-006',
      title: 'College Announcement',
      message: 'New batch of tablets and cameras now available for borrowing this semester.',
      type: NotificationType.system,
      date: now.subtract(const Duration(days: 7)),
      isRead: true,
    ),
  ];
}
