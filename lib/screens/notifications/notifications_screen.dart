import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/motion.dart';
import '../../app/theme.dart';
import '../../models/notification_item.dart';
import '../../state/app_state.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/notification_card.dart';
import '../../widgets/pressable.dart';

/// Notifications — organized by recency (Today / Yesterday / Earlier) with an
/// All / Unread filter. Minimal chrome; the cards carry the detail.
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unread > 0)
            IconButton(
              tooltip: 'Mark all as read',
              onPressed: () => context.read<AppState>().markAllAsRead(),
              icon: const Icon(Icons.done_all_rounded, size: 21),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Filter chips ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  count: all.length,
                  selected: !_unreadOnly,
                  onTap: () => setState(() => _unreadOnly = false),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Unread',
                  count: unread,
                  selected: _unreadOnly,
                  onTap: unread > 0 || !_unreadOnly ? () => setState(() => _unreadOnly = true) : null,
                ),
              ],
            ),
          ),

          // ── Content ────────────────────────────────────────────────────
          Expanded(
            child: visible.isEmpty
                ? RefreshIndicator(
                    color: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    onRefresh: () => context.read<AppState>().refreshNotifications(),
                    child: _emptyState(all.isEmpty),
                  )
                : RefreshIndicator(
                    color: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    onRefresh: () => context.read<AppState>().refreshNotifications(),
                    child: _groupedList(context, appState, visible),
                  ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Grouping: Today / Yesterday / Earlier
  // -------------------------------------------------------------------------
  Widget _groupedList(BuildContext context, AppState appState, List<AppNotification> items) {
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
      children.add(_SectionHeader(label));
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
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: children,
    );
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  // -------------------------------------------------------------------------
  // Empty states
  // -------------------------------------------------------------------------
  Widget _emptyState(bool totallyEmpty) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
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
// Filter chip — label + live count, brand-tinted when active.
// -----------------------------------------------------------------------------
class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback? onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = selected && onTap != null;
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: AppMotion.emphasized,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.divider.withValues(alpha: 0.8),
          ),
          boxShadow: active ? AppShadows.soft : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : AppColors.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: active
                    ? Colors.white.withValues(alpha: 0.22)
                    : AppColors.textTertiary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: active ? Colors.white : AppColors.textTertiary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Section header — whisper-quiet uppercase label with count.
// -----------------------------------------------------------------------------
class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader(this.label);

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
          const SizedBox(width: 8),
          Expanded(child: Divider(color: AppColors.divider.withValues(alpha: 0.7), height: 1)),
        ],
      ),
    );
  }
}
