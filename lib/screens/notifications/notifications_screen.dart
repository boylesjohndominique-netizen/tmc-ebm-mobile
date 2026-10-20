import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../models/notification_item.dart';
import '../../state/app_state.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/liquid_glass.dart';
import '../../widgets/notification_card.dart';

/// Notifications — organized by recency (Today / Yesterday / Earlier) with an
/// All / Unread filter. Minimal chrome; the glass cards carry the detail.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _unreadOnly = false;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final all = appState.notifications;
    final unread = all.where((n) => !n.isRead).length;
    final visible = _unreadOnly ? all.where((n) => !n.isRead).toList() : all;

    return LiquidScaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Notifications',
                            style: Theme.of(context).textTheme.headlineLarge),
                        const SizedBox(height: 3),
                        Text(
                          unread > 0
                              ? '$unread unread'
                              : 'You are all caught up',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (unread > 0)
                    GlassIconButton(
                      icon: Icons.done_all_rounded,
                      tooltip: 'Mark all as read',
                      onTap: () => context.read<AppState>().markAllAsRead(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Filter chips ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  GlassChip(
                    label: 'All',
                    count: '${all.length}',
                    selected: !_unreadOnly,
                    onTap: () => setState(() => _unreadOnly = false),
                  ),
                  const SizedBox(width: 8),
                  GlassChip(
                    label: 'Unread',
                    count: '$unread',
                    selected: _unreadOnly,
                    onTap: unread > 0 || !_unreadOnly
                        ? () => setState(() => _unreadOnly = true)
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Content ────────────────────────────────────────────────────
            Expanded(
              child: visible.isEmpty
                  ? RefreshIndicator(
                      color: AppColors.primary,
                      backgroundColor: AppColors.surface,
                      onRefresh: () =>
                          context.read<AppState>().refreshNotifications(),
                      child: _emptyState(all.isEmpty),
                    )
                  : RefreshIndicator(
                      color: AppColors.primary,
                      backgroundColor: AppColors.surface,
                      onRefresh: () =>
                          context.read<AppState>().refreshNotifications(),
                      child: _groupedList(context, visible),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Grouping: Today / Yesterday / Earlier
  // -------------------------------------------------------------------------
  Widget _groupedList(BuildContext context, List<AppNotification> items) {
    final now = DateTime.now();
    final today = <AppNotification>[];
    final yesterday = <AppNotification>[];
    final earlier = <AppNotification>[];

    for (final n in items) {
      final d = n.date;
      if (_sameDay(d, now)) {
        today.add(n);
      } else if (_sameDay(d, now.subtract(const Duration(days: 1)))) {
        yesterday.add(n);
      } else {
        earlier.add(n);
      }
    }

    final sections = <String, List<AppNotification>>{
      'Today': today,
      'Yesterday': yesterday,
      'Earlier': earlier,
    };

    final children = <Widget>[];
    sections.forEach((label, list) {
      if (list.isEmpty) return;
      children.add(_SectionHeader(label, list.length));
      for (final n in list) {
        children.add(Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: NotificationCard(
            notification: n,
            onTap: () => context.read<AppState>().markAsRead(n.id),
          ),
        ));
      }
    });

    return ListView(
      physics:
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: children,
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // -------------------------------------------------------------------------
  // Empty states
  // -------------------------------------------------------------------------
  Widget _emptyState(bool totallyEmpty) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.55,
          child: totallyEmpty
              ? const EmptyState(
                  icon: Icons.notifications_none_rounded,
                  title: 'All caught up',
                  subtitle: 'New notifications will appear here.',
                )
              : const EmptyState(
                  icon: Icons.done_all_rounded,
                  title: 'Nothing unread',
                ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Section header — quiet uppercase label with a hairline rule.
// -----------------------------------------------------------------------------
class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;

  const _SectionHeader(this.label, this.count);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 10, bottom: 10),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(width: 7),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.textTertiary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
              child: Divider(
                  color: AppColors.divider.withValues(alpha: 0.7), height: 1)),
        ],
      ),
    );
  }
}
