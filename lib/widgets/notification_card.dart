import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../app/theme.dart';
import '../models/notification_item.dart';

class NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const NotificationCard({super.key, required this.notification, required this.onTap});

  IconData get _icon {
    switch (notification.type) {
      case NotificationType.approval:
        return Icons.check_circle_rounded;
      case NotificationType.rejection:
        return Icons.cancel_rounded;
      case NotificationType.reminder:
        return Icons.schedule_rounded;
      case NotificationType.overdue:
        return Icons.warning_rounded;
      case NotificationType.system:
        return Icons.campaign_rounded;
    }
  }

  Color get _color {
    switch (notification.type) {
      case NotificationType.approval:
        return AppColors.success;
      case NotificationType.rejection:
        return AppColors.danger;
      case NotificationType.reminder:
        return AppColors.gold;
      case NotificationType.overdue:
        return AppColors.danger;
      case NotificationType.system:
        return AppColors.info;
    }
  }

  String get _timeAgo {
    final diff = DateTime.now().difference(notification.date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(notification.date);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notification.isRead ? AppColors.surface : AppColors.lightBlue.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(color: _color.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(_icon, color: _color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(notification.title,
                            style: Theme.of(context).textTheme.titleMedium),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                              color: AppColors.gold, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(notification.message, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 6),
                  Text(_timeAgo,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
