import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/notification_card.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final notifications = appState.notifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (appState.unreadCount > 0)
            TextButton(
              onPressed: () => context.read<AppState>().markAllAsRead(),
              child: const Text('Mark all as read'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: notifications.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_none_rounded,
              title: "You're all caught up!",
              subtitle: 'New notifications will appear here.',
            )
          : ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final n = notifications[i];
                return NotificationCard(
                  notification: n,
                  onTap: () => context.read<AppState>().markAsRead(n.id),
                );
              },
            ),
    );
  }
}
