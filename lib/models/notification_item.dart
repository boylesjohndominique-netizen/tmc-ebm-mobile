enum NotificationType { approval, rejection, reminder, overdue, system }

class AppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime date;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.date,
    this.isRead = false,
  });
}
