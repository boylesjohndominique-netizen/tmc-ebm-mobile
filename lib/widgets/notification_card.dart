import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../app/motion.dart';
import '../app/theme.dart';
import '../models/notification_item.dart';
import 'liquid_glass.dart';
import 'pressable.dart';

/// Notification card — tinted icon box, title with unread dot, message preview
/// and a meta row (category pill + relative time).
///
/// Tapping expands the card to reveal the full message and the absolute
/// timestamp; the parent's [onTap] marks it read.
class NotificationCard extends StatefulWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const NotificationCard(
      {super.key, required this.notification, required this.onTap});

  @override
  State<NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<NotificationCard> {
  bool _expanded = false;

  AppNotification get n => widget.notification;
  bool get _unread => !n.isRead;

  IconData get _icon => switch (n.type) {
        NotificationType.approval => Icons.task_alt_rounded,
        NotificationType.rejection => Icons.cancel_rounded,
        NotificationType.reminder => Icons.schedule_rounded,
        NotificationType.overdue => Icons.notification_important_rounded,
        NotificationType.system => Icons.campaign_rounded,
      };

  Color get _color => switch (n.type) {
        NotificationType.approval => AppColors.success,
        NotificationType.rejection => AppColors.danger,
        NotificationType.reminder => AppColors.primary,
        NotificationType.overdue => AppColors.warning,
        NotificationType.system => AppColors.textSecondary,
      };

  String get _category => switch (n.type) {
        NotificationType.approval => 'Approved',
        NotificationType.rejection => 'Rejected',
        NotificationType.reminder => 'Reminder',
        NotificationType.overdue => 'Overdue',
        NotificationType.system => 'System',
      };

  String get _timeAgo {
    final diff = DateTime.now().difference(n.date);
    if (diff.inMinutes < 1) return 'Now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return DateFormat('MMM d').format(n.date);
  }

  String get _fullDate {
    final now = DateTime.now();
    final sameYear = n.date.year == now.year;
    return sameYear
        ? DateFormat('MMM d · h:mm a').format(n.date)
        : DateFormat('MMM d, yyyy · h:mm a').format(n.date);
  }

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () {
        setState(() => _expanded = !_expanded);
        widget.onTap();
      },
      child: GlassPanel(
        blur: 0,
        radius: AppRadius.lg,
        padding: EdgeInsets.zero,
        shadows: AppShadows.card,
        tint: _unread ? AppColors.primarySoft : null,
        child: AnimatedContainer(
          duration: AppMotion.responsive(context, AppMotion.normal),
          curve: AppMotion.emphasized,
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Icon ─────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(_icon, color: _color, size: 22),
              ),
              const SizedBox(width: 12),

              // ── Content ──────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + unread dot
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            n.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  _unread ? FontWeight.w700 : FontWeight.w600,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.1,
                            ),
                          ),
                        ),
                        if (_unread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Message — collapses to 2 lines, expands in full
                    AnimatedSize(
                      duration: AppMotion.fast,
                      curve: AppMotion.emphasized,
                      alignment: Alignment.topCenter,
                      child: Text(
                        n.message,
                        maxLines: _expanded ? null : 2,
                        overflow: _expanded ? null : TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Meta row — category pill + timestamp
                    Row(
                      children: [
                        _CategoryPill(label: _category, color: _color),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _expanded ? _fullDate : _timeAgo,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textTertiary,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Single-word category pill — quiet, tinted, uppercase.
class _CategoryPill extends StatelessWidget {
  final String label;
  final Color color;
  const _CategoryPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
