import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../models/borrowing_transaction.dart';
import '../../state/app_state.dart';
import '../../widgets/equipment_card.dart';
import '../../widgets/pressable.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/theme_toggle_button.dart';
import '../equipment/equipment_details_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        backgroundColor: AppColors.surface,
        color: AppColors.primary,
        onRefresh: () async {
          try {
            await appState.refreshAll();
          } catch (_) {
            // Keep the indicator from hanging if the backend is unreachable.
            await Future.delayed(const Duration(milliseconds: 400));
          }
        },
        child: ListView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          children: [
            // ── Header: brand mark + theme + notifications ────────────────
            SafeArea(
              bottom: false,
              child: SizedBox(
                height: 44,
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.inventory_2_rounded,
                          color: AppColors.primary, size: 21),
                    ),
                    const Spacer(),
                    const ThemeToggleButton(isHeaderStyle: false),
                    _HeaderIconButton(
                      icon: Icons.notifications_none_rounded,
                      showDot: appState.unreadCount > 0,
                      onTap: () => Navigator.of(context).pushNamed('/notifications'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // ── Title ─────────────────────────────────────────────────────
            Text('Overview', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 16),

            if (appState.currentUser?.isPending == true) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 18),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.verified_user_outlined,
                          color: Color(0xFFD97706), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Account Not Verified',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: Color(0xFFB45309),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'You can browse equipment, but you must submit your front and back ID photos in Profile for admin verification before borrowing.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Stats strip ───────────────────────────────────────────────
            _StatsStrip(
              borrowed: appState.currentlyBorrowed.length,
              pending:
                  appState.transactions.where((t) => t.status == RequestStatus.pending).length,
              approved:
                  appState.transactions.where((t) => t.status == RequestStatus.approved).length,
              overdue: appState.overdueCount,
            ),
            const SizedBox(height: 28),

            // ── Quick actions ─────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _QuickAction(
                    icon: Icons.search_rounded,
                    label: 'Browse',
                    onTap: () => Navigator.of(context).pushNamed('/equipment'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.add_circle_outline_rounded,
                    label: 'Request',
                    onTap: () => Navigator.of(context).pushNamed('/equipment'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.assignment_return_outlined,
                    label: 'Returns',
                    onTap: () => Navigator.of(context).pushNamed('/borrowed-equipment'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.history_rounded,
                    label: 'History',
                    onTap: () => Navigator.of(context).pushNamed('/history'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ── Equipment preview ─────────────────────────────────────────
            const _SectionHeader('Equipment'),
            const SizedBox(height: 12),
            ...appState.equipment.where((e) => e.isAvailable).take(3).map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: EquipmentCard(
                      equipment: e,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => EquipmentDetailsScreen(equipmentId: e.id)),
                      ),
                    ),
                  ),
                ),
            const SizedBox(height: 18),

            // ── Recent activity ───────────────────────────────────────────
            const _SectionHeader('Activity'),
            const SizedBox(height: 12),
            if (appState.transactions.isEmpty)
              Text('Nothing yet.', style: Theme.of(context).textTheme.bodyMedium)
            else
              ...appState.transactions.take(3).map((t) => _ActivityTile(txn: t)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header action button — flat surface tile with an optional unread dot.
// ---------------------------------------------------------------------------
class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final bool showDot;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider.withValues(alpha: 0.6)),
              ),
              child: Icon(icon, color: AppColors.textPrimary, size: 21),
            ),
          ),
        ),
        if (showDot)
          Positioned(
            top: 5,
            right: 6,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: AppColors.gold,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Stats strip — one gradient card, four tap-through figures.
// ---------------------------------------------------------------------------
class _StatsStrip extends StatelessWidget {
  final int borrowed;
  final int pending;
  final int approved;
  final int overdue;

  const _StatsStrip({
    required this.borrowed,
    required this.pending,
    required this.approved,
    required this.overdue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.primaryGlow,
      ),
      child: Row(
        children: [
          _StatColumn(value: borrowed, label: 'Borrowed', onTap: () => Navigator.of(context).pushNamed('/borrowed-equipment')),
          _divider,
          _StatColumn(value: pending, label: 'Pending', onTap: () => Navigator.of(context).pushNamed('/my-requests')),
          _divider,
          _StatColumn(value: approved, label: 'Approved', onTap: () => Navigator.of(context).pushNamed('/my-requests')),
          _divider,
          _StatColumn(value: overdue, label: 'Overdue', onTap: () => Navigator.of(context).pushNamed('/borrowed-equipment')),
        ],
      ),
    );
  }

  Widget get _divider => Container(
        width: 1,
        height: 30,
        color: Colors.white.withValues(alpha: 0.18),
      );
}

class _StatColumn extends StatelessWidget {
  final int value;
  final String label;
  final VoidCallback onTap;

  const _StatColumn({required this.value, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Text(
              '$value',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.78),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick action tile — icon + single-word label.
// ---------------------------------------------------------------------------
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.6)),
          boxShadow: AppShadows.soft,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section header — label + optional trailing action.
// ---------------------------------------------------------------------------
class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(label, style: Theme.of(context).textTheme.titleLarge);
  }
}

// ---------------------------------------------------------------------------
// Activity tile — status dot, item name, trailing status pill.
// ---------------------------------------------------------------------------
class _ActivityTile extends StatelessWidget {
  final BorrowingTransaction txn;
  const _ActivityTile({required this.txn});

  Color get _statusColor => switch (txn.status) {
        RequestStatus.pending => AppColors.warning,
        RequestStatus.approved => AppColors.success,
        RequestStatus.rejected => AppColors.danger,
        RequestStatus.completed => AppColors.primary,
        RequestStatus.cancelled => AppColors.neutral,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: _statusColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${txn.equipmentName}  ·  ${txn.quantity}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(width: 8),
          StatusBadge.forRequest(txn.status),
        ],
      ),
    );
  }
}
